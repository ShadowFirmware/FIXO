import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/resident/presentation/providers/edit_profile_view_model.dart';
import 'package:fixo/features/technician/presentation/providers/technician_profile_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../resident/fakes.dart';

/// HU-3.2 Modificar perfil del técnico.
void main() {
  const nameField = Key('editProfile.name');
  const emailField = Key('editProfile.email');
  const phoneField = Key('editProfile.phone');

  late AuthSession session;
  late FakeProfileRepository profiles;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())
      ..start(TestUsers.technician);
    profiles = FakeProfileRepository();
  });

  /// Abre el formulario sobre otra pantalla para poder comprobar el regreso.
  Future<void> openForm(
    WidgetTester tester, {
    FakeProfileRepository? repository,
  }) async {
    final viewModel = EditProfileViewModel(
      session: session,
      housings: FakeHousingRepository(),
      profiles: repository ?? profiles,
    );
    addTearDown(viewModel.dispose);

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
                      TechnicianEditProfileScreen(viewModel: viewModel),
                ),
              ),
              child: const Text('Abrir formulario'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir formulario'));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.ancestor(
    of: find.text('Guardar cambios'),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('PU-501 el formulario se llena con los datos actuales', (
    tester,
  ) async {
    await openForm(tester);

    expect(find.text('Juan Pérez Ramírez'), findsOneWidget);
    expect(find.text('juan@correo.com'), findsOneWidget);
    expect(find.text('7774445566'), findsOneWidget);
  });

  testWidgets('PU-502 la especialidad es de solo lectura', (tester) async {
    await openForm(tester);

    expect(find.text('electricidad'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('PU-503 el formulario no queda debajo de la barra superior', (
    tester,
  ) async {
    await openForm(tester);

    final title = tester.getBottomLeft(find.text('Modificar perfil'));
    final firstSection = tester.getTopLeft(find.text('INFORMACIÓN PERSONAL'));

    expect(firstSection.dy, greaterThan(title.dy));
  });

  testWidgets('PU-504 "Guardar cambios" solo se habilita si hay cambios', (
    tester,
  ) async {
    await openForm(tester);
    bool isEnabled() => tester.widget<ButtonStyleButton>(saveButton()).enabled;

    expect(isEnabled(), isFalse);

    await tester.enterText(find.byKey(phoneField), '7779998877');
    await tester.pump();
    expect(isEnabled(), isTrue);

    await tester.enterText(find.byKey(phoneField), '7774445566');
    await tester.pump();
    expect(isEnabled(), isFalse);
  });

  testWidgets('PU-505 con un correo inválido informa el error y no guarda', (
    tester,
  ) async {
    await openForm(tester);

    await tester.enterText(find.byKey(emailField), 'juan@');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(find.text('Correo no válido'), findsOneWidget);
    expect(profiles.saved, isEmpty);
    expect(session.currentUser!.email, 'juan@correo.com');
  });

  testWidgets('PU-506 con un teléfono inválido informa el error y no guarda', (
    tester,
  ) async {
    await openForm(tester);

    await tester.enterText(find.byKey(phoneField), '777');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(find.text('El teléfono debe tener 10 dígitos'), findsOneWidget);
    expect(profiles.saved, isEmpty);
    expect(session.currentUser!.phone, '7774445566');
  });

  testWidgets('PU-507 al guardar actualiza el perfil y conserva la '
      'especialidad', (tester) async {
    final profile = TechnicianProfileViewModel(session: session);
    addTearDown(profile.dispose);
    await openForm(tester);

    await tester.enterText(find.byKey(nameField), '  Juan   Pérez ');
    await tester.enterText(find.byKey(phoneField), '7779998877');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(profiles.saved.single, (
      uid: 'uid-tecnico',
      name: 'Juan Pérez',
      email: 'juan@correo.com',
      phone: '7779998877',
    ));
    expect(profiles.emailRequests, isEmpty);
    expect(profile.name, 'Juan Pérez');
    expect(profile.phone, '7779998877');
    expect(profile.specialty, 'electricidad');
    expect(find.text('Tu perfil se actualizó correctamente'), findsOneWidget);
    expect(find.byType(TechnicianEditProfileScreen), findsNothing);
  });

  testWidgets('PU-510 al cambiar el correo envía el enlace y conserva el '
      'correo actual hasta confirmarlo', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byKey(emailField), ' Juan.Nuevo@Correo.com ');
    await tester.enterText(find.byKey(phoneField), '7779998877');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(profiles.emailRequests, ['juan.nuevo@correo.com']);
    expect(profiles.saved.single.email, 'juan@correo.com');
    expect(session.currentUser!.email, 'juan@correo.com');
    expect(session.currentUser!.phone, '7779998877');
    expect(
      find.textContaining('Te enviamos un enlace a juan.nuevo@correo.com'),
      findsOneWidget,
    );
    expect(find.byType(TechnicianEditProfileScreen), findsNothing);
  });

  testWidgets('PU-511 si no se puede enviar el enlace no se guarda nada', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      emailError: ProfileFailure.recentLoginRequired,
    );
    await openForm(tester, repository: repository);

    await tester.enterText(find.byKey(emailField), 'juan.nuevo@correo.com');
    await tester.enterText(find.byKey(phoneField), '7779998877');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(
      find.text(ProfileFailure.recentLoginRequired.message),
      findsOneWidget,
    );
    expect(repository.saved, isEmpty);
    expect(session.currentUser!.phone, '7774445566');
    expect(find.byType(TechnicianEditProfileScreen), findsOneWidget);
  });

  testWidgets('PU-508 si falla el guardado informa el motivo y sigue en el '
      'formulario', (tester) async {
    await openForm(
      tester,
      repository: FakeProfileRepository(emailError: ProfileFailure.emailTaken),
    );

    await tester.enterText(find.byKey(emailField), 'maria@correo.com');
    await tester.pump();
    await tapText(tester, 'Guardar cambios');

    expect(find.text(ProfileFailure.emailTaken.message), findsOneWidget);
    expect(find.byType(TechnicianEditProfileScreen), findsOneWidget);
    expect(session.currentUser!.email, 'juan@correo.com');
  });

  testWidgets('PU-509 "Cancelar" regresa sin guardar', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byKey(phoneField), '7779998877');
    await tester.pump();
    await tapText(tester, 'Cancelar');

    expect(find.byType(TechnicianEditProfileScreen), findsNothing);
    expect(profiles.saved, isEmpty);
    expect(session.currentUser!.phone, '7774445566');
  });
}
