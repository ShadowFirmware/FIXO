import 'package:firebase_core/firebase_core.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/admin/data/datasources/incident_admin_remote_data_source.dart';
import 'package:fixo/features/admin/data/repositories/incident_admin_repository_impl.dart';
import 'package:fixo/features/admin/domain/entities/pending_incident.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pending_incidents_fakes.dart';

/// HU-4.8 Consultar incidencias pendientes de asignación: repositorio.
void main() {
  late FakeIncidentAdminRemoteDataSource remote;
  late IncidentAdminRepositoryImpl repository;

  setUp(() {
    remote = FakeIncidentAdminRemoteDataSource()
      ..userNames = {'res-ana': 'Ana López'}
      ..housingLabels = {'viv-4b': 'Torre A – 4B'};
    repository = IncidentAdminRepositoryImpl(remote: remote);
  });

  test('PU-426 ordena de la más antigua a la más reciente; sin fecha al final',
      () async {
    final next = repository.watchPending().first;
    remote.controller.add([
      pendingIncident(3, createdAt: DateTime(2026, 10, 3)),
      pendingIncident(4),
      pendingIncident(1, createdAt: DateTime(2026, 10, 1)),
      pendingIncident(2, createdAt: DateTime(2026, 10, 2)),
    ]);
    final list = await next;
    expect(list.map((p) => p.incident.folio), [1, 2, 3, 4]);
  });

  test('PU-427 a igual fecha se ordena por número de reporte', () async {
    final date = DateTime(2026, 10, 1, 9);
    final next = repository.watchPending().first;
    remote.controller.add([
      pendingIncident(5, createdAt: date),
      pendingIncident(2, createdAt: date),
    ]);
    expect((await next).map((p) => p.incident.folio), [2, 5]);
  });

  test('PU-428 agrega el departamento y el nombre de quien reportó', () async {
    final next = repository.watchPending().first;
    remote.controller.add([
      pendingIncident(1, createdAt: DateTime(2026, 10, 1)),
      pendingIncident(2, housingId: 'no-existe', createdBy: 'no-existe'),
    ]);
    final list = await next;
    expect(list[0].housingLabel, 'Torre A – 4B');
    expect(list[0].reporterName, 'Ana López');
    expect(list[1].housingLabel, 'Sin registrar');
    expect(list[1].reporterName, 'Sin registrar');
  });

  test('PU-429 no vuelve a leer el nombre del mismo usuario', () async {
    final updates = <List<PendingIncident>>[];
    final sub = repository.watchPending().listen(updates.add);
    remote.controller.add([pendingIncident(1), pendingIncident(2)]);
    await pumpEventQueue();
    remote.controller.add([pendingIncident(2)]);
    await pumpEventQueue();
    await sub.cancel();
    expect(updates, hasLength(2));
    expect(remote.userReads, ['res-ana']);
  });

  test('PU-430 sin conexión se traduce al mensaje correspondiente', () async {
    final error = repository.watchPending().first;
    remote.controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    await expectLater(error, throwsA(IncidentFailure.offline));
  });

  test('PU-431 errores de asignar y rechazar se traducen', () async {
    remote.actionError = const IncidentNotPendingException();
    await expectLater(
      repository.reject(incidentId: 'inc-1', comment: 'x'),
      throwsA(IncidentFailure.notPending),
    );
    remote.actionError = const TechnicianUnavailableException();
    await expectLater(
      repository.assign(
        incidentId: 'inc-1',
        technicianId: 'tec-1',
        estimatedTime: DateTime(2030),
      ),
      throwsA(IncidentFailure.technicianUnavailable),
    );
  });

  test('PU-432 el comentario de rechazo se guarda sin espacios extra',
      () async {
    await repository.reject(incidentId: 'inc-1', comment: '  No procede  ');
    expect(remote.lastComment, 'No procede');
  });
}
