import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/admin_incident_history_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_incident_history_screen.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_history_fakes.dart';
import 'pending_incidents_fakes.dart';

/// HU-4.11 Consultar historial de incidencias: ViewModel e interfaz.
void main() {
  final records = [
    historyRecord(
      historyIncident(
        3,
        status: IncidentStatus.rejected,
        type: IncidentType.structure,
        housingId: 'viv-1a',
        rejectionComment: 'Es del área común',
        createdAt: DateTime(2026, 10, 20),
      ),
      housingLabel: 'Torre B – 1A',
    ),
    historyRecord(
      historyIncident(
        2,
        status: IncidentStatus.resolved,
        technicianId: 'tec-2',
        solution: 'Se cambió la llave de paso',
        createdAt: DateTime(2026, 10, 10),
        resolvedAt: DateTime(2026, 10, 11, 12),
        before: const ['https://res.cloudinary.com/x/image/upload/a.jpg'],
        after: const ['https://res.cloudinary.com/x/image/upload/b.jpg'],
      ),
      technicianName: 'Luis Ramos',
    ),
    historyRecord(
      historyIncident(
        1,
        status: IncidentStatus.assigned,
        technicianId: 'tec-1',
        createdAt: DateTime(2026, 10, 1),
      ),
      technicianName: 'José Pérez',
    ),
  ];

  late FakeIncidentAdminRepository repository;
  late FakeHistoryPdfExporter exporter;
  late AdminIncidentHistoryViewModel viewModel;

  setUp(() {
    repository = FakeIncidentAdminRepository();
    exporter = FakeHistoryPdfExporter();
    viewModel = AdminIncidentHistoryViewModel(
      repository: repository,
      exporter: exporter,
      clock: () => DateTime(2026, 11, 2, 16, 5),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> load() async {
    viewModel.start();
    repository.historyController.add(records);
    await pumpEventQueue();
  }

  List<int> folios() => viewModel.results.map((r) => r.incident.folio).toList();

  test('PU-469 carga el historial, cuenta por estado e informa los '
      'errores', () async {
    expect(viewModel.state, AdminHistoryState.loading);
    await load();

    expect(viewModel.state, AdminHistoryState.loaded);
    expect(folios(), [3, 2, 1]);
    expect(viewModel.statusCounts, {
      IncidentStatus.pending: 0,
      IncidentStatus.assigned: 1,
      IncidentStatus.inProgress: 0,
      IncidentStatus.resolved: 1,
      IncidentStatus.rejected: 1,
    });
    expect(viewModel.emptyMessage, isNull);

    repository.historyController.add(const []);
    await pumpEventQueue();
    expect(
      viewModel.emptyMessage,
      AdminIncidentHistoryViewModel.noIncidentsMessage,
    );

    repository.historyController.addError(
      IncidentFailure.adminHistoryAccessDenied,
    );
    await pumpEventQueue();
    expect(viewModel.state, AdminHistoryState.error);
    expect(
      viewModel.errorMessage,
      IncidentFailure.adminHistoryAccessDenied.message,
    );
  });

  test('PU-470 ofrece los técnicos y departamentos con incidencias y aplica '
      'los filtros', () async {
    await load();

    expect(viewModel.technicianOptions, [
      ('tec-1', 'José Pérez'),
      ('tec-2', 'Luis Ramos'),
    ]);
    expect(viewModel.housingOptions, [
      ('viv-4b', 'Torre A – 4B'),
      ('viv-1a', 'Torre B – 1A'),
    ]);

    viewModel.setTechnician('tec-2');
    expect(folios(), [2]);
    viewModel.setHousing('viv-1a');
    expect(folios(), isEmpty);
    expect(
      viewModel.emptyMessage,
      AdminIncidentHistoryViewModel.noResultsMessage,
    );

    viewModel.clearFilters();
    viewModel.setType(IncidentType.structure);
    expect(folios(), [3]);
    viewModel.setStatus(IncidentStatus.resolved);
    expect(folios(), isEmpty);
    viewModel.setType(null);
    expect(folios(), [2]);

    viewModel.clearFilters();
    expect(
      viewModel.setDateRange(
        from: DateTime(2026, 10, 5),
        to: DateTime(2026, 10, 1),
      ),
      isNotNull,
    );
    expect(viewModel.filter.hasDateRange, isFalse);
    expect(
      viewModel.setDateRange(
        from: DateTime(2026, 10, 5),
        to: DateTime(2026, 10, 20),
      ),
      isNull,
    );
    expect(folios(), [3, 2]);
  });

  test('PU-471 exporta a PDF lo que se muestra, con los filtros', () async {
    await load();
    viewModel.setTechnician('tec-1');

    expect(await viewModel.exportPdf(), isNull);
    expect(exporter.records!.map((r) => r.incident.folio), [1]);
    expect(exporter.filterLines, ['Técnico: José Pérez']);
    expect(exporter.generatedAt, DateTime(2026, 11, 2, 16, 5));
    expect(exporter.sharedFileName, 'historial-incidencias-2026-11-02.pdf');
    expect(viewModel.isExporting, isFalse);

    viewModel.setStatus(IncidentStatus.pending);
    expect(
      await viewModel.exportPdf(),
      AdminIncidentHistoryViewModel.exportEmptyMessage,
    );

    viewModel.clearFilters();
    exporter.error = Exception('sin memoria');
    expect(
      await viewModel.exportPdf(),
      AdminIncidentHistoryViewModel.exportFailedMessage,
    );
    expect(viewModel.isExporting, isFalse);
  });

  group('pantalla', () {
    Future<void> pumpScreen(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminIncidentHistoryScreen(viewModel: viewModel),
        ),
      );
      repository.historyController.add(records);
      await tester.pumpAndSettle();
    }

    Future<void> tapStatus(WidgetTester tester, String status) async {
      final chip = find.byKey(Key('history.status.$status'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    testWidgets('PU-472 en el teléfono muestra tarjetas con los datos y '
        'filtra por estado y técnico', (tester) async {
      await pumpScreen(tester, const Size(800, 1600));

      expect(find.text('Todas (3)'), findsOneWidget);
      expect(find.text('Resuelta (1)'), findsOneWidget);
      expect(find.text('3 incidencias'), findsOneWidget);
      expect(find.text('José Pérez'), findsOneWidget);
      expect(find.text('Sin asignar'), findsOneWidget);
      expect(find.text('Antes: 1 · Después: 1'), findsOneWidget);
      expect(
        find.text('Resuelta: 11 de octubre de 2026, 12:00 p. m.'),
        findsOneWidget,
      );

      await tapStatus(tester, 'resuelta');
      await tester.pumpAndSettle();
      expect(find.text('1 de 3 incidencias'), findsOneWidget);
      expect(find.text('Incidencia 2'), findsOneWidget);
      expect(find.text('Incidencia 1'), findsNothing);

      await tester.tap(find.byKey(const Key('history.clearFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history.technician')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('José Pérez').last);
      await tester.pumpAndSettle();
      expect(viewModel.filter.technicianId, 'tec-1');
      expect(find.text('Incidencia 1'), findsOneWidget);
      expect(find.text('Incidencia 2'), findsNothing);
    });

    testWidgets('PU-473 en pantallas anchas muestra la tabla con todas las '
        'columnas', (tester) async {
      await pumpScreen(tester, const Size(1600, 1000));

      for (final header in [
        'No. reporte',
        'Estado',
        'Detalles',
        'Evidencias',
        'Departamento',
        'Reportó',
        'Técnico',
        'Fecha de creación',
        'Fecha de resolución',
      ]) {
        expect(
          find.descendant(
            of: find.byType(DataTable),
            matching: find.text(header),
          ),
          findsOneWidget,
          reason: header,
        );
      }
      expect(find.text('INC-0003'), findsOneWidget);
      expect(find.text('Torre B – 1A'), findsWidgets);
    });

    testWidgets('PU-474 el detalle muestra el rechazo y las evidencias del '
        'residente y del técnico', (tester) async {
      await pumpScreen(tester, const Size(800, 1600));

      await tester.tap(find.text('Incidencia 3'));
      await tester.pumpAndSettle();
      expect(find.text('Motivo del rechazo'), findsOneWidget);
      expect(find.text('Es del área común'), findsOneWidget);
      expect(find.text('El residente no adjuntó evidencias.'), findsOneWidget);
      expect(
        find.text('La incidencia fue rechazada; no hay solución.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('historyDetail.close')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Incidencia 2'));
      await tester.pumpAndSettle();
      expect(find.text('Se cambió la llave de paso'), findsOneWidget);
      expect(find.text('Técnico asignado'), findsOneWidget);
      expect(find.text('Evidencias del residente (antes) · 1'), findsOneWidget);
      expect(find.text('Evidencias del técnico (después) · 1'), findsOneWidget);
    });

    testWidgets('PU-475 el botón exporta lo filtrado y avisa si no hay '
        'nada que exportar', (tester) async {
      await pumpScreen(tester, const Size(800, 1600));

      await tapStatus(tester, 'rechazada');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history.exportPdf')));
      await tester.pumpAndSettle();
      expect(exporter.records!.map((r) => r.incident.folio), [3]);
      expect(exporter.filterLines, ['Estado: Rechazada']);

      await tapStatus(tester, 'pendiente');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history.exportPdf')));
      await tester.pumpAndSettle();
      expect(
        find.text(AdminIncidentHistoryViewModel.exportEmptyMessage),
        findsOneWidget,
      );
    });
  });
}
