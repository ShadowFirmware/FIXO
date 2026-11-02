import 'package:fixo/core/errors/incident_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/pending_incidents_view_model.dart';
import 'package:fixo/features/admin/presentation/widgets/estimated_time_field.dart';
import 'package:fixo/features/admin/presentation/widgets/pending_incident_widgets.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pending_incidents_fakes.dart';

/// HU-4.9 Asignar un técnico y establecer hora estimada: formulario.
void main() {
  const juan = UserModel(
    uid: 'tec-juan',
    name: 'Juan Pérez',
    email: 'juan@correo.com',
    phone: '7774445566',
    role: UserRole.technician,
    accountStatus: AccountStatus.active,
    specialty: 'plomería',
    available: true,
  );
  const luis = UserModel(
    uid: 'tec-luis',
    name: 'Luis Ruiz',
    email: 'luis@correo.com',
    phone: '',
    role: UserRole.technician,
    accountStatus: AccountStatus.active,
    available: true,
  );

  final pending = withNames(
    pendingIncident(1, createdAt: DateTime(2026, 11, 1, 9, 30)),
  );

  late FakeIncidentAdminRepository repository;
  late PendingIncidentsViewModel viewModel;

  setUp(() {
    repository = FakeIncidentAdminRepository()
      ..technicians = const [juan, luis];
    viewModel = PendingIncidentsViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  /// Pantalla con un botón que abre el formulario de asignación.
  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  PendingIncidentActions(context, viewModel).assign(pending),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Finder confirmButton() => find.widgetWithText(ElevatedButton, 'Asignar');

  test('PU-445 la hora estimada no puede ser pasada ni a más de 30 días', () {
    final now = DateTime(2026, 11, 2, 10);
    String? validate(DateTime? time) =>
        PendingIncidentsViewModel.validateEstimatedTime(time, now: now);

    expect(validate(null), 'Selecciona la hora estimada de llegada');
    expect(
      validate(DateTime(2026, 11, 2, 9, 59)),
      'La hora estimada no puede ser en el pasado',
    );
    expect(validate(DateTime(2026, 11, 2, 16)), isNull);
    expect(validate(DateTime(2026, 12, 2, 23, 59)), isNull);
    expect(
      validate(DateTime(2026, 12, 3)),
      'La hora estimada no puede ser después de 30 días',
    );
    expect(
      PendingIncidentsViewModel.validateAssignment(
        technicianId: null,
        estimatedTime: DateTime(2026, 11, 2, 16),
        now: now,
      ),
      'Selecciona un técnico',
    );
  });

  test('PU-446 la hora sugerida es dentro de una hora, al siguiente '
      'cuarto', () {
    expect(
      EstimatedTimeField.suggestedTime(DateTime(2026, 11, 2, 10, 7)),
      DateTime(2026, 11, 2, 11, 15),
    );
    expect(
      EstimatedTimeField.suggestedTime(DateTime(2026, 11, 2, 23, 50)),
      DateTime(2026, 11, 3, 1),
    );
  });

  testWidgets('PU-447 el formulario muestra la incidencia y los técnicos '
      'disponibles, y pide técnico y hora', (tester) async {
    await openForm(tester);

    expect(find.text('Asignar INC-0001'), findsOneWidget);
    expect(find.text('Incidencia 1'), findsOneWidget);
    expect(find.text('Agua · Torre A – 4B'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Plomería · 7774445566'), findsOneWidget);
    expect(find.text('Sin especialidad'), findsOneWidget);

    await tester.tap(confirmButton());
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un técnico'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign.technician.tec-juan')));
    await tester.pumpAndSettle();
    await tester.tap(confirmButton());
    await tester.pumpAndSettle();
    expect(find.text('Selecciona la hora estimada de llegada'), findsOneWidget);
    expect(repository.assigned, isEmpty);
  });

  testWidgets('PU-448 al confirmar se asigna con el técnico y la hora '
      'elegidos', (tester) async {
    await openForm(tester);

    await tester.tap(find.byKey(const Key('assign.technician.tec-luis')));
    await tester.tap(find.byKey(const Key('assign.estimatedTime')));
    await tester.pumpAndSettle();
    // Selectores de fecha y de hora con la hora sugerida.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(repository.assigned, {'inc-1': 'tec-luis'});
    expect(find.text('Incidencia INC-0001 asignada.'), findsOneWidget);
  });

  testWidgets('PU-449 si falla la consulta de técnicos se puede '
      'reintentar', (tester) async {
    repository.techniciansError = IncidentFailure.offline;
    await openForm(tester);

    expect(find.text(IncidentFailure.offline.message), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign.retry')));
    await tester.pumpAndSettle();

    expect(repository.technicianLoads, 2);
    expect(find.text('Juan Pérez'), findsOneWidget);
  });

  testWidgets('PU-450 si el técnico dejó de estar disponible se avisa', (
    tester,
  ) async {
    repository.actionError = IncidentFailure.technicianUnavailable;
    await openForm(tester);

    await tester.tap(find.byKey(const Key('assign.technician.tec-juan')));
    await tester.tap(find.byKey(const Key('assign.estimatedTime')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(
      find.text(IncidentFailure.technicianUnavailable.message),
      findsOneWidget,
    );
  });
}
