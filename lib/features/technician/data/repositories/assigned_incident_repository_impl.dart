import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../datasources/assigned_incident_remote_data_source.dart';

class AssignedIncidentRepositoryImpl implements AssignedIncidentRepository {
  AssignedIncidentRepositoryImpl({AssignedIncidentRemoteDataSource? remote})
    : _remote = remote ?? AssignedIncidentRemoteDataSource();

  final AssignedIncidentRemoteDataSource _remote;

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
