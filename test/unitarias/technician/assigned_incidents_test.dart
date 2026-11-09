import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incidents_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_home_screen.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.3 Consultar incidencias asignadas: ViewModel, lista y detalle.
void main() {
  final arrival = DateTime(2026, 11, 9, 10, 30);
  final items = [
    assignedItem(assignedIncident(1, estimatedTime: arrival)),
    assignedItem(
      assignedIncident(
        2,
        status: IncidentStatus.inProgress,
        type: IncidentType.electricity,
      ),
      housingLabel: 'Torre B – 1A',
      residentName: 'Luis Gómez',
    ),
    assignedItem(assignedIncident(3)),
  ];

  late AuthSession session;
  late FakeAssignedIncidentRepository repository;
  late AssignedIncidentsViewModel viewModel;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.technician);
    repository = FakeAssignedIncidentRepository();
    viewModel = AssignedIncidentsViewModel(
      session: session,
      repository: repository,
    );
  });

  tearDown(() => viewModel.dispose());

  group('ViewModel', () {
    test('PU-521 carga las incidencias y las filtra por estado', () async {
      expect(viewModel.state, AssignedIncidentsState.loading);
      expect(repository.requestedTechnicians, [technicianId]);

      repository.listController.add(items);
      await pumpEventQueue();
      expect(viewModel.state, AssignedIncidentsState.loaded);
      expect(viewModel.countOf(null), 3);
      expect(viewModel.countOf(IncidentStatus.assigned), 2);
      expect(viewModel.countOf(IncidentStatus.inProgress), 1);
      expect(viewModel.emptyMessage, isNull);

      viewModel.setStatusFilter(IncidentStatus.inProgress);
      expect(viewModel.results.map((i) => i.incident.folio), [2]);
      viewModel.setStatusFilter(null);
      expect(viewModel.results, hasLength(3));
    });

    test('PU-522 la resuelta deja la lista y avisa cuando ya no hay '
        'incidencias', () async {
      repository.listController.add([
        assignedItem(assignedIncident(1, status: IncidentStatus.inProgress)),
      ]);
      await pumpEventQueue();
      viewModel.setStatusFilter(IncidentStatus.assigned);
      expect(
        viewModel.emptyMessage,
        'No tienes incidencias en estado "Asignada".',
      );

      // El técnico resuelve la incidencia.
      repository.listController.add([
        assignedItem(assignedIncident(1, status: IncidentStatus.resolved)),
      ]);
      await pumpEventQueue();
      expect(viewModel.incidents, isEmpty);
      expect(
        viewModel.emptyMessage,
        AssignedIncidentsViewModel.noIncidentsMessage,
      );
    });

    test('PU-523 informa si no se pudieron cargar', () async {
      repository.listController.addError(IncidentFailure.offline);
      await pumpEventQueue();
      expect(viewModel.state, AssignedIncidentsState.error);
      expect(viewModel.errorMessage, IncidentFailure.offline.message);
      expect(viewModel.emptyMessage, isNull);
    });
  });

  group('pantallas', () {
    late List<Object?> opened;

    Future<void> pumpHome(WidgetTester tester) async {
      opened = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianHomeScreen(viewModel: viewModel),
          onGenerateRoute: (settings) {
            opened.add(settings.arguments);
            expect(settings.name, RouteNames.technicianIncidentDetail);
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Detalle')),
            );
          },
        ),
      );
    }

    testWidgets('PU-524 muestra la información de cada incidencia y el '
        'filtro por estado', (tester) async {
      await pumpHome(tester);
      repository.listController.add(items);
      await tester.pumpAndSettle();

      expect(find.text('Incidencias asignadas'), findsOneWidget);
      expect(find.text('INC-0001'), findsOneWidget);
      expect(find.text('Fuga 1'), findsOneWidget);
      expect(find.text('Agua · Torre A – 4B'), findsNWidgets(2));
      expect(find.text('Luz · Torre B – 1A'), findsOneWidget);
      expect(find.text('Reportó: Luis Gómez'), findsOneWidget);
      expect(
        find.text('Llegada estimada: ${DateFormats.dateTime(arrival)}'),
        findsOneWidget,
      );
      expect(find.text('Todas (3)'), findsOneWidget);
      expect(find.text('Asignada (2)'), findsOneWidget);
      expect(find.text('En proceso (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('assigned.status.en_proceso')));
      await tester.pumpAndSettle();
      expect(find.text('Fuga 2'), findsOneWidget);
      expect(find.text('Fuga 1'), findsNothing);
      expect(find.text('Fuga 3'), findsNothing);
    });

    testWidgets('PU-525 abre el detalle de la incidencia', (tester) async {
      await pumpHome(tester);
      repository.listController.add(items);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fuga 2'));
      await tester.pumpAndSettle();
      expect(opened, ['inc-2']);
      expect(find.text('Detalle'), findsOneWidget);
    });

    testWidgets('PU-526 muestra un mensaje si no hay incidencias '
        'asignadas', (tester) async {
      await pumpHome(tester);
      repository.listController.add(const []);
      await tester.pumpAndSettle();
      expect(
        find.text(AssignedIncidentsViewModel.noIncidentsMessage),
        findsOneWidget,
      );
      expect(find.byKey(const Key('assigned.status.all')), findsNothing);

      repository.listController.add([items[1]]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assigned.status.asignada')));
      await tester.pumpAndSettle();
      expect(
        find.text('No tienes incidencias en estado "Asignada".'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('assigned.showAll')));
      await tester.pumpAndSettle();
      expect(find.text('Fuga 2'), findsOneWidget);
    });

    testWidgets('PU-527 el detalle muestra la información general y no '
        'se abre si la incidencia es de otro técnico', (tester) async {
      Future<AssignedIncidentDetailViewModel> pumpDetail() async {
        final detail = AssignedIncidentDetailViewModel(
          incidentId: 'inc-1',
          session: session,
          repository: repository,
        );
        addTearDown(detail.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            // Una clave nueva para que la pantalla use el nuevo ViewModel.
            home: TechnicianIncidentDetailScreen(
              key: UniqueKey(),
              incidentId: 'inc-1',
              viewModel: detail,
            ),
          ),
        );
        return detail;
      }

      await pumpDetail();
      repository.detailController.add(items.first);
      await tester.pumpAndSettle();

      expect(find.text('INC-0001'), findsOneWidget);
      expect(find.text('Fuga 1'), findsOneWidget);
      expect(find.text('Agua'), findsOneWidget);
      expect(find.text('Torre A – 4B'), findsOneWidget);
      expect(find.text(DateFormats.dateTime(arrival)), findsOneWidget);
      expect(find.text('Gotea la tubería del baño.'), findsOneWidget);
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('7771112233'), findsOneWidget);

      await pumpDetail();
      repository.detailController.add(
        assignedItem(assignedIncident(1, technician: 'otro-tecnico')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(IncidentFailure.notAssignedToYou.message),
        findsOneWidget,
      );
      expect(find.text('Fuga 1'), findsNothing);
    });
  });
}
