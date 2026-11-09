import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/data/models/finalize_plan.dart';
import 'package:fixo/features/technician/data/models/start_attention_plan.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/entities/finalize_conditions.dart';
import 'package:fixo/features/technician/domain/usecases/finalize_incident.dart';
import 'package:fixo/features/technician/domain/usecases/watch_assigned_incidents.dart';
import 'package:fixo/features/technician/domain/usecases/watch_resolved_incidents.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:fixo/features/technician/presentation/widgets/assigned_incident_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

const solution = 'Se cambió el empaque de la llave del baño.';

/// HU-3.7 Finalizar una incidencia como resuelta: condiciones, cambios en
/// Firestore, confirmación y listas.
void main() {
  final registeredAt = DateTime(2026, 11, 9, 11);

  /// Incidencia En proceso con la solución registrada.
  final withSolution = assignedIncident(
    1,
    status: IncidentStatus.inProgress,
  ).withSolution(registeredAt);

  group('condiciones', () {
    test('PU-558 solo se finaliza una incidencia propia En proceso con la '
        'solución registrada', () {
      IncidentFailure? check(Incident incident, [String? uid = technicianId]) =>
          FinalizeConditions.check(incident, technicianId: uid);

      expect(check(withSolution), isNull);
      expect(
        check(withSolution, 'otro-tecnico'),
        IncidentFailure.notAssignedToYou,
      );
      expect(check(withSolution, null), IncidentFailure.notAssignedToYou);
      expect(
        check(assignedIncident(1, status: IncidentStatus.inProgress)),
        IncidentFailure.solutionRequired,
      );
      expect(
        check(assignedIncident(1, status: IncidentStatus.resolved)),
        IncidentFailure.incidentAlreadyFinalized,
      );
      for (final status in [
        IncidentStatus.pending,
        IncidentStatus.assigned,
        IncidentStatus.rejected,
      ]) {
        expect(
          check(assignedIncident(1, status: status)),
          IncidentFailure.finalizeNotAvailable,
        );
      }
    });

    test('PU-559 la transacción revisa las condiciones y prepara los '
        'cambios', () {
      void validate({
        String status = 'en_proceso',
        String? assignedTo = technicianId,
        String? registered = solution,
        String account = 'activa',
      }) => FinalizePlan.validate(
        incident: {
          'estado': status,
          'tecnicoId': assignedTo,
          'solucion': registered,
        },
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
        () => validate(account: 'suspendida'),
        throwsA(isA<TechnicianCannotAttendException>()),
      );
      expect(
        () => validate(registered: '  '),
        throwsA(isA<SolutionRequiredException>()),
      );
      expect(
        () => validate(status: 'resuelta'),
        throwsA(isA<IncidentAlreadyFinalizedException>()),
      );
      expect(
        () => validate(status: 'asignada'),
        throwsA(isA<FinalizeNotAvailableException>()),
      );

      // Estado, fecha de resolución y cierre del chat.
      final update = FinalizePlan.incidentUpdate;
      expect(update['estado'], IncidentStatus.resolved.value);
      expect(update['fechaResolucion'], isA<FieldValue>());
      expect(update['chatCerrado'], isTrue);
      // El técnico queda Disponible.
      expect(FinalizePlan.technicianUpdate, {'disponible': true});

      final notice = FinalizePlan.notice(
        userId: 'res-ana',
        incidentId: 'inc-1',
        reportNumber: 'INC-0001',
        title: 'Fuga 1',
        technicianName: 'Juan Pérez',
        solution: 'x' * 300,
      );
      expect(notice['usuarioId'], 'res-ana');
      expect(notice['tipo'], FinalizePlan.resolvedType);
      expect(notice['titulo'], 'Incidencia INC-0001 resuelta');
      expect(
        notice['mensaje'],
        'Juan Pérez resolvió "Fuga 1". Solución: ${'x' * 200}… Consulta la '
        'solución y las evidencias en el detalle.',
      );
    });

    test('PU-560 el repositorio avisa a los administradores y traduce los '
        'errores', () async {
      final remote = FakeAssignedIncidentRemoteDataSource()
        ..adminIds = ['uid-admin', 'uid-admin-2'];
      final repository = AssignedIncidentRepositoryImpl(remote: remote);

      await repository.finalize(
        incidentId: 'inc-1',
        technicianId: technicianId,
      );
      expect(remote.finalized, [
        (incidentId: 'inc-1', technicianId: technicianId),
      ]);
      expect(remote.notifiedAdmins.last, ['uid-admin', 'uid-admin-2']);

      // Si no se pueden consultar los administradores, se finaliza igual.
      remote.adminIds = null;
      await repository.finalize(
        incidentId: 'inc-2',
        technicianId: technicianId,
      );
      expect(remote.finalized.last.incidentId, 'inc-2');
      expect(remote.notifiedAdmins.last, isEmpty);

      for (final (error, failure) in <(Object, IncidentFailure)>[
        (
          const NotAssignedToTechnicianException(),
          IncidentFailure.notAssignedToYou,
        ),
        (
          const TechnicianCannotAttendException(),
          IncidentFailure.technicianCannotAttend,
        ),
        (const SolutionRequiredException(), IncidentFailure.solutionRequired),
        (
          const IncidentAlreadyFinalizedException(),
          IncidentFailure.incidentAlreadyFinalized,
        ),
        (
          const FinalizeNotAvailableException(),
          IncidentFailure.finalizeNotAvailable,
        ),
        (
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
          IncidentFailure.offline,
        ),
      ]) {
        remote.finalizeError = error;
        await expectLater(
          repository.finalize(incidentId: 'inc-1', technicianId: technicianId),
          throwsA(failure),
        );
      }
    });

    test(
      'PU-561 solo un técnico con la cuenta activa puede finalizar',
      () async {
        final repository = FakeAssignedIncidentRepository();
        final finalize = FinalizeIncident(repository);
        const suspended = AppUser(
          uid: technicianId,
          name: 'Juan Pérez Ramírez',
          email: 'juan@correo.com',
          phone: '7774445566',
          role: UserRole.technician,
          accountStatus: AccountStatus.suspended,
        );

        await expectLater(
          finalize(technician: TestUsers.resident(), incidentId: 'inc-1'),
          throwsA(IncidentFailure.assignedAccessDenied),
        );
        await expectLater(
          finalize(technician: suspended, incidentId: 'inc-1'),
          throwsA(IncidentFailure.technicianCannotAttend),
        );
        expect(repository.finalized, isEmpty);

        await finalize(technician: TestUsers.technician, incidentId: 'inc-1');
        expect(repository.finalized.single.incidentId, 'inc-1');
      },
    );

    test('PU-562 se leen la fecha de la solución y el cierre del chat', () {
      final incident = IncidentModel.fromMap('inc-1', {
        'folio': 1,
        'nombre': 'Fuga',
        'tipo': 'agua',
        'detalles': '',
        'viviendaId': 'viv-4b',
        'creadaPor': 'res-ana',
        'estado': 'resuelta',
        'tecnicoId': technicianId,
        'solucion': solution,
        'fechaSolucion': Timestamp.fromDate(registeredAt),
        'chatCerrado': true,
      });
      expect(incident.solutionRegisteredAt, registeredAt);
      expect(incident.chatClosed, isTrue);
      expect(incident.toFirestore()['chatCerrado'], isTrue);
      expect(
        incident.toFirestore()['fechaSolucion'],
        Timestamp.fromDate(registeredAt),
      );

      // Una incidencia sin el campo tiene el chat abierto.
      final open = IncidentModel.fromMap('inc-2', {
        'tipo': 'agua',
        'estado': 'en_proceso',
      });
      expect(open.chatClosed, isFalse);
    });
  });

  group('pantalla y listas', () {
    late AuthSession session;
    late FakeAssignedIncidentRepository repository;

    setUp(() {
      session = AuthSession.withRepository(FakeAuthRepository())
        ..start(TestUsers.technician);
      repository = FakeAssignedIncidentRepository();
    });

    Future<void> pumpDetail(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final detail = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
        session: session,
        repository: repository,
      );
      addTearDown(detail.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TechnicianIncidentDetailScreen(
                      incidentId: 'inc-1',
                      viewModel: detail,
                    ),
                  ),
                ),
                child: const Text('Lista'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lista'));
      // Mientras carga gira el indicador: se espera solo la transición.
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('PU-563 Finalizar incidencia pide confirmación, finaliza y '
        'vuelve a la lista', (tester) async {
      await pumpDetail(tester);

      // Sin solución registrada solo se puede registrar.
      repository.detailController.add(
        assignedItem(assignedIncident(1, status: IncidentStatus.inProgress)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail.registerSolution')), findsOneWidget);
      expect(find.byKey(const Key('detail.finalize')), findsNothing);

      repository.detailController.add(assignedItem(withSolution));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail.registerSolution')), findsNothing);
      expect(find.text(solution), findsOneWidget);
      expect(find.text(DateFormats.dateTime(registeredAt)), findsOneWidget);

      // Cancelar no finaliza.
      await tester.tap(find.byKey(const Key('detail.finalize')));
      await tester.pumpAndSettle();
      expect(find.text('¿Finalizar la incidencia?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.finalized, isEmpty);

      final gate = repository.finalizeGate = Completer<void>();
      await tester.tap(find.byKey(const Key('detail.finalize')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail.finalizeConfirm')));
      await tester.pump();
      expect(find.text('Finalizando…'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.finalized, [
        (incidentId: 'inc-1', technicianId: technicianId),
      ]);
      expect(
        find.text(
          'Finalizaste la incidencia INC-0001. Ya está en tu historial.',
        ),
        findsOneWidget,
      );
      expect(find.byType(TechnicianIncidentDetailScreen), findsNothing);
      expect(find.text('Lista'), findsOneWidget);
    });

    testWidgets('PU-564 si no se puede finalizar se informa y se queda en el '
        'detalle', (tester) async {
      await pumpDetail(tester);
      repository
        ..finalizeError = IncidentFailure.incidentAlreadyFinalized
        ..detailController.add(assignedItem(withSolution));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail.finalize')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail.finalizeConfirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(IncidentFailure.incidentAlreadyFinalized.message),
        findsOneWidget,
      );
      expect(find.byType(TechnicianIncidentDetailScreen), findsOneWidget);
    });

    test('PU-565 al finalizarla deja las asignadas y pasa al historial de '
        'atendidas', () async {
      final assigned = WatchAssignedIncidents(repository)(
        technician: TestUsers.technician,
      );
      final resolved = WatchResolvedIncidents(repository)(
        technician: TestUsers.technician,
      );
      final lists = <String, List<int>>{};
      final subscriptions = [
        assigned.listen(
          (l) => lists['asignadas'] = [for (final i in l) i.incident.folio],
        ),
        resolved.listen(
          (l) => lists['atendidas'] = [for (final i in l) i.incident.folio],
        ),
      ];
      addTearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      });

      // Con la solución registrada sigue entre las asignadas.
      repository.listController.add([assignedItem(withSolution)]);
      await pumpEventQueue();
      expect(lists, {
        'asignadas': [1],
        'atendidas': <int>[],
      });
      expect(
        AssignedIncidentCard.noteOf(withSolution)?.$2,
        'Solución registrada: falta finalizar la incidencia',
      );

      // Al finalizarla pasa al historial.
      repository.listController.add([
        assignedItem(
          assignedIncident(
            1,
            status: IncidentStatus.resolved,
          ).withSolution(registeredAt),
        ),
      ]);
      await pumpEventQueue();
      expect(lists, {
        'asignadas': <int>[],
        'atendidas': [1],
      });
    });
  });
}

extension on Incident {
  /// La misma incidencia con la solución registrada el [date].
  Incident withSolution(DateTime date) => Incident(
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
    solution: solution, // La constante del archivo.
    solutionRegisteredAt: date,
    evidenceAfter: const ['https://res.cloudinary.com/fixo/image/upload/1.jpg'],
  );
}
