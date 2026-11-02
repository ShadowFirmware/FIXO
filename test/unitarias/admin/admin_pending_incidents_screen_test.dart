import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/pending_incidents_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:fixo/features/admin/presentation/screens/admin_pending_incidents_screen.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pending_incidents_fakes.dart';

/// HU-4.8 Consultar incidencias pendientes de asignación: interfaz.
void main() {
  late FakeIncidentAdminRepository repository;
  late PendingIncidentsViewModel viewModel;

  final items = [
    withNames(
      pendingIncident(
        1,
        createdAt: DateTime(2026, 10, 1, 9, 30),
        evidence: const ['https://res.cloudinary.com/x/image/upload/a.jpg'],
      ),
    ),
    withNames(
      pendingIncident(
        2,
        type: IncidentType.electricity,
        createdAt: DateTime(2026, 10, 2),
      ),
    ),
    withNames(pendingIncident(3, createdAt: DateTime(2026, 10, 3))),
    withNames(
      pendingIncident(
        4,
        type: IncidentType.structure,
        createdAt: DateTime(2026, 10, 4),
      ),
    ),
  ];

  setUp(() {
    repository = FakeIncidentAdminRepository();
    viewModel = PendingIncidentsViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.light,
    home: home,
    routes: {
      RouteNames.adminPendingIncidents: (_) =>
          const Scaffold(body: Text('Pantalla de reportes pendientes')),
    },
  );

  Future<void> emit(WidgetTester tester) async {
    repository.controller.add(items);
    await tester.pumpAndSettle();
  }

  void useDesktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('PU-433 inicio: muestra 3 pendientes y el botón "Ver más"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(AdminHomeScreen(viewModel: viewModel)));
    await emit(tester);

    expect(find.text('Incidencia 1'), findsOneWidget);
    expect(find.text('Incidencia 3'), findsOneWidget);
    expect(find.text('Incidencia 4'), findsNothing);

    await tester.scrollUntilVisible(find.text('Ver más'), 200);
    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de reportes pendientes'), findsOneWidget);
  });

  testWidgets('PU-434 inicio sin pendientes muestra el aviso', (tester) async {
    await tester.pumpWidget(app(AdminHomeScreen(viewModel: viewModel)));
    repository.controller.add(const []);
    await tester.pumpAndSettle();
    expect(find.text('No hay reportes por el momento'), findsOneWidget);
  });

  testWidgets('PU-435 tabla: columnas, datos y opciones', (tester) async {
    useDesktop(tester);
    await tester.pumpWidget(
      app(AdminPendingIncidentsScreen(viewModel: viewModel)),
    );
    await emit(tester);

    for (final column in [
      'No. reporte',
      'Nombre',
      'Tipo',
      'Detalles',
      'Evidencias',
      'Departamento',
      'Reportó',
      'Fecha de creación',
      'Opciones',
    ]) {
      expect(find.text(column), findsOneWidget);
    }
    expect(find.text('INC-0001'), findsOneWidget);
    expect(find.text('Detalles de la incidencia 1'), findsOneWidget);
    expect(find.text('1 (ver)'), findsOneWidget);
    expect(find.text('1 de octubre de 2026, 9:30 a. m.'), findsOneWidget);
    expect(find.text('Torre A – 4B'), findsNWidgets(4));
    expect(find.text('Ana López'), findsNWidgets(4));
    expect(find.text('Asignar'), findsNWidgets(4));
    expect(find.text('Rechazar'), findsNWidgets(4));
  });

  testWidgets('PU-436 filtro por tipo', (tester) async {
    useDesktop(tester);
    await tester.pumpWidget(
      app(AdminPendingIncidentsScreen(viewModel: viewModel)),
    );
    await emit(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Luz'));
    await tester.pumpAndSettle();
    expect(find.text('INC-0002'), findsOneWidget);
    expect(find.text('INC-0001'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Otros'));
    await tester.pumpAndSettle();
    expect(
      find.text('No hay incidencias pendientes de tipo Otros'),
      findsOneWidget,
    );
  });

  testWidgets('PU-437 rechazar exige motivo y confirmación', (tester) async {
    await tester.pumpWidget(
      app(AdminPendingIncidentsScreen(viewModel: viewModel)),
    );
    await emit(tester);

    await tester.tap(find.text('Rechazar').first);
    await tester.pumpAndSettle();
    final dialogButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(ElevatedButton, 'Rechazar'),
    );

    await tester.tap(dialogButton);
    await tester.pumpAndSettle();
    expect(find.text('Escribe el motivo del rechazo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'No procede');
    await tester.tap(dialogButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar rechazo'), findsOneWidget);

    await tester.tap(dialogButton);
    await tester.pumpAndSettle();
    expect(repository.rejected, {'inc-1': 'No procede'});
    expect(find.text('Incidencia INC-0001 rechazada.'), findsOneWidget);
  });

  testWidgets('PU-438 sin técnicos disponibles se muestra el aviso', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(AdminPendingIncidentsScreen(viewModel: viewModel)),
    );
    await emit(tester);

    await tester.tap(find.text('Asignar').first);
    await tester.pumpAndSettle();
    expect(
      find.text('No hay técnicos disponibles en este momento.'),
      findsOneWidget,
    );
  });
}
