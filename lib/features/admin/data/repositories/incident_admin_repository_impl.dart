import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/pending_incident.dart';
import '../../domain/entities/rejection_rules.dart';
import '../../domain/repositories/incident_admin_repository.dart';
import '../datasources/incident_admin_remote_data_source.dart';

class IncidentAdminRepositoryImpl implements IncidentAdminRepository {
  IncidentAdminRepositoryImpl({IncidentAdminRemoteDataSource? remote})
    : _remote = remote ?? IncidentAdminRemoteDataSource();

  final IncidentAdminRemoteDataSource _remote;

  // Los nombres casi no cambian: se guardan para no volver a leerlos cada
  // vez que llega una actualización de la lista.
  final _userNames = <String, Future<String>>{};
  final _housingLabels = <String, Future<String>>{};

  static const _unknown = 'Sin registrar';

  @override
  Stream<List<PendingIncident>> watchPending() {
    return _remote
        .watchPending()
        .asyncMap((incidents) async {
          final sorted = [...incidents]..sort(compareOldestFirst);
          return Future.wait([
            for (final incident in sorted)
              _withNames(incident),
          ]);
        })
        .handleError((Object e) {
          throw switch (e) {
            FirebaseException(code: 'unavailable') => IncidentFailure.offline,
            FirebaseException(code: 'permission-denied') =>
              IncidentFailure.pendingAccessDenied,
            _ => IncidentFailure.pendingLoadFailed,
          };
        });
  }

  /// Más antiguas primero. Las que aún no tienen fecha del servidor (recién
  /// creadas) van al final; a igual fecha, por folio.
  static int compareOldestFirst(Incident a, Incident b) {
    final da = a.createdAt;
    final db = b.createdAt;
    if (da == null && db == null) return a.folio.compareTo(b.folio);
    if (da == null) return 1;
    if (db == null) return -1;
    final byDate = da.compareTo(db);
    return byDate != 0 ? byDate : a.folio.compareTo(b.folio);
  }

  Future<PendingIncident> _withNames(Incident incident) async {
    final results = await Future.wait([
      _housingLabels.putIfAbsent(
        incident.housingId,
        () => _safe(() => _remote.housingLabel(incident.housingId)),
      ),
      _userNames.putIfAbsent(
        incident.createdBy,
        () => _safe(() => _remote.userName(incident.createdBy)),
      ),
    ]);
    return PendingIncident(
      incident: incident,
      housingLabel: results[0],
      reporterName: results[1],
    );
  }

  static Future<String> _safe(Future<String?> Function() read) async {
    try {
      final value = (await read())?.trim();
      return value == null || value.isEmpty ? _unknown : value;
    } catch (_) {
      return _unknown;
    }
  }

  @override
  Future<List<AppUser>> availableTechnicians() async {
    try {
      return await _remote.availableTechnicians();
    } on FirebaseException catch (e) {
      throw _failureFor(e);
    }
  }

  @override
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  }) async {
    try {
      await _remote.assign(
        incidentId: incidentId,
        technicianId: technicianId,
        estimatedTime: estimatedTime,
      );
    } on IncidentNotPendingException {
      throw IncidentFailure.notPending;
    } on TechnicianUnavailableException {
      throw IncidentFailure.technicianUnavailable;
    } on FirebaseException catch (e) {
      throw _failureFor(e);
    }
  }

  @override
  Future<void> reject({
    required String incidentId,
    required String comment,
  }) async {
    // El motivo es obligatorio aunque la llamada no venga del formulario.
    final invalid = RejectionRules.validate(comment);
    if (invalid != null) throw IncidentFailure(invalid);
    try {
      await _remote.reject(incidentId: incidentId, comment: comment.trim());
    } on IncidentNotPendingException {
      throw IncidentFailure.notPending;
    } on FirebaseException catch (e) {
      throw _failureFor(e);
    }
  }

  static IncidentFailure _failureFor(FirebaseException e) => switch (e.code) {
    'unavailable' || 'deadline-exceeded' => IncidentFailure.offline,
    'permission-denied' => IncidentFailure.pendingAccessDenied,
    _ => IncidentFailure.actionFailed,
  };
}
