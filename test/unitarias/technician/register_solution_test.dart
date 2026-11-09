import 'dart:async';

import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/incidents/domain/entities/evidence_file.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/domain/entities/assigned_incident.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/providers/resolved_incidents_view_model.dart';
import 'package:fixo/features/technician/presentation/providers/solution_form_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/register_solution_screen.dart';
import 'package:fixo/features/technician/presentation/screens/technician_history_screen.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../incidents/fakes.dart' as incidents;
import 'assigned_incidents_fakes.dart';

/// HU-3.6 Registrar la solución y evidencias de una incidencia: formulario,
/// vista previa, guardado y consulta.
void main() {
  const solution = 'Se cambió el empaque de la llave del baño.';
  final resolvedAt = DateTime(2026, 11, 9, 12, 30);

  final inProgress = assignedItem(
    assignedIncident(1, status: IncidentStatus.inProgress),
  );

  late AuthSession session;
  late FakeAssignedIncidentRepository repository;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.technician);
    repository = FakeAssignedIncidentRepository();
  });

  SolutionFormViewModel formViewModel(
    AssignedIncident item, {
    List<EvidenceFile> photos = const [incidents.photo],
  }) {
    final viewModel = SolutionFormViewModel(
      item: item,
      session: session,
      repository: repository,
      picker: incidents.FakeEvidencePicker(
        photos: photos,
        video: incidents.video,
      ),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('ViewModel', () {
    test('PU-551 agrega y quita evidencias con los mismos límites del '
        'residente', () async {
      final heavy = EvidenceFile(
        path: '/fotos/pesada.jpg',
        isVideo: false,
        sizeBytes: SolutionFormViewModel.maxPhotoBytes + 1,
      );
      final vm = formViewModel(
        inProgress,
        photos: [incidents.photo, incidents.photo, incidents.photo, heavy],
      );

      await vm.addPhotos(fromCamera: false);
      expect(vm.evidence, hasLength(3));
      expect(
        vm.evidenceMessage,
        'Las fotos pueden pesar hasta 10 MB y los videos hasta 50 MB.',
      );

      await vm.addVideo(fromCamera: true);
      await vm.addPhotos(fromCamera: true);
      expect(vm.evidence, hasLength(SolutionFormViewModel.maxEvidence));
      expect(vm.evidenceMessage, 'Solo puedes adjuntar hasta 5 evidencias.');
      expect(vm.canAddEvidence, isFalse);

      vm.removeEvidence(vm.evidence.first);
      expect(vm.evidence, hasLength(4));
      expect(vm.evidenceMessage, isNull);
    });

    test('PU-552 solo se registra la solución de una incidencia propia En '
        'proceso', () {
      expect(formViewModel(inProgress).statusError, isNull);
      for (final (status, failure) in [
        (IncidentStatus.assigned, IncidentFailure.attentionNotStarted),
        (IncidentStatus.resolved, IncidentFailure.solutionAlreadyRegistered),
        (IncidentStatus.rejected, IncidentFailure.solutionNotAvailable),
      ]) {
        expect(
          formViewModel(assignedItem(assignedIncident(1, status: status)))
              .statusError,
          failure,
        );
      }
      expect(
        formViewModel(
          assignedItem(
            assignedIncident(
              1,
              status: IncidentStatus.inProgress,
              technician: 'otro-tecnico',
            ),
          ),
        ).statusError,
        IncidentFailure.notAssignedToYou,
      );
    });
  });

  group('formulario', () {
    Future<SolutionFormViewModel> pumpForm(
      WidgetTester tester, {
      AssignedIncident? item,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final vm = formViewModel(item ?? inProgress);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        RegisterSolutionScreen(item: vm.item, viewModel: vm),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      return vm;
    }

    testWidgets('PU-553 valida la descripción y las evidencias antes de la '
        'vista previa', (tester) async {
      final vm = await pumpForm(tester);
      expect(find.text('Registrar solución'), findsOneWidget);
      expect(find.text('INC-0001'), findsOneWidget);

      await tester.tap(find.byKey(const Key('solution.review')));
      await tester.pumpAndSettle();
      expect(find.text('Describe la solución aplicada'), findsOneWidget);
      expect(
        find.text(SolutionFormViewModel.missingEvidenceMessage),
        findsOneWidget,
      );
      expect(find.byKey(const Key('solution.reviewView')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('solution.description')),
        solution,
      );
      await vm.addPhotos(fromCamera: false);
      await tester.pumpAndSettle();
      expect(
        find.text(SolutionFormViewModel.missingEvidenceMessage),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('solution.review')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('solution.reviewView')), findsOneWidget);
      expect(find.text(solution), findsOneWidget);
      expect(find.text('EVIDENCIAS DEL TRABAJO (1)'), findsOneWidget);

      // Al corregir se conserva lo que se escribió.
      await tester.tap(find.byKey(const Key('solution.edit')));
      await tester.pumpAndSettle();
      expect(find.text(solution), findsOneWidget);
      expect(find.byKey(const Key('solution.reviewView')), findsNothing);
    });

    testWidgets('PU-554 guarda la solución y vuelve al detalle', (
      tester,
    ) async {
      final vm = await pumpForm(tester);
      await tester.enterText(
        find.byKey(const Key('solution.description')),
        solution,
      );
      await vm.addPhotos(fromCamera: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('solution.review')));
      await tester.pumpAndSettle();

      // Primero falla y se queda en la vista previa.
      repository.solutionError = IncidentFailure.offline;
      await tester.tap(find.byKey(const Key('solution.save')));
      await tester.pumpAndSettle();
      expect(find.text(IncidentFailure.offline.message), findsOneWidget);
      expect(find.byKey(const Key('solution.reviewView')), findsOneWidget);

      repository
        ..solutionError = null
        ..solutionGate = Completer<void>();
      await tester.tap(find.byKey(const Key('solution.save')));
      await tester.pump();
      expect(find.text('Guardando…'), findsOneWidget);

      repository.solutionGate!.complete();
      await tester.pumpAndSettle();
      expect(repository.solutions.single.incidentId, 'inc-1');
      expect(repository.solutions.single.solution, solution);
      expect(repository.solutions.single.evidence, [incidents.photo]);
      expect(find.text('Registraste la solución de INC-0001.'), findsOneWidget);
      expect(find.byType(RegisterSolutionScreen), findsNothing);
    });

    testWidgets('PU-555 no muestra el formulario si la incidencia no está En '
        'proceso', (tester) async {
      await pumpForm(tester, item: assignedItem(assignedIncident(1)));
      expect(
        find.text(IncidentFailure.attentionNotStarted.message),
        findsOneWidget,
      );
      expect(find.byKey(const Key('solution.description')), findsNothing);
    });
  });

  group('consulta', () {
    final resolved = assignedItem(
      assignedIncident(
        1,
        status: IncidentStatus.resolved,
      ).withSolution(resolvedAt),
    );

    testWidgets('PU-556 el detalle ofrece Registrar solución En proceso y '
        'muestra la solución al resolverse', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final opened = <Object?>[];
      final detail = AssignedIncidentDetailViewModel(
        incidentId: 'inc-1',
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
          onGenerateRoute: (settings) {
            expect(settings.name, RouteNames.technicianRegisterSolution);
            opened.add(settings.arguments);
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Formulario')),
            );
          },
        ),
      );

      repository.detailController.add(inProgress);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail.startAttention')), findsNothing);
      await tester.tap(find.byKey(const Key('detail.registerSolution')));
      await tester.pumpAndSettle();
      expect(opened, [inProgress]);

      Navigator.of(tester.element(find.text('Formulario'))).pop();
      repository.detailController.add(resolved);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail.registerSolution')), findsNothing);
      expect(find.text('Se cambió el empaque.'), findsOneWidget);
      expect(find.text(DateFormats.dateTime(resolvedAt)), findsOneWidget);
      expect(find.text('EVIDENCIAS DEL TRABAJO'), findsOneWidget);
      expect(
        find.text('1 foto · Toca una para verla completa.'),
        findsOneWidget,
      );
    });

    testWidgets('PU-557 el historial del técnico muestra sus incidencias '
        'resueltas', (tester) async {
      final viewModel = ResolvedIncidentsViewModel(
        session: session,
        repository: repository,
      );
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TechnicianHistoryScreen(viewModel: viewModel),
        ),
      );

      repository.listController.add([inProgress]);
      await tester.pumpAndSettle();
      expect(
        find.text(ResolvedIncidentsViewModel.noIncidentsMessage),
        findsOneWidget,
      );

      repository.listController.add([inProgress, resolved]);
      await tester.pumpAndSettle();
      expect(find.text('Fuga 1'), findsOneWidget);
      expect(
        find.text('Resuelta el ${DateFormats.dateTime(resolvedAt)}'),
        findsOneWidget,
      );
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
    solution: 'Se cambió el empaque.',
    evidenceAfter: const ['https://res.cloudinary.com/fixo/image/upload/1.jpg'],
    resolvedAt: date,
  );
}
