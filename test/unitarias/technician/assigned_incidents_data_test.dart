import 'package:firebase_core/firebase_core.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/usecases/watch_assigned_incident.dart';
import 'package:fixo/features/technician/domain/usecases/watch_assigned_incidents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.3 Consultar incidencias asignadas: datos, permisos y orden.
void main() {
  group('repositorio', () {
    late FakeAssignedIncidentRemoteDataSource remote;
    late AssignedIncidentRepositoryImpl repository;

    setUp(() {
      remote = FakeAssignedIncidentRemoteDataSource()
        ..housingLabels = {'viv-4b': 'Torre A – 4B'}
        ..contacts = {'res-ana': (name: 'Ana López', phone: '7771112233')};
      repository = AssignedIncidentRepositoryImpl(remote: remote);
    });

    test('PU-515 agrega el lugar y el residente de cada incidencia', () async {
      final next = repository.watchByTechnician(technicianId).first;
      remote.listController.add([
        assignedIncident(1),
        assignedIncident(2),
        assignedIncident(3, housingId: 'viv-x', createdBy: 'res-x'),
      ]);
      final list = await next;

      expect(list.map((i) => i.housingLabel), [
        'Torre A – 4B',
        'Torre A – 4B',
        'Sin registrar',
      ]);
      expect(list.first.residentName, 'Ana López');
      expect(list.first.residentPhone, '7771112233');
      expect(list.last.residentName, 'Sin registrar');
      expect(list.last.residentPhone, isNull);
      // La vivienda y el residente repetidos se consultan una sola vez.
      expect(remote.lookups['viv-4b'], 1);
      expect(remote.lookups['res-ana'], 1);
    });

    test('PU-516 traduce los errores de Firestore', () async {
      for (final (code, failure) in [
        ('unavailable', IncidentFailure.offline),
        ('permission-denied', IncidentFailure.assignedAccessDenied),
        ('internal', IncidentFailure.assignedLoadFailed),
      ]) {
        final error = repository.watchByTechnician(technicianId).first;
        remote.listController.addError(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        await expectLater(error, throwsA(failure));
      }

      final missing = repository.watchById('inc-9').first;
      remote.detailController.add(null);
      expect(await missing, isNull);

      final failed = repository.watchById('inc-1').first;
      remote.detailController.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'internal'),
      );
      await expectLater(failed, throwsA(IncidentFailure.loadFailed));
    });
  });

  group('incidencias del técnico autenticado', () {
    late FakeAssignedIncidentRepository repository;
    late WatchAssignedIncidents watch;

    setUp(() {
      repository = FakeAssignedIncidentRepository();
      watch = WatchAssignedIncidents(repository);
    });

    test('PU-517 solo un técnico puede consultarlas', () async {
      await expectLater(
        watch(technician: TestUsers.resident()),
        emitsError(IncidentFailure.assignedAccessDenied),
      );
      await expectLater(
        watch(technician: null),
        emitsError(IncidentFailure.assignedAccessDenied),
      );
      expect(repository.requestedTechnicians, isEmpty);
    });

    test(
      'PU-518 muestra solo las suyas en estado Asignada o En proceso',
      () async {
        final next = watch(technician: TestUsers.technician).first;
        expect(repository.requestedTechnicians, [technicianId]);

        repository.listController.add([
          assignedItem(assignedIncident(1)),
          assignedItem(assignedIncident(2, status: IncidentStatus.inProgress)),
          // Las resueltas pasan al historial.
          assignedItem(assignedIncident(3, status: IncidentStatus.resolved)),
          assignedItem(assignedIncident(4, status: IncidentStatus.rejected)),
          assignedItem(assignedIncident(5, status: IncidentStatus.pending)),
          // De otro técnico.
          assignedItem(assignedIncident(6, technician: 'otro-tecnico')),
        ]);
        expect((await next).map((i) => i.incident.folio), [1, 2]);
      },
    );

    test('PU-519 ordena por la llegada estimada más próxima', () async {
      final next = watch(technician: TestUsers.technician).first;
      repository.listController.add([
        assignedItem(assignedIncident(4)),
        assignedItem(
          assignedIncident(1, estimatedTime: DateTime(2026, 11, 9, 12)),
        ),
        assignedItem(assignedIncident(2)),
        assignedItem(
          assignedIncident(3, estimatedTime: DateTime(2026, 11, 9, 9)),
        ),
      ]);
      // Sin hora estimada van al final, por folio.
      expect((await next).map((i) => i.incident.folio), [3, 1, 2, 4]);
    });

    test(
      'PU-520 el detalle solo se muestra si la incidencia es suya',
      () async {
        final watchOne = WatchAssignedIncident(repository);
        final events = <Object?>[];
        final subscription = watchOne(
          technician: TestUsers.technician,
          id: 'inc-1',
        ).listen(events.add, onError: events.add);

        repository.detailController
          ..add(assignedItem(assignedIncident(1)))
          ..add(null)
          ..add(assignedItem(assignedIncident(1, technician: 'otro-tecnico')));
        await pumpEventQueue();
        await subscription.cancel();

        expect(repository.requestedIds, ['inc-1']);
        expect(events, [isNotNull, isNull, IncidentFailure.notAssignedToYou]);

        await expectLater(
          watchOne(technician: TestUsers.admin, id: 'inc-1'),
          emitsError(IncidentFailure.assignedAccessDenied),
        );
      },
    );
  });
}
