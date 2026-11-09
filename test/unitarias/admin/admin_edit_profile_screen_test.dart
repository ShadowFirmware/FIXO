import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/screens/admin_edit_profile_screen.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/resident/presentation/providers/edit_profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';
import '../resident/fakes.dart';

/// HU-4.2 Modificar perfil del administrador: pantalla.
void main() {
  const admin = AppUser(
    uid: 'uid-admin',
    name: 'Carlos Admin Pérez',
    email: 'admin@correo.com',
    phone: '5551234567',
    role: UserRole.admin,
    accountStatus: AccountStatus.active,
  );

  late AuthSession session;
  late FakeProfileRepository profiles;

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository())..start(admin);
    profiles = FakeProfileRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final viewModel = EditProfileViewModel(
      session: session,
      housings: FakeHousingRepository(),
      profiles: profiles,
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
                  builder: (_) => AdminEditProfileScreen(viewModel: viewModel),
                ),
              ),
              child: const Text('Perfil'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(ElevatedButton, 'Guardar cambios');

  Future<void> saveAndConfirm(WidgetTester tester) async {
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('PU-582 carga los datos del administrador y no guarda sin '
      'cambios', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Carlos Admin Pérez'), findsOneWidget);
    expect(find.text('admin@correo.com'), findsOneWidget);
    expect(find.text('5551234567'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);
  });

  testWidgets('PU-583 con datos inválidos marca cada campo, avisa y no '
      'guarda', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('editProfile.name')),
      'Carlos 123',
    );
    await tester.enterText(find.byKey(const Key('editProfile.phone')), '555');
    await tester.pumpAndSettle();
    await saveAndConfirm(tester);

    expect(find.text('El nombre solo puede tener letras'), findsOneWidget);
    expect(find.text('El teléfono debe tener 10 dígitos'), findsOneWidget);
    expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
    expect(profiles.saved, isEmpty);
    expect(find.byType(AdminEditProfileScreen), findsOneWidget);
  });

  testWidgets('PU-584 con datos válidos guarda, avisa y regresa al '
      'perfil', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('editProfile.phone')),
      '5559876543',
    );
    await tester.pumpAndSettle();
    await saveAndConfirm(tester);

    expect(profiles.saved.single.phone, '5559876543');
    expect(session.currentUser?.phone, '5559876543');
    expect(find.text('Tu perfil se actualizó correctamente'), findsOneWidget);
    expect(find.byType(AdminEditProfileScreen), findsNothing);
  });
}
