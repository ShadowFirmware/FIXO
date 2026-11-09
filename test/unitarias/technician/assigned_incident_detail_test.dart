import 'dart:async';

import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/core/utils/date_formats.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:fixo/features/technician/domain/entities/assigned_incident.dart';
import 'package:fixo/features/technician/presentation/providers/assigned_incident_detail_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_incident_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import 'assigned_incidents_fakes.dart';

/// HU-3.4 Consultar detalles y evidencias de una incidencia: pantalla de
/// detalle y opción Comenzar atención.
void main() {
  // Lunes 9 de noviembre de 2026, 9:00; el técnico llega a las 10:30.
  final now = DateTime(2026, 11, 9, 9);
  final arrival = DateTime(2026, 11, 9, 10, 30);

  const photo = 'https://res.cloudinary.com/fixo/image/upload/a.jpg';
  const video = 'https://res.cloudinary.com/fixo/video/upload/b.mp4';

  AssignedIncident item({
    IncidentStatus status = IncidentStatus.assigned,
    Housing? housing = towerA4B,
  }) => assignedItem(
    assignedIncident(1, status: status, estimatedTime: arrival),
    housing: housing,
  ).withEvidence(const [photo, photo, video]);

  late AuthSession session;
  late FakeAssignedIncidentRepository repository;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.technician);
    repository = FakeAssignedIncidentRepository();
  });

  Future<AssignedIncidentDetailViewModel> pumpDetail(
    WidgetTester tester, {
    AssignedIncident? initial,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final viewModel = AssignedIncidentDetailViewModel(
      incidentId: 'inc-1',
      initial: initial,
      session: session,
      repository: repository,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TechnicianIncidentDetailScreen(
          incidentId: 'inc-1',
          viewModel: viewModel,
        ),
      ),
    );
    return viewModel;
  }

  testWidgets('PU-532 al abrirla desde la lista se muestra de inmediato y '
      'se actualiza sola', (tester) async {
    final viewModel = await pumpDetail(tester, initial: item());
    expect(viewModel.state, AssignedIncidentDetailState.loaded);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Fuga 1'), findsOneWidget);
    expect(repository.requestedIds, ['inc-1']);

    // Cambia en Firestore.
    repository.detailController.add(item(status: IncidentStatus.inProgress));
    await tester.pumpAndSettle();
    expect(find.text('Estás atendiendo el problema.'), findsOneWidget);
  });

  testWidgets('PU-533 muestra la información general de la incidencia', (
    tester,
  ) async {
    await pumpDetail(tester);
    repository.detailController.add(item());
    await tester.pumpAndSettle();

    expect(find.text('INC-0001'), findsOneWidget);
    expect(find.text('Fuga 1'), findsOneWidget);
    expect(find.text('Agua'), findsOneWidget);
    expect(find.text('Gotea la tubería del baño.'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text(DateFormats.dateTime(DateTime(2026, 11))), findsOneWidget);
    expect(find.text(DateFormats.dateTime(arrival)), findsOneWidget);
    expect(
      find.text('Llegada estimada: ${DateFormats.dateTime(arrival)}'),
      findsOneWidget,
    );
    expect(find.text('Faltan 1 h 30 min'), findsOneWidget);
  });

  testWidgets('PU-534 muestra las evidencias del residente', (tester) async {
    await pumpDetail(tester);
    repository.detailController.add(item());
    await tester.pumpAndSettle();

    expect(find.text('EVIDENCIAS DEL RESIDENTE'), findsOneWidget);
    expect(
      find.text('2 fotos · 1 video · Toca una para verla completa.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('PU-535 muestra la ubicación y los datos del residente', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpDetail(tester);
    repository.detailController.add(item());
    await tester.pumpAndSettle();

    expect(find.text('Torre A – 4B'), findsOneWidget);
    expect(find.text('Departamento'), findsOneWidget);
    expect(find.text('Torre A'), findsOneWidget);
    expect(find.text('4B'), findsOneWidget);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('7771112233'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Copiar'));
    await tester.pump();
    expect(copied, ['7771112233']);
    expect(find.text('Teléfono copiado'), findsOneWidget);

    // Una casa no tiene edificio.
    repository.detailController.add(
      item(
        housing: const Housing(
          id: 'casa-12',
          type: HousingType.house,
          number: '12',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Edificio o torre'), findsNothing);
  });

  testWidgets('PU-536 Comenzar atención pasa la incidencia a En proceso', (
    tester,
  ) async {
    await pumpDetail(tester);
    repository.detailController.add(item());
    await tester.pumpAndSettle();

    // Cancelar no cambia nada.
    await tester.tap(find.byKey(const Key('detail.startAttention')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.started, isEmpty);

    final gate = repository.startGate = Completer<void>();
    await tester.tap(find.byKey(const Key('detail.startAttention')));
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

    // Firestore avisa del nuevo estado y la opción desaparece.
    repository.detailController.add(item(status: IncidentStatus.inProgress));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail.startAttention')), findsNothing);
    expect(find.text('Faltan 1 h 30 min'), findsNothing);
  });

  testWidgets('PU-537 informa si no se pudo comenzar o cargar la '
      'incidencia', (tester) async {
    await pumpDetail(tester);
    repository
      ..startError = IncidentFailure.attentionAlreadyStarted
      ..detailController.add(item());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail.startAttention')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail.startConfirm')));
    await tester.pumpAndSettle();
    expect(
      find.text(IncidentFailure.attentionAlreadyStarted.message),
      findsOneWidget,
    );

    // Sin conexión se puede reintentar.
    repository.detailController.addError(IncidentFailure.offline);
    await tester.pumpAndSettle();
    expect(find.text(IncidentFailure.offline.message), findsOneWidget);
    await tester.tap(find.byKey(const Key('detail.retry')));
    // Mientras carga gira el indicador: no se espera a que termine.
    await tester.pump();
    expect(repository.requestedIds, ['inc-1', 'inc-1']);
    repository.detailController.add(item());
    await tester.pumpAndSettle();
    expect(find.text('Fuga 1'), findsOneWidget);

    // Si es de otro técnico no se puede reintentar.
    repository.detailController.add(
      assignedItem(assignedIncident(1, technician: 'otro-tecnico')),
    );
    await tester.pumpAndSettle();
    expect(find.text(IncidentFailure.notAssignedToYou.message), findsOneWidget);
    expect(find.byKey(const Key('detail.retry')), findsNothing);
  });
}

extension on AssignedIncident {
  /// La misma incidencia con las evidencias del residente [urls].
  AssignedIncident withEvidence(List<String> urls) {
    final i = incident;
    return AssignedIncident(
      incident: Incident(
        id: i.id,
        folio: i.folio,
        title: i.title,
        type: i.type,
        description: i.description,
        housingId: i.housingId,
        createdBy: i.createdBy,
        status: i.status,
        technicianId: i.technicianId,
        estimatedTime: i.estimatedTime,
        createdAt: i.createdAt,
        evidenceBefore: urls,
      ),
      housingLabel: housing?.label ?? housingLabel,
      housing: housing,
      residentName: residentName,
      residentPhone: residentPhone,
      residentEmail: residentEmail,
    );
  }
}
