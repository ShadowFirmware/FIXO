import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/admin/domain/entities/history_incident.dart';
import 'package:fixo/features/admin/presentation/widgets/history_incident_detail.dart';
import 'package:fixo/features/admin/presentation/widgets/history_incident_widgets.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/widgets/incident_history_card.dart';
import 'package:fixo/features/technician/data/models/start_attention_plan.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/usecases/start_attention.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incidents_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_home_screen.dart';
import 'package:fixo/features/technician/presentation/widgets/assigned_incident_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.5 Comenzar la atención de una incidencia: validaciones, cambio de
/// estado, botón en la lista y reflejo del cambio en el sistema.
void main() {
  final now = DateTime(2026, 11, 9, 9);
  final startedAt = DateTime(2026, 11, 9, 10, 5);

  group('validaciones', () {
    void validate({
      String status = 'asignada',
      String? assignedTo = technicianId,
      Map<String, dynamic>? technician = const {
        'rol': 'tecnico',
        'estadoCuenta': 'activa',
      },
    }) => StartAttentionPlan.validate(
      incident: {'estado': status, 'tecnicoId': assignedTo},
      technician: technician,
      technicianId: technicianId,
      now: now,
    );

    test('PU-538 solo el técnico asignado, con su cuenta activa, puede '
        'comenzarla', () {
      expect(validate, returnsNormally);
      expect(
        () => validate(assignedTo: 'otro-tecnico'),
        throwsA(isA<NotAssignedToTechnicianException>()),
      );
      expect(
        () => validate(assignedTo: null),
        throwsA(isA<NotAssignedToTechnicianException>()),
      );

      for (final technician in <Map<String, dynamic>?>[
        null,
        {'rol': 'residente', 'estadoCuenta': 'activa'},
        {'rol': 'tecnico', 'estadoCuenta': 'deshabilitada'},
        {
          'rol': 'tecnico',
          'estadoCuenta': 'activa',
          'suspendidaHasta': Timestamp.fromDate(DateTime(2026, 11, 10)),
        },
      ]) {
        expect(
          () => validate(technician: technician),
          throwsA(isA<TechnicianCannotAttendException>()),
        );
      }
      // Una suspensión que ya terminó no impide comenzar.
      expect(
        () => validate(
          technician: {
            'rol': 'tecnico',
            'estadoCuenta': 'activa',
            'suspendidaHasta': Timestamp.fromDate(DateTime(2026, 11, 1)),
          },
        ),
        returnsNormally,
      );
    });

    test('PU-539 solo una incidencia Asignada se puede comenzar, y una En '
        'proceso no puede volver a iniciarse', () async {
      expect(
        () => validate(status: 'en_proceso'),
        throwsA(isA<AttentionAlreadyStartedException>()),
      );
      for (final (value, status) in [
        ('resuelta', IncidentStatus.resolved),
        ('rechazada', IncidentStatus.rejected),
        ('pendiente', IncidentStatus.pending),
      ]) {
        expect(
          () => validate(status: value),
          throwsA(
            isA<AttentionNotAvailableException>().having(
              (e) => e.status,
              'status',
              status,
            ),
          ),
        );
      }

      final remote = FakeAssignedIncidentRemoteDataSource();
      final repository = AssignedIncidentRepositoryImpl(remote: remote);
      for (final (error, failure) in <(Object, IncidentFailure)>[
        (
          const AttentionAlreadyStartedException(),
          IncidentFailure.attentionAlreadyStarted,
        ),
        (
          const AttentionNotAvailableException(IncidentStatus.resolved),
          IncidentFailure.attentionResolved,
        ),
        (
          const AttentionNotAvailableException(IncidentStatus.rejected),
          IncidentFailure.attentionRejected,
        ),
        (
          const AttentionNotAvailableException(IncidentStatus.pending),
          IncidentFailure.attentionNotAvailable,
        ),
        (
          const TechnicianCannotAttendException(),
          IncidentFailure.technicianCannotAttend,
        ),
      ]) {
        remote.startError = error;
        await expectLater(
          repository.startAttention(
            incidentId: 'inc-1',
            technicianId: technicianId,
          ),
          throwsA(failure),
        );
      }
      expect(
        IncidentFailure.attentionAlreadyStarted.message,
        contains('no puede volver a iniciarse'),
      );
    });

    test(
      'PU-540 un técnico con la cuenta suspendida no puede comenzarla',
      () async {
        final repository = FakeAssignedIncidentRepository();
        const suspended = AppUser(
          uid: technicianId,
          name: 'Juan Pérez Ramírez',
          email: 'juan@correo.com',
          phone: '7774445566',
          role: UserRole.technician,
          accountStatus: AccountStatus.suspended,
        );

        await expectLater(
          StartAttention(repository)(
            technician: suspended,
            incidentId: 'inc-1',
          ),
          throwsA(IncidentFailure.technicianCannotAttend),
        );
        expect(repository.started, isEmpty);
      },
    );
  });

  group('cambio de estado', () {
    test('PU-541 se guarda En proceso y se avisa a los '
        'administradores', () async {
      final update = StartAttentionPlan.incidentUpdate;
      expect(update['estado'], IncidentStatus.inProgress.value);
      expect(update['fechaInicioAtencion'], isA<FieldValue>());

      final remote = FakeAssignedIncidentRemoteDataSource()
        ..adminIds = ['uid-admin', 'uid-admin-2'];
      final repository = AssignedIncidentRepositoryImpl(remote: remote);
      await repository.startAttention(
        incidentId: 'inc-1',
        technicianId: technicianId,
      );
      expect(remote.started.single.incidentId, 'inc-1');
      expect(remote.notifiedAdmins.single, ['uid-admin', 'uid-admin-2']);

      // Si no se pueden consultar los administradores, comienza igual.
      remote.adminIds = null;
      await repository.startAttention(
        incidentId: 'inc-2',
        technicianId: technicianId,
      );
      expect(remote.started.last.incidentId, 'inc-2');
      expect(remote.notifiedAdmins.last, isEmpty);
    });

    test('PU-542 la fecha de inicio de la atención se lee de Firestore', () {
      final incident = IncidentModel.fromMap('inc-1', {
        'folio': 1,
        'nombre': 'Fuga',
        'tipo': 'agua',
        'detalles': '',
        'viviendaId': 'viv-4b',
        'creadaPor': 'res-ana',
        'estado': 'en_proceso',
        'tecnicoId': technicianId,
        'fechaInicioAtencion': Timestamp.fromDate(startedAt),
      });
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.startedAt, startedAt);
      expect(
        incident.toFirestore()['fechaInicioAtencion'],
        Timestamp.fromDate(startedAt),
      );
    });

    test('PU-543 el cambio se refleja para el técnico, el residente y el '
        'administrador', () {
      final incident = assignedIncident(
        1,
        status: IncidentStatus.inProgress,
      ).withStartedAt(startedAt);
      final since = 'En atención desde ${DateFormats.dateTime(startedAt)}';

      // Técnico: la tarjeta de la lista.
      expect(AssignedIncidentCard.noteOf(incident)?.$2, since);
      // Residente: la tarjeta del historial.
      expect(IncidentHistoryCard.noteFor(incident), since);
      // Administrador: el detalle del historial.
      final rows = historyDetailRows(
        HistoryIncident(
          incident: incident,
          housingLabel: 'Torre A – 4B',
          reporterName: 'Ana López',
          technicianName: 'Juan Pérez Ramírez',
        ),
      );
      expect(
        rows,
        contains(('Inicio de la atención', formatHistoryDate(startedAt))),
      );

      // Mientras sigue Asignada se muestra la llegada estimada.
      final assigned = assignedIncident(1, estimatedTime: now);
      expect(
        AssignedIncidentCard.noteOf(assigned)?.$2,
        'Llegada estimada: ${DateFormats.dateTime(now)}',
      );
    });
  });

  group('botón en la lista', () {
    late FakeAssignedIncidentRepository repository;
    late AssignedIncidentsViewModel viewModel;

    setUp(() {
      repository = FakeAssignedIncidentRepository();
      viewModel = AssignedIncidentsViewModel(
        session: AuthSession.withRepository(FakeAuthRepository())
          ..start(TestUsers.technician),
        repository: repository,
      );
    });

    tearDown(() => viewModel.dispose());

    Future<void> pumpList(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianHomeScreen(viewModel: viewModel),
        ),
      );
      repository.listController.add([
        assignedItem(assignedIncident(1)),
        assignedItem(
          assignedIncident(
            2,
            status: IncidentStatus.inProgress,
          ).withStartedAt(startedAt),
        ),
      ]);
      await tester.pumpAndSettle();
    }

    testWidgets('PU-544 Comenzar atención solo aparece en las Asignadas y '
        'pasa la incidencia a En proceso', (tester) async {
      await pumpList(tester);
      expect(find.byKey(const Key('assigned.start.inc-1')), findsOneWidget);
      expect(find.byKey(const Key('assigned.start.inc-2')), findsNothing);
      expect(
        find.text('En atención desde ${DateFormats.dateTime(startedAt)}'),
        findsOneWidget,
      );

      final gate = repository.startGate = Completer<void>();
      await tester.tap(find.byKey(const Key('assigned.start.inc-1')));
      await tester.pumpAndSettle();
      expect(find.text('¿Comenzar la atención?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('detail.startConfirm')));
      await tester.pump();
      expect(find.text('Comenzando…'), findsOneWidget);

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(repository.started, [
        (incidentId: 'inc-1', technicianId: technicianId),
      ]);
      expect(find.text('Comenzaste la atención de INC-0001.'), findsOneWidget);

      // Firestore avisa del nuevo estado y el botón desaparece.
      repository.listController.add([
        assignedItem(
          assignedIncident(
            1,
            status: IncidentStatus.inProgress,
          ).withStartedAt(startedAt),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assigned.start.inc-1')), findsNothing);
    });

    testWidgets('PU-545 informa si no se pudo comenzar desde la lista', (
      tester,
    ) async {
      await pumpList(tester);
      repository.startError = IncidentFailure.attentionAlreadyStarted;

      await tester.tap(find.byKey(const Key('assigned.start.inc-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail.startConfirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(IncidentFailure.attentionAlreadyStarted.message),
        findsOneWidget,
      );
      expect(repository.started, isEmpty);
      // El botón vuelve a estar disponible hasta que Firestore cambie.
      expect(find.text('Comenzar atención'), findsOneWidget);
    });
  });
}

extension on Incident {
  /// La misma incidencia con la fecha de inicio de la atención.
  Incident withStartedAt(DateTime date) => Incident(
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
    estimatedTime: estimatedTime,
    createdAt: createdAt,
    startedAt: date,
  );
}
