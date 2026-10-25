import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../notifications/data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/new_incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/evidence_storage_data_source.dart';
import '../datasources/incident_remote_data_source.dart';
import '../models/incident_model.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  IncidentRepositoryImpl({
    IncidentRemoteDataSource? remote,
    EvidenceStorageDataSource? storage,
    NotificationRemoteDataSource? notifications,
  }) : _remote = remote ?? IncidentRemoteDataSource(),
       _storage = storage ?? EvidenceStorageDataSource(),
       _notifications = notifications ?? NotificationRemoteDataSource();

  final IncidentRemoteDataSource _remote;
  final EvidenceStorageDataSource _storage;
  final NotificationRemoteDataSource _notifications;

  @override
  Future<Incident> register({
    required NewIncident data,
    required String residentId,
    required String housingId,
  }) async {
    final id = _remote.newId();

    // Primero se suben las evidencias: si fallan, no queda una incidencia
    // registrada sin ellas.
    final List<String> urls;
    try {
      urls = await _storage.uploadBefore(id, data.evidence);
    } on EvidenceUploadException catch (e) {
      throw e.network
          ? IncidentFailure.network
          : IncidentFailure.evidenceUpload;
    }

    try {
      final adminIds = await _notifications.activeAdminIds();
      return await _remote.create(
        id: id,
        build: (folio) => IncidentModel(
          id: id,
          folio: folio,
          title: data.title,
          type: data.type,
          description: data.description,
          housingId: housingId,
          createdBy: residentId,
          // Toda incidencia empieza como pendiente de asignación.
          status: IncidentStatus.pending,
          evidenceBefore: urls,
        ),
        // El administrador recibe el aviso de que hay una incidencia
        // pendiente de asignar.
        alsoWrite: (transaction, incident) =>
            _notifications.addNewIncidentNotices(
              transaction,
              adminIds: adminIds,
              incidentId: incident.id,
              reportNumber: incident.reportNumber,
              title: incident.title,
            ),
      );
    } on FirebaseException catch (e) {
      throw _failureFor(e);
    }
  }

  @override
  Stream<Incident?> watchById(String id) {
    return _remote.watchById(id).handleError((Object e) {
      throw switch (e) {
        FirebaseException(code: 'unavailable') => IncidentFailure.network,
        FirebaseException(code: 'permission-denied') =>
          IncidentFailure.accessDenied,
        _ => IncidentFailure.loadFailed,
      };
    });
  }

  static IncidentFailure _failureFor(FirebaseException e) => switch (e.code) {
    'unavailable' || 'deadline-exceeded' => IncidentFailure.network,
    'permission-denied' => IncidentFailure.permissionDenied,
    _ => IncidentFailure.unknown,
  };
}
