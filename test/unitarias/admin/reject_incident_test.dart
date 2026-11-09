import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/data/datasources/incident_admin_remote_data_source.dart';
import 'package:fixo/features/admin/data/models/assignment_plan.dart';
import 'package:fixo/features/admin/data/repositories/incident_admin_repository_impl.dart';
import 'package:fixo/features/admin/domain/entities/rejection_rules.dart';
import 'package:fixo/features/admin/presentation/providers/pending_incidents_view_model.dart';
import 'package:fixo/features/admin/presentation/widgets/pending_incident_widgets.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pending_incidents_fakes.dart';

/// HU-4.10 Rechazar reporte: validaciones, formulario y confirmación.
void main() {
  final pending = withNames(
    pendingIncident(1, createdAt: DateTime(2026, 11, 1, 9, 30)),
  );

  late FakeIncidentAdminRepository repository;
  late PendingIncidentsViewModel viewModel;

  setUp(() {
    repository = FakeIncidentAdminRepository();
    viewModel = PendingIncidentsViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  /// Pantalla con botones para rechazar y para ver el detalle.
  Future<void> pumpActions(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final actions = PendingIncidentActions(context, viewModel);
              return Column(
                children: [
                  TextButton(
                    onPressed: () => actions.reject(pending),
                    child: const Text('Abrir rechazo'),
                  ),
                  TextButton(
                    onPressed: () => showPendingIncidentDetail(
                      context,
                      pending,
                      actions: actions,
                    ),
                    child: const Text('Abrir detalle'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // El último es el del formulario o la confirmación que está al frente.
  Finder rejectButton() => find.widgetWithText(ElevatedButton, 'Rechazar').last;

  Future<void> writeReason(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('reject.comment')), text);
    await tester.pumpAndSettle();
  }

  test('PU-454 el motivo es obligatorio y de máximo 500 caracteres', () {
    expect(RejectionRules.validate(''), 'Escribe el motivo del rechazo');
    expect(RejectionRules.validate('   \n '), 'Escribe el motivo del rechazo');
    expect(
      RejectionRules.validate('a' * 501),
      'El motivo no debe exceder 500 caracteres',
    );
    expect(RejectionRules.validate('Es del área común'), isNull);
    expect(
      PendingIncidentsViewModel.validateRejection('  '),
      RejectionRules.validate('  '),
    );
  });

  test('PU-455 el repositorio no rechaza sin motivo aunque la llamada no '
      'venga del formulario', () async {
    final remote = FakeIncidentAdminRemoteDataSource();
    final repo = IncidentAdminRepositoryImpl(remote: remote);

    await expectLater(
      repo.reject(incidentId: 'inc-1', comment: '  '),
      throwsA(
        isA<IncidentFailure>().having(
          (f) => f.message,
          'message',
          'Escribe el motivo del rechazo',
        ),
      ),
    );
    expect(remote.lastComment, isNull);
  });

  test('PU-456 una incidencia rechazada no se puede asignar', () async {
    expect(
      () => AssignmentPlan.validate(
        incident: {'estado': 'rechazada'},
        technician: {
          'rol': 'tecnico',
          'estadoCuenta': 'activa',
          'disponible': true,
        },
        now: DateTime(2026, 11, 2),
      ),
      throwsA(isA<IncidentRejectedException>()),
    );

    final remote = FakeIncidentAdminRemoteDataSource()
      ..actionError = const IncidentRejectedException();
    await expectLater(
      IncidentAdminRepositoryImpl(remote: remote).assign(
        incidentId: 'inc-1',
        technicianId: 'tec-1',
        estimatedTime: DateTime(2026, 11, 3),
      ),
      throwsA(IncidentFailure.alreadyRejected),
    );
  });

  test('PU-457 el ViewModel no intenta asignar una incidencia '
      'rechazada', () async {
    final rejected = withNames(
      IncidentModel(
        id: 'inc-9',
        folio: 9,
        title: 'Puerta del elevador',
        type: IncidentType.other,
        description: 'No cierra',
        housingId: 'viv-4b',
        createdBy: 'res-ana',
        status: IncidentStatus.rejected,
      ),
    );

    final ok = await viewModel.assign(
      rejected,
      technicianId: 'tec-1',
      estimatedTime: DateTime.now().add(const Duration(hours: 2)),
    );

    expect(ok, isFalse);
    expect(viewModel.errorMessage, IncidentFailure.alreadyRejected.message);
    expect(repository.assigned, isEmpty);
  });

  testWidgets('PU-458 el formulario muestra la incidencia y no continúa sin '
      'motivo', (tester) async {
    await pumpActions(tester);
    await tester.tap(find.text('Abrir rechazo'));
    await tester.pumpAndSettle();

    expect(find.text('Rechazar INC-0001'), findsOneWidget);
    expect(find.text('Incidencia 1'), findsOneWidget);
    expect(
      find.text('El residente recibirá este motivo en su notificación.'),
      findsOneWidget,
    );

    await tester.tap(rejectButton());
    await tester.pumpAndSettle();
    expect(find.text('Escribe el motivo del rechazo'), findsOneWidget);
    expect(find.text('Confirmar rechazo'), findsNothing);

    // El error desaparece en cuanto se escribe un motivo.
    await writeReason(tester, 'Es del área común');
    expect(find.text('Escribe el motivo del rechazo'), findsNothing);
  });

  testWidgets('PU-459 la confirmación muestra el motivo y al cancelar no se '
      'rechaza', (tester) async {
    await pumpActions(tester);
    await tester.tap(find.text('Abrir rechazo'));
    await tester.pumpAndSettle();
    await writeReason(tester, '  Es del área común  ');
    await tester.tap(rejectButton());
    await tester.pumpAndSettle();

    expect(find.text('Confirmar rechazo'), findsOneWidget);
    expect(find.text('Motivo: Es del área común'), findsOneWidget);
    expect(
      find.text('Pasará a Rechazada y no se podrá asignar a un técnico.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.rejected, isEmpty);
  });

  testWidgets('PU-460 al confirmar se rechaza con el motivo y se avisa', (
    tester,
  ) async {
    await pumpActions(tester);
    await tester.tap(find.text('Abrir rechazo'));
    await tester.pumpAndSettle();
    await writeReason(tester, 'Es del área común');
    await tester.tap(rejectButton());
    await tester.pumpAndSettle();
    await tester.tap(rejectButton());
    await tester.pumpAndSettle();

    expect(repository.rejected, {'inc-1': 'Es del área común'});
    expect(find.text('Incidencia INC-0001 rechazada.'), findsOneWidget);
  });

  testWidgets('PU-461 el detalle de la incidencia ofrece la opción de '
      'rechazar', (tester) async {
    await pumpActions(tester);
    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pendingDetail.reject')));
    await tester.pumpAndSettle();

    expect(find.text('Rechazar INC-0001'), findsOneWidget);
    expect(find.byKey(const Key('reject.comment')), findsOneWidget);
  });
}
