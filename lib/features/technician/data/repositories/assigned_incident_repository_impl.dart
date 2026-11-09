import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../incidents/data/datasources/evidence_storage_data_source.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../datasources/assigned_incident_remote_data_source.dart';
import '../models/finalize_plan.dart';
import '../models/solution_plan.dart';
import '../models/start_attention_plan.dart';

class AssignedIncidentRepositoryImpl implements AssignedIncidentRepository {
  AssignedIncidentRepositoryImpl({
    AssignedIncidentRemoteDataSource? remote,
    EvidenceStorageDataSource? storage,
  }) : _remote = remote ?? AssignedIncidentRemoteDataSource(),
       _storage = storage ?? EvidenceStorageDataSource();

  final AssignedIncidentRemoteDataSource _remote;
  final EvidenceStorageDataSource _storage;

  // Se consultan una sola vez aunque la lista se emita muchas veces.
  final _housings = <String, Future<Housing?>>{};
  final _contacts = <String, Future<_Contact>>{};

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

  @override
  Future<void> startAttention({
    required String incidentId,
    required String technicianId,
  }) async {
    try {
      // Si no se pueden consultar los administradores, la atención
      // comienza de todos modos y solo se avisa al residente.
      final adminIds = await _remote.activeAdminIds().catchError(
        (Object _) => const <String>[],
      );
      await _remote.startAttention(
        incidentId: incidentId,
        technicianId: technicianId,
        adminIds: adminIds,
      );
    } on NotAssignedToTechnicianException {
      throw IncidentFailure.notAssignedToYou;
    } on TechnicianCannotAttendException {
      throw IncidentFailure.technicianCannotAttend;
    } on AttentionAlreadyStartedException {
      throw IncidentFailure.attentionAlreadyStarted;
    } on AttentionNotAvailableException catch (e) {
      throw switch (e.status) {
        IncidentStatus.resolved => IncidentFailure.attentionResolved,
        IncidentStatus.rejected => IncidentFailure.attentionRejected,
        _ => IncidentFailure.attentionNotAvailable,
      };
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => IncidentFailure.offline,
        'permission-denied' => IncidentFailure.notAssignedToYou,
        _ => IncidentFailure.actionFailed,
      };
    }
  }

  @override
  Future<void> registerSolution({
    required String incidentId,
    required String technicianId,
    required String solution,
    required List<EvidenceFile> evidence,
  }) async {
    // Primero se suben las evidencias: si fallan, la incidencia no queda
    // resuelta sin ellas.
    final List<String> urls;
    try {
      urls = await _storage.uploadAfter(incidentId, evidence);
    } on EvidenceUploadException catch (e) {
      throw e.network
          ? IncidentFailure.offline
          : IncidentFailure.evidenceUpload;
    }

    try {
      await _remote.registerSolution(
        incidentId: incidentId,
        technicianId: technicianId,
        solution: solution,
        evidenceUrls: urls,
      );
    } on NotAssignedToTechnicianException {
      throw IncidentFailure.notAssignedToYou;
    } on TechnicianCannotAttendException {
      throw IncidentFailure.technicianCannotAttend;
    } on SolutionAlreadyRegisteredException {
      throw IncidentFailure.solutionAlreadyRegistered;
    } on AttentionNotStartedException {
      throw IncidentFailure.attentionNotStarted;
    } on SolutionNotAvailableException {
      throw IncidentFailure.solutionNotAvailable;
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => IncidentFailure.offline,
        'permission-denied' => IncidentFailure.notAssignedToYou,
        _ => IncidentFailure.actionFailed,
      };
    }
  }

  @override
  Future<void> finalize({
    required String incidentId,
    required String technicianId,
  }) async {
    try {
      await _remote.finalize(
        incidentId: incidentId,
        technicianId: technicianId,
      );
    } on NotAssignedToTechnicianException {
      throw IncidentFailure.notAssignedToYou;
    } on TechnicianCannotAttendException {
      throw IncidentFailure.technicianCannotAttend;
    } on SolutionRequiredException {
      throw IncidentFailure.solutionRequired;
    } on IncidentAlreadyFinalizedException {
      throw IncidentFailure.incidentAlreadyFinalized;
    } on FinalizeNotAvailableException {
      throw IncidentFailure.finalizeNotAvailable;
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => IncidentFailure.offline,
        'permission-denied' => IncidentFailure.notAssignedToYou,
        _ => IncidentFailure.actionFailed,
      };
    }
  }

  Future<AssignedIncident> _withContact(Incident incident) async {
    final (housing, resident) = await (
      _housings.putIfAbsent(
        incident.housingId,
        () => _housing(incident.housingId),
      ),
      _contacts.putIfAbsent(
        incident.createdBy,
        () => _contact(incident.createdBy),
      ),
    ).wait;
    return AssignedIncident(
      incident: incident,
      housingLabel: _textOr(housing?.label) ?? _unknown,
      housing: housing,
      residentName: resident.name,
      residentPhone: resident.phone,
      residentEmail: resident.email,
    );
  }

  Future<Housing?> _housing(String id) async {
    try {
      return await _remote.housing(id);
    } catch (_) {
      return null;
    }
  }

  Future<_Contact> _contact(String uid) async {
    try {
      final contact = await _remote.contact(uid);
      return (
        name: _textOr(contact?.name) ?? _unknown,
        phone: _textOr(contact?.phone),
        email: _textOr(contact?.email),
      );
    } catch (_) {
      return (name: _unknown, phone: null, email: null);
    }
  }

  static String? _textOr(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

typedef _Contact = ({String name, String? phone, String? email});
