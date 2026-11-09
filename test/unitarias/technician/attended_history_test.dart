import 'package:firebase_core/firebase_core.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/screens/incident_detail_screen.dart';
import 'package:fixo/features/technician/data/repositories/assigned_incident_repository_impl.dart';
import 'package:fixo/features/technician/domain/entities/assigned_incident.dart';
import 'package:fixo/features/technician/domain/usecases/watch_resolved_incidents.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/providers/resolved_incidents_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_history_screen.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:fixo/features/technician/presentation/widgets/attended_history_filters.dart';
import 'package:fixo/features/technician/presentation/widgets/attended_incident_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.8 Consultar historial de incidencias atendidas: consulta, datos del
/// historial, filtros y mensajes.
void main() {
  /// Incidencia resuelta el [day] de noviembre de 2026 a las 12:30, tras
  /// 2 h 15 min de atención.
  AssignedIncident attended(
    int folio, {
    int day = 9,
    IncidentType type = IncidentType.water,
    String? technician = technicianId,
    IncidentStatus status = IncidentStatus.resolved,
  }) => assignedItem(
    assignedIncident(
      folio,
      type: type,
      status: status,
      technician: technician,
    ).attended(day),
  );

  final history = [
    attended(1, day: 3),
    attended(2, day: 9, type: IncidentType.electricity),
    attended(3, day: 6),
  ];

  late AuthSession session;
  late FakeAssignedIncidentRepository repository;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.technician);
    repository = FakeAssignedIncidentRepository();
  });

  ResolvedIncidentsViewModel historyViewModel() {
    final viewModel = ResolvedIncidentsViewModel(
      session: session,
      repository: repository,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('consulta', () {
    test('PU-566 consulta en Firestore solo las resueltas del técnico y '
        'traduce los errores', () async {
      final remote = FakeAssignedIncidentRemoteDataSource()
        ..contacts = {'res-ana': (name: 'Ana López', phone: null, email: null)};
      final repository = AssignedIncidentRepositoryImpl(remote: remote);

      final next = repository.watchResolved(technicianId).first;
      remote.resolvedController.add([
        assignedIncident(1, status: IncidentStatus.resolved),
      ]);
      expect((await next).single.residentName, 'Ana López');

      for (final (code, failure) in [
        ('unavailable', IncidentFailure.offline),
        ('permission-denied', IncidentFailure.assignedAccessDenied),
        ('internal', IncidentFailure.technicianHistoryLoadFailed),
      ]) {
        final error = repository.watchResolved(technicianId).first;
        remote.resolvedController.addError(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        await expectLater(error, throwsA(failure));
      }
    });

    test('PU-567 el historial muestra únicamente las incidencias resueltas '
        'del técnico autenticado', () async {
      final watch = WatchResolvedIncidents(repository);
      await expectLater(
        watch(technician: TestUsers.resident()),
        emitsError(IncidentFailure.assignedAccessDenied),
      );

      final next = watch(technician: TestUsers.technician).first;
      expect(repository.requestedHistories, [technicianId]);
      repository.listController.add([
        ...history,
        attended(4, technician: 'otro-tecnico'),
        attended(5, status: IncidentStatus.inProgress),
      ]);
      // De la resuelta más recientemente a la más antigua.
      expect((await next).map((i) => i.incident.folio), [2, 3, 1]);
    });
  });

  test('PU-568 calcula la duración de la atención, las evidencias y el '
      'rango de fechas', () {
    final incident = history.first.incident;
    expect(AttendedIncidentCard.attentionTime(incident), '2 h 15 min');
    expect(
      AttendedIncidentCard.attentionTime(
        assignedIncident(1).attended(9, minutes: 45),
      ),
      '45 min',
    );
    expect(
      AttendedIncidentCard.attentionTime(
        assignedIncident(1).attended(9, minutes: 27 * 60),
      ),
      '1 d 3 h',
    );
    expect(AttendedIncidentCard.attentionTime(assignedIncident(1)), isNull);

    expect(AttendedIncidentCard.evidenceCount(incident), '2 evidencias');

    expect(AttendedHistoryFilters.dateRangeLabel(), 'Todas las fechas');
    expect(
      AttendedHistoryFilters.dateRangeLabel(
        from: DateTime(2026, 11),
        to: DateTime(2026, 11, 9),
      ),
      '1 nov 2026 – 9 nov 2026',
    );
    expect(
      AttendedHistoryFilters.dateRangeLabel(from: DateTime(2026, 11)),
      'Desde 1 nov 2026',
    );
  });

  group('filtros', () {
    test('PU-569 filtra por tipo y por fecha de resolución', () async {
      final vm = historyViewModel();
      repository.listController.add(history);
      await pumpEventQueue();
      expect(vm.results, hasLength(3));

      vm.setType(IncidentType.water);
      expect(vm.results.map((i) => i.incident.folio), [3, 1]);

      // Ambos días se incluyen completos.
      vm.setDateRange(from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 6));
      expect(vm.results.map((i) => i.incident.folio), [3, 1]);
      vm.setDateRange(from: DateTime(2026, 11, 4), to: DateTime(2026, 11, 6));
      expect(vm.results.map((i) => i.incident.folio), [3]);

      vm.setType(IncidentType.structure);
      expect(vm.results, isEmpty);
      expect(vm.emptyMessage, ResolvedIncidentsViewModel.noResultsMessage);

      vm.clearFilters();
      expect(vm.hasFilters, isFalse);
      expect(vm.results, hasLength(3));
      expect(vm.emptyMessage, isNull);
    });

    test('PU-570 avisa si no hay historial y permite reintentar tras un '
        'error', () async {
      final vm = historyViewModel();
      repository.listController.addError(IncidentFailure.offline);
      await pumpEventQueue();
      expect(vm.state, ResolvedIncidentsState.error);
      expect(vm.errorMessage, IncidentFailure.offline.message);

      vm.retry();
      expect(vm.state, ResolvedIncidentsState.loading);
      expect(repository.requestedHistories, hasLength(2));
      repository.listController.add(const []);
      await pumpEventQueue();
      expect(vm.emptyMessage, ResolvedIncidentsViewModel.noIncidentsMessage);
    });
  });

  group('pantallas', () {
    Future<ResolvedIncidentsViewModel> pumpHistory(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = historyViewModel();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianHistoryScreen(viewModel: vm),
        ),
      );
      return vm;
    }

    testWidgets('PU-571 muestra la información del historial y filtra por '
        'tipo', (tester) async {
      await pumpHistory(tester);
      repository.listController.add(history);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('history.total')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fuga 2'), findsOneWidget);
      expect(
        find.text(
          'Resuelta el ${DateFormats.dateTime(DateTime(2026, 11, 9, 12, 30))}',
        ),
        findsOneWidget,
      );
      expect(find.text('Solución: Se cambió el empaque.'), findsNWidgets(3));
      expect(find.text('2 evidencias'), findsNWidgets(3));
      expect(find.text('Atendida en 2 h 15 min'), findsNWidgets(3));
      expect(find.text('3 incidencias'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history.type.luz')));
      await tester.pumpAndSettle();
      expect(find.text('Fuga 2'), findsOneWidget);
      expect(find.text('Fuga 1'), findsNothing);
      expect(find.text('Mostrando 1 de 3'), findsOneWidget);
    });

    testWidgets('PU-572 muestra mensajes cuando no hay resultados', (
      tester,
    ) async {
      final vm = await pumpHistory(tester);
      repository.listController.add(const []);
      await tester.pumpAndSettle();
      expect(
        find.text(ResolvedIncidentsViewModel.noIncidentsMessage),
        findsOneWidget,
      );
      expect(find.byKey(const Key('history.type.all')), findsNothing);

      repository.listController.add(history);
      await tester.pumpAndSettle();
      vm.setDateRange(from: DateTime(2026, 10), to: DateTime(2026, 10, 31));
      await tester.pumpAndSettle();
      expect(find.text('1 oct 2026 – 31 oct 2026'), findsOneWidget);
      expect(
        find.text(ResolvedIncidentsViewModel.noResultsMessage),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('history.clearFilters')));
      await tester.pumpAndSettle();
      expect(find.text('Fuga 1'), findsOneWidget);
      expect(find.text('Todas las fechas'), findsOneWidget);
    });

    testWidgets('PU-573 el detalle muestra la solución, las evidencias y el '
        'resumen de la atención', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final detail = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
        initial: history.first,
        session: session,
        repository: repository,
      );
      addTearDown(detail.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianIncidentDetailScreen(
            incidentId: 'inc-1',
            viewModel: detail,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Se cambió el empaque.'), findsOneWidget);
      expect(find.text('EVIDENCIAS DEL TRABAJO'), findsOneWidget);
      expect(find.text('RESUMEN DE LA ATENCIÓN'), findsOneWidget);
      final summary = find.ancestor(
        of: find.text('RESUMEN DE LA ATENCIÓN'),
        matching: find.byType(DetailSection),
      );
      Finder inSummary(String text) =>
          find.descendant(of: summary, matching: find.text(text));
      for (final (label, value) in [
        ('Comenzó', DateFormats.dateTime(DateTime(2026, 11, 3, 10, 15))),
        (
          'Solución registrada',
          DateFormats.dateTime(DateTime(2026, 11, 3, 12)),
        ),
        ('Resuelta', DateFormats.dateTime(DateTime(2026, 11, 3, 12, 30))),
        ('Duración de la atención', '2 h 15 min'),
      ]) {
        expect(inSummary(label), findsOneWidget);
        // Cada fecha aparece una sola vez en toda la pantalla.
        expect(find.text(value), findsOneWidget);
      }
      // Las fechas no se repiten en otras secciones.
      expect(find.text('Inicio de la atención'), findsNothing);
      expect(find.byKey(const Key('detail.finalize')), findsNothing);
    });
  });
}

extension on Incident {
  /// La misma incidencia atendida el [day] de noviembre de 2026: comenzó a
  /// las 10:15 y se resolvió [minutes] después.
  Incident attended(int day, {int minutes = 135}) {
    final started = DateTime(2026, 11, day, 10, 15);
    return Incident(
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
      startedAt: started,
      solution: 'Se cambió el empaque.',
      solutionRegisteredAt: DateTime(2026, 11, day, 12),
      evidenceAfter: const [
        'https://res.cloudinary.com/fixo/image/upload/1.jpg',
        'https://res.cloudinary.com/fixo/video/upload/2.mp4',
      ],
      resolvedAt: started.add(Duration(minutes: minutes)),
    );
  }
}
