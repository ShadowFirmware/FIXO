import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/domain/entities/stats_period.dart';
import 'package:fixo/features/admin/presentation/providers/incident_stats_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_statistics_screen.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_history_fakes.dart';
import 'pending_incidents_fakes.dart';

/// HU-4.12 Consultar estadísticas de incidencias por periodo: ViewModel,
/// dashboard y actualización en tiempo real.
void main() {
  // Miércoles 4 de noviembre de 2026, 10:00.
  var now = DateTime(2026, 11, 4, 10);

  final records = [
    historyRecord(
      historyIncident(
        1,
        status: IncidentStatus.resolved,
        technicianId: 'tec-1',
      ),
      technicianName: 'José Pérez',
    ),
    historyRecord(
      historyIncident(
        2,
        type: IncidentType.electricity,
        status: IncidentStatus.assigned,
        technicianId: 'tec-1',
      ),
      technicianName: 'José Pérez',
    ),
    historyRecord(historyIncident(3, type: IncidentType.electricity)),
    historyRecord(historyIncident(4, status: IncidentStatus.rejected)),
  ];

  late FakeIncidentAdminRepository repository;
  late IncidentStatsViewModel viewModel;

  setUp(() {
    now = DateTime(2026, 11, 4, 10);
    repository = FakeIncidentAdminRepository();
    viewModel = IncidentStatsViewModel(
      repository: repository,
      clock: () => now,
    );
  });

  tearDown(() => viewModel.dispose());

  test('PU-485 consulta la semana actual y cambia de periodo', () {
    viewModel.start();
    expect(viewModel.period.kind, StatsPeriodKind.week);
    expect(repository.requestedPeriods.last, (
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 9),
    ));
    // No se avanza más allá de la semana actual.
    expect(viewModel.canGoNext, isFalse);

    viewModel.selectKind(StatsPeriodKind.month);
    expect(repository.requestedPeriods.last, (
      DateTime(2026, 11),
      DateTime(2026, 12),
    ));

    viewModel.previous();
    expect(viewModel.period.label, 'Octubre 2026');
    expect(viewModel.canGoNext, isTrue);
    viewModel.next();
    expect(viewModel.period.label, 'Noviembre 2026');

    final requests = repository.requestedPeriods.length;
    expect(
      viewModel.setCustomRange(DateTime(2026, 10, 9), DateTime(2026, 10, 1)),
      'La fecha final no puede ser anterior a la inicial',
    );
    expect(repository.requestedPeriods, hasLength(requests));

    expect(
      viewModel.setCustomRange(DateTime(2026, 10, 1), DateTime(2026, 10, 9)),
      isNull,
    );
    expect(viewModel.period.kind, StatsPeriodKind.custom);
    expect(repository.requestedPeriods.last, (
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 10),
    ));
  });

  test('PU-486 las estadísticas se recalculan con cada cambio del '
      'sistema', () async {
    viewModel.start();
    expect(viewModel.state, StatsState.loading);

    repository.periodController.add(records.take(2).toList());
    await pumpEventQueue();
    expect(viewModel.state, StatsState.loaded);
    expect(viewModel.stats.total, 2);
    expect(viewModel.updatedAt, DateTime(2026, 11, 4, 10));

    // Llega una incidencia nueva y otra cambia de estado.
    now = DateTime(2026, 11, 4, 10, 5);
    repository.periodController.add(records);
    await pumpEventQueue();
    expect(viewModel.stats.total, 4);
    expect(viewModel.stats.countOf(IncidentStatus.rejected), 1);
    expect(viewModel.updatedAt, DateTime(2026, 11, 4, 10, 5));

    // Al cambiar de periodo se borran los datos del anterior.
    viewModel.previous();
    expect(viewModel.state, StatsState.loading);
    expect(viewModel.stats.isEmpty, isTrue);
    expect(viewModel.updatedAt, isNull);
  });

  test('PU-487 si falla se informa y se puede reintentar', () async {
    viewModel.start();
    repository.periodController.addError(IncidentFailure.offline);
    await pumpEventQueue();
    expect(viewModel.state, StatsState.error);
    expect(viewModel.errorMessage, IncidentFailure.offline.message);

    viewModel.retry();
    expect(viewModel.state, StatsState.loading);
    expect(repository.requestedPeriods, hasLength(2));
    repository.periodController.add(records);
    await pumpEventQueue();
    expect(viewModel.state, StatsState.loaded);
  });

  group('dashboard', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminStatisticsScreen(viewModel: viewModel),
        ),
      );
    }

    testWidgets('PU-488 muestra el resumen y las gráficas por tipo, estado '
        'y técnico', (tester) async {
      await pumpScreen(tester);
      repository.periodController.add(records);
      await tester.pumpAndSettle();

      expect(find.text('2 nov 2026 – 8 nov 2026'), findsOneWidget);
      expect(
        find.text('En tiempo real · Actualizado a las 10:00 a. m.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stats.total')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );

      Finder inSection(String key, String text) =>
          find.descendant(of: find.byKey(Key(key)), matching: find.text(text));
      expect(inSection('stats.byType', 'Agua'), findsOneWidget);
      expect(inSection('stats.byType', '2 · 50 %'), findsNWidgets(2));
      expect(inSection('stats.byType', '0 · 0 %'), findsNWidgets(2));
      expect(inSection('stats.byStatus', 'Resuelta'), findsOneWidget);
      expect(inSection('stats.byStatus', '25 %'), findsNWidgets(4));
      expect(
        inSection('stats.byTechnician', 'José Pérez · 1 resuelta'),
        findsOneWidget,
      );
      expect(inSection('stats.byTechnician', '2 · 100 %'), findsOneWidget);
    });

    testWidgets('PU-489 se elige el periodo desde el dashboard', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('stats.period.month')));
      // Sin datos el indicador de carga sigue girando: no se espera a que
      // termine.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Noviembre 2026'), findsOneWidget);

      final next = tester.widget<IconButton>(
        find.byKey(const Key('stats.next')),
      );
      expect(next.onPressed, isNull);

      await tester.tap(find.byKey(const Key('stats.previous')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(repository.requestedPeriods.last, (
        DateTime(2026, 10),
        DateTime(2026, 11),
      ));
    });

    testWidgets('PU-490 avisa cuando el periodo no tiene incidencias y '
        'permite reintentar tras un error', (tester) async {
      await pumpScreen(tester);
      repository.periodController.add(const []);
      await tester.pumpAndSettle();
      expect(
        find.text(IncidentStatsViewModel.noIncidentsMessage),
        findsNWidgets(3),
      );

      repository.periodController.addError(IncidentFailure.statsLoadFailed);
      await tester.pumpAndSettle();
      expect(
        find.text(IncidentFailure.statsLoadFailed.message),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('stats.retry')));
      repository.periodController.add(records);
      await tester.pumpAndSettle();
      expect(find.text(IncidentFailure.statsLoadFailed.message), findsNothing);
      expect(find.byKey(const Key('stats.byType')), findsOneWidget);
    });
  });
}
