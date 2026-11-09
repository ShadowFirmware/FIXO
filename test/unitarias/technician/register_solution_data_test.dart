import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/utils/validators.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/incidents/data/datasources/evidence_storage_data_source.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/data/models/solution_plan.dart';
import 'package:fixo/features/technician/data/models/start_attention_plan.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/usecases/register_solution.dart';
import 'package:fixo/features/technician/domain/usecases/watch_resolved_incidents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../incidents/fakes.dart' as incidents;
import 'assigned_incidents_fakes.dart';

/// HU-3.6 Registrar la solución y evidencias de una incidencia: reglas,
/// datos y consulta.
void main() {
  const solution = 'Se cambió el empaque de la llave del baño.';

  test('PU-546 la descripción de la solución es obligatoria', () {
    expect(
      Validators.solutionDescription('  '),
      'Describe la solución aplicada',
    );
    expect(
      Validators.solutionDescription('Listo'),
      'La descripción debe tener al menos 10 caracteres',
    );
    expect(
      Validators.solutionDescription('a' * 501),
      'La descripción no debe pasar de 500 caracteres',
    );
    expect(Validators.solutionDescription(solution), isNull);
  });

  test('PU-547 solo el técnico asignado registra la solución de una '
      'incidencia En proceso', () {
    void validate({
      String status = 'en_proceso',
      String? assignedTo = technicianId,
      String account = 'activa',
    }) => SolutionPlan.validate(
      incident: {'estado': status, 'tecnicoId': assignedTo},
      technician: {'rol': 'tecnico', 'estadoCuenta': account},
      technicianId: technicianId,
      now: DateTime(2026, 11, 9),
    );

    expect(validate, returnsNormally);
    expect(
      () => validate(assignedTo: 'otro-tecnico'),
      throwsA(isA<NotAssignedToTechnicianException>()),
    );
    expect(
      () => validate(account: 'deshabilitada'),
      throwsA(isA<TechnicianCannotAttendException>()),
    );
    expect(
      () => validate(status: 'resuelta'),
      throwsA(isA<SolutionAlreadyRegisteredException>()),
    );
    expect(
      () => validate(status: 'asignada'),
      throwsA(isA<AttentionNotStartedException>()),
    );
    for (final status in ['pendiente', 'rechazada']) {
      expect(
        () => validate(status: status),
        throwsA(isA<SolutionNotAvailableException>()),
      );
    }

    // Solo una vez: con la solución registrada ya no se puede registrar otra.
    expect(
      () => SolutionPlan.validate(
        incident: {
          'estado': 'en_proceso',
          'tecnicoId': technicianId,
          'solucion': solution,
        },
        technician: {'rol': 'tecnico', 'estadoCuenta': 'activa'},
        technicianId: technicianId,
        now: DateTime(2026, 11, 9),
      ),
      throwsA(isA<SolutionAlreadyRegisteredException>()),
    );

    // La incidencia sigue En proceso hasta que se finaliza (HU-3.7).
    final update = SolutionPlan.incidentUpdate(
      solution: '  $solution ',
      evidenceUrls: const ['https://cdn/1.jpg'],
    );
    expect(update.containsKey('estado'), isFalse);
    expect(update['solucion'], solution);
    expect(update['evidenciasDespues'], ['https://cdn/1.jpg']);
    expect(update['fechaSolucion'], isA<FieldValue>());
  });

  group('repositorio', () {
    late FakeAssignedIncidentRemoteDataSource remote;

    setUp(() => remote = FakeAssignedIncidentRemoteDataSource());

    test('PU-548 sube las evidencias y después guarda la solución', () async {
      final repository = AssignedIncidentRepositoryImpl(
        remote: remote,
        storage: incidents.FakeEvidenceStorage(),
      );
      await repository.registerSolution(
        incidentId: 'inc-1',
        technicianId: technicianId,
        solution: solution,
        evidence: const [incidents.photo, incidents.video],
      );
      expect(remote.solutions.single.solution, solution);
      expect(remote.solutions.single.evidenceUrls, [
        'https://storage/inc-1/despues/1.jpg',
        'https://storage/inc-1/despues/2.mp4',
      ]);

      // Si las evidencias no se suben, la incidencia no se resuelve.
      for (final (error, failure) in [
        (const EvidenceUploadException(network: true), IncidentFailure.offline),
        (const EvidenceUploadException(), IncidentFailure.evidenceUpload),
      ]) {
        final failing = AssignedIncidentRepositoryImpl(
          remote: remote,
          storage: incidents.FakeEvidenceStorage(error: error),
        );
        await expectLater(
          failing.registerSolution(
            incidentId: 'inc-2',
            technicianId: technicianId,
            solution: solution,
            evidence: const [incidents.photo],
          ),
          throwsA(failure),
        );
      }
      expect(remote.solutions, hasLength(1));

      for (final (error, failure) in <(Object, IncidentFailure)>[
        (
          const SolutionAlreadyRegisteredException(),
          IncidentFailure.solutionAlreadyRegistered,
        ),
        (
          const AttentionNotStartedException(),
          IncidentFailure.attentionNotStarted,
        ),
        (
          const SolutionNotAvailableException(),
          IncidentFailure.solutionNotAvailable,
        ),
        (
          const NotAssignedToTechnicianException(),
          IncidentFailure.notAssignedToYou,
        ),
      ]) {
        remote.solutionError = error;
        await expectLater(
          repository.registerSolution(
            incidentId: 'inc-1',
            technicianId: technicianId,
            solution: solution,
            evidence: const [incidents.photo],
          ),
          throwsA(failure),
        );
      }
    });
  });

  test('PU-549 valida los datos y evidencias obligatorias antes de '
      'subirlas', () async {
    final repository = FakeAssignedIncidentRepository();
    final register = RegisterSolution(repository);
    Future<void> call({
      AppUser? technician,
      String text = solution,
      bool withEvidence = true,
    }) => register(
      technician: technician ?? TestUsers.technician,
      incidentId: 'inc-1',
      solution: text,
      evidence: withEvidence ? const [incidents.photo] : const [],
    );

    await expectLater(
      call(technician: TestUsers.resident()),
      throwsA(IncidentFailure.assignedAccessDenied),
    );
    await expectLater(
      call(text: 'Listo'),
      throwsA(
        isA<SolutionIncompleteException>().having(
          (e) => e.message,
          'message',
          'La descripción debe tener al menos 10 caracteres',
        ),
      ),
    );
    await expectLater(
      call(withEvidence: false),
      throwsA(
        isA<SolutionIncompleteException>().having(
          (e) => e.message,
          'message',
          RegisterSolution.missingEvidenceMessage,
        ),
      ),
    );
    expect(repository.solutions, isEmpty);

    await call(text: '  $solution  ');
    expect(repository.solutions.single.solution, solution);
    expect(repository.solutions.single.technicianId, technicianId);
  });

  test('PU-550 el historial del técnico muestra sus incidencias '
      'resueltas', () async {
    final repository = FakeAssignedIncidentRepository();
    final next = WatchResolvedIncidents(repository)(
      technician: TestUsers.technician,
    ).first;

    const resolved = IncidentStatus.resolved;
    repository.listController.add([
      assignedItem(assignedIncident(1, status: resolved).resolvedOn(9)),
      assignedItem(assignedIncident(2, status: resolved).resolvedOn(12)),
      assignedItem(assignedIncident(3, status: IncidentStatus.inProgress)),
      assignedItem(
        assignedIncident(
          4,
          status: resolved,
          technician: 'otro-tecnico',
        ).resolvedOn(10),
      ),
    ]);
    expect((await next).map((i) => i.incident.folio), [2, 1]);
  });
}

extension on Incident {
  /// La misma incidencia resuelta el [day] de noviembre de 2026.
  Incident resolvedOn(int day) => Incident(
    id: id,
    folio: folio,
    title: title,
    type: type,
    description: description,
    housingId: housingId,
    createdBy: createdBy,
    status: status,
    // Con this: `technicianId` solo es la constante del técnico de prueba.
    technicianId: this.technicianId,
    createdAt: createdAt,
    resolvedAt: DateTime(2026, 11, day),
    solution: 'Se cambió el empaque.',
  );
}
