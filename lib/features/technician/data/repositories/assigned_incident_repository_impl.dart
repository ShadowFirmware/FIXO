import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../datasources/assigned_incident_remote_data_source.dart';

class AssignedIncidentRepositoryImpl implements AssignedIncidentRepository {
  AssignedIncidentRepositoryImpl({AssignedIncidentRemoteDataSource? remote})
    : _remote = remote ?? AssignedIncidentRemoteDataSource();

  final AssignedIncidentRemoteDataSource _remote;

  // Se consultan una sola vez aunque la lista se emita muchas veces.
  final _housingLabels = <String, Future<String>>{};
  final _contacts = <String, Future<({String name, String? phone})>>{};

  static const _unknown = 'Sin registrar';

  @override
  Stream<List<AssignedIncident>> watchByTechnician(String technicianId) {
    return _remote
        .watchByTechnician(technicianId)
        .asyncMap(
          (incidents) => Future.wait([
            for (final incident in incidents) _withContact(incident),
          ]),
        )
        .handleError((Object e) {
          throw switch (e) {
            FirebaseException(code: 'unavailable') => IncidentFailure.offline,
            FirebaseException(code: 'permission-denied') =>
              IncidentFailure.assignedAccessDenied,
            _ => IncidentFailure.assignedLoadFailed,
          };
        });
  }

  @override
  Stream<AssignedIncident?> watchById(String id) {
    return _remote
        .watchById(id)
        .asyncMap(
          (incident) => incident == null
              ? Future<AssignedIncident?>.value()
              : _withContact(incident),
        )
        .handleError((Object e) {
          throw switch (e) {
            FirebaseException(code: 'unavailable') => IncidentFailure.offline,
            FirebaseException(code: 'permission-denied') =>
              IncidentFailure.accessDenied,
            _ => IncidentFailure.loadFailed,
          };
        });
  }

  Future<AssignedIncident> _withContact(Incident incident) async {
    final (housing, resident) = await (
      _housingLabels.putIfAbsent(
        incident.housingId,
        () => _housingLabel(incident.housingId),
      ),
      _contacts.putIfAbsent(
        incident.createdBy,
        () => _contact(incident.createdBy),
      ),
    ).wait;
    return AssignedIncident(
      incident: incident,
      housingLabel: housing,
      residentName: resident.name,
      residentPhone: resident.phone,
    );
  }

  Future<String> _housingLabel(String id) async {
    try {
      return _textOr(await _remote.housingLabel(id)) ?? _unknown;
    } catch (_) {
      return _unknown;
    }
  }

  Future<({String name, String? phone})> _contact(String uid) async {
    try {
      final contact = await _remote.contact(uid);
      return (
        name: _textOr(contact?.name) ?? _unknown,
        phone: _textOr(contact?.phone),
      );
    } catch (_) {
      return (name: _unknown, phone: null);
    }
  }

  static String? _textOr(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
