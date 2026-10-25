import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/providers/incident_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';

/// HU-2.4 Consultar detalles de la incidencia.
void main() {
  final createdAt = DateTime(2026, 10, 20, 9, 30);
  final arrival = DateTime(2026, 10, 21, 16, 0);

  Incident incident({
    IncidentStatus status = IncidentStatus.pending,
    String housingId = 'vivienda-4b',
    String? technicianId,
    DateTime? estimatedTime,
    String? solution,
    DateTime? resolvedAt,
    List<String> evidenceAfter = const [],
    String? rejectionComment,
    DateTime? rejectedAt,
  }) => Incident(
    id: 'inc-1',
    folio: 7,
    title: 'Fuga en baño',
    type: IncidentType.water,
    description: 'Gotea la llave del lavabo',
    housingId: housingId,
    createdBy: 'uid-residente',
    status: status,
    technicianId: technicianId,
    estimatedTime: estimatedTime,
    solution: solution,
    resolvedAt: resolvedAt,
    evidenceBefore: const ['https://res.cloudinary.com/x/image/upload/1.jpg'],
    evidenceAfter: evidenceAfter,
    rejectionComment: rejectionComment,
    rejectedAt: rejectedAt,
    createdAt: createdAt,
  );

  late AuthSession session;
  late FakeIncidentRepository incidents;

  IncidentDetailViewModel createViewModel() {
    final vm = IncidentDetailViewModel(
      incidentId: 'inc-1',
      session: session,
      incidents: incidents,
      housings: FakeHousingRepository(),
      technicians: FakeTechnicianRepository(
        technicians: {'uid-tecnico': TestUsers.technician},
      ),
    );
    addTearDown(vm.dispose);
    return vm;
  }

  /// Simula que Firestore emite la incidencia y espera a que se cargue.
  Future<void> emit(Incident? value) async {
    incidents.changes.add(value);
    await pumpEventQueue();
  }

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.resident());
    incidents = FakeIncidentRepository();
  });

  test('PU-79 muestra la información general y las evidencias', () async {
    final vm = createViewModel();
    expect(vm.state, IncidentDetailState.loading);

    await emit(incident());

    expect(vm.state, IncidentDetailState.loaded);
    expect(incidents.watchedIds, ['inc-1']);
    expect(vm.incident!.reportNumber, 'INC-0007');
    expect(vm.incident!.title, 'Fuga en baño');
    expect(vm.type, 'Agua');
    expect(vm.housing, 'Torre A – 4B');
    expect(vm.createdAt, '20 de octubre de 2026, 9:30 a. m.');
    expect(vm.description, 'Gotea la llave del lavabo');
    expect(vm.incident!.evidenceBefore, hasLength(1));
  });

  test('PU-80 pendiente: sin técnico, solución ni rechazo', () async {
    final vm = createViewModel();
    await emit(incident());

    expect(vm.incident!.status.label, 'Pendiente');
    expect(vm.showTechnician, isFalse);
    expect(vm.estimatedArrival, isNull);
    expect(vm.isResolved, isFalse);
    expect(vm.isRejected, isFalse);
  });

  test('PU-81 asignada: muestra el técnico y la hora estimada', () async {
    final vm = createViewModel();
    await emit(
      incident(
        status: IncidentStatus.assigned,
        technicianId: 'uid-tecnico',
        estimatedTime: arrival,
      ),
    );

    expect(vm.incident!.status.label, 'Asignada');
    expect(vm.showTechnician, isTrue);
    expect(vm.technicianName, 'Juan Pérez Ramírez');
    expect(vm.technicianPhone, '7774445566');
    expect(vm.technicianSpecialty, 'Electricidad');
    expect(vm.estimatedArrival, '21 de octubre de 2026, 4:00 p. m.');
  });

  test('PU-82 resuelta: muestra la solución y sus evidencias', () async {
    final vm = createViewModel();
    await emit(
      incident(
        status: IncidentStatus.resolved,
        technicianId: 'uid-tecnico',
        solution: 'Se cambió el empaque de la llave',
        resolvedAt: DateTime(2026, 10, 21, 17, 15),
        evidenceAfter: const [
          'https://res.cloudinary.com/x/image/upload/2.jpg',
        ],
      ),
    );

    expect(vm.isResolved, isTrue);
    expect(vm.solution, 'Se cambió el empaque de la llave');
    expect(vm.resolvedAt, '21 de octubre de 2026, 5:15 p. m.');
    expect(vm.evidenceAfter, hasLength(1));
    expect(vm.showTechnician, isTrue);
  });

  test('PU-83 rechazada: muestra el motivo y la fecha, sin técnico ni '
      'hora estimada', () async {
    final vm = createViewModel();
    await emit(
      incident(
        status: IncidentStatus.rejected,
        // Aunque el documento tenga técnico, no se debe mostrar.
        technicianId: 'uid-tecnico',
        estimatedTime: arrival,
        rejectionComment: 'El problema es del área común',
        rejectedAt: DateTime(2026, 10, 20, 12, 0),
      ),
    );

    expect(vm.isRejected, isTrue);
    expect(vm.rejectionComment, 'El problema es del área común');
    expect(vm.rejectedAt, '20 de octubre de 2026, 12:00 p. m.');
    expect(vm.showTechnician, isFalse);
    expect(vm.estimatedArrival, isNull);
  });

  test('PU-84 se actualiza cuando cambia el estado en Firestore', () async {
    final vm = createViewModel();
    var notifications = 0;
    vm.addListener(() => notifications++);

    await emit(incident());
    expect(vm.showTechnician, isFalse);

    await emit(
      incident(
        status: IncidentStatus.inProgress,
        technicianId: 'uid-tecnico',
        estimatedTime: arrival,
      ),
    );

    expect(vm.incident!.status.label, 'En proceso');
    expect(vm.technicianName, 'Juan Pérez Ramírez');
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('PU-85 no se muestra una incidencia de otro departamento', () async {
    final vm = createViewModel();
    await emit(incident(housingId: 'vivienda-7c'));

    expect(vm.state, IncidentDetailState.error);
    expect(vm.isAccessDenied, isTrue);
    expect(vm.errorMessage, IncidentFailure.accessDenied.message);
    expect(vm.incident, isNull);
  });

  test('PU-86 un usuario que no es residente no puede consultarla', () async {
    session.start(TestUsers.technician);
    final vm = createViewModel();
    await pumpEventQueue();

    expect(vm.isAccessDenied, isTrue);
    expect(incidents.watchedIds, isEmpty);
  });

  test('PU-87 avisa si la incidencia no existe o no se pudo cargar', () async {
    final vm = createViewModel();

    await emit(null);
    expect(vm.state, IncidentDetailState.notFound);

    incidents.changes.addError(IncidentFailure.network);
    await pumpEventQueue();
    expect(vm.state, IncidentDetailState.error);
    expect(vm.errorMessage, IncidentFailure.network.message);
    expect(vm.isAccessDenied, isFalse);
  });
}
