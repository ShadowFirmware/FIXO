import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/resident/presentation/providers/incident_history_view_model.dart';
import 'package:fixo/features/resident/presentation/screens/incident_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../incidents/fakes.dart';

/// HU-2.5 Consultar historial de incidencias: pantalla.
void main() {
  final leak = Incident(
    id: 'inc-7',
    folio: 7,
    title: 'Fuga en baño',
    type: IncidentType.water,
    description: 'Gotea la llave del lavabo',
    housingId: 'vivienda-4b',
    createdBy: 'uid-residente',
    status: IncidentStatus.pending,
    createdAt: DateTime(2026, 10, 20, 9, 30),
  );

  late FakeIncidentRepository incidents;
  late IncidentHistoryViewModel viewModel;
  late List<RouteSettings> pushed;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncidentHistoryScreen(viewModel: viewModel),
        onGenerateRoute: (settings) {
          pushed.add(settings);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Text('Detalle ${settings.arguments}'),
          );
        },
      ),
    );
    incidents.housingChanges.add([leak]);
    await tester.pumpAndSettle();
  }

  setUp(() {
    incidents = FakeIncidentRepository();
    viewModel = IncidentHistoryViewModel(
      session: AuthSession.withRepository(FakeAuthRepository())
        ..start(TestUsers.resident()),
      incidents: incidents,
      housings: FakeHousingRepository(),
    );
    pushed = [];
  });

  tearDown(() => viewModel.dispose());

  testWidgets('PU-100 cada incidencia muestra número, nombre, tipo, fecha y '
      'estado', (tester) async {
    await pumpScreen(tester);

    expect(find.text('INC-0007'), findsOneWidget);
    expect(find.text('Fuga en baño'), findsOneWidget);
    expect(find.text('Agua · 20 de octubre de 2026'), findsOneWidget);
    // Una vez en la tarjeta y otra en el filtro por estado.
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('PU-101 al tocar una incidencia se abre su detalle', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Fuga en baño'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, RouteNames.incidentDetail);
    expect(pushed.single.arguments, 'inc-7');
    expect(find.text('Detalle inc-7'), findsOneWidget);
  });

  testWidgets('PU-102 sin resultados muestra el aviso y permite limpiar los '
      'filtros', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('history.search')), 'gas');
    await tester.pumpAndSettle();
    expect(
      find.text(IncidentHistoryViewModel.noResultsMessage),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('history.clearFilters')));
    await tester.pumpAndSettle();
    expect(find.text('Fuga en baño'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('history.search')))
          .controller!
          .text,
      isEmpty,
    );
  });
}
