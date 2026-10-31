import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/admin_profile_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_profile_screen.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../housing/fakes.dart';

/// HU-4.1 Consultar perfil del administrador: interfaz.
void main() {
  late AuthSession session;
  late FakeHousingRepository housings;
  late AdminProfileViewModel viewModel;

  AppUser adminWith({
    String name = 'Carlos Admin Pérez',
    String email = 'admin@correo.com',
    String phone = '5551234567',
    String? housingId,
    AccountStatus status = AccountStatus.active,
    DateTime? createdAt,
  }) => AppUser(
    uid: 'uid-admin',
    name: name,
    email: email,
    phone: phone,
    role: UserRole.admin,
    accountStatus: status,
    housingId: housingId,
    createdAt: createdAt,
  );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    housings = FakeHousingRepository();
    viewModel = AdminProfileViewModel(session: session, housings: housings);
  });

  tearDown(() => viewModel.dispose());

  Widget buildApp() => MaterialApp(
    theme: AppTheme.light,
    home: AdminProfileScreen(viewModel: viewModel),
    routes: {
      RouteNames.adminEditProfile: (_) =>
          const Scaffold(body: Text('Pantalla de edición')),
    },
  );

  testWidgets('PU-411 muestra los datos del administrador autenticado', (
    tester,
  ) async {
    session.start(adminWith(createdAt: DateTime(2026, 10, 27)));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Carlos Admin Pérez'), findsNWidgets(2));
    expect(find.text('admin@correo.com'), findsNWidgets(2));
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('27 de octubre de 2026'), findsOneWidget);
  });

  testWidgets(
    'PU-412 solo muestra la información del administrador en sesión',
    (tester) async {
      session.start(adminWith());
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Carlos Admin Pérez'), findsNWidgets(2));
      expect(find.text('Luis Admin Ruiz'), findsNothing);

      session.start(
        adminWith(name: 'Luis Admin Ruiz', email: 'luis@correo.com'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carlos Admin Pérez'), findsNothing);
      expect(find.text('Luis Admin Ruiz'), findsNWidgets(2));
      expect(find.text('luis@correo.com'), findsNWidgets(2));
    },
  );

  testWidgets('PU-413 muestra la vivienda cuando el perfil la tiene asignada', (
    tester,
  ) async {
    session.start(adminWith(housingId: 'vivienda-4b'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('VIVIENDA'), findsOneWidget);
    expect(find.text('Vivienda asignada'), findsOneWidget);
    expect(find.text('Torre A – 4B'), findsOneWidget);
  });

  testWidgets('PU-414 no muestra la sección de vivienda si no hay asignada', (
    tester,
  ) async {
    session.start(adminWith());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('VIVIENDA'), findsNothing);
    expect(find.text('Vivienda asignada'), findsNothing);
  });

  testWidgets('PU-415 el botón "Modificar perfil" navega a la edición', (
    tester,
  ) async {
    session.start(adminWith());
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('adminProfile.edit'));
    expect(button, findsOneWidget);
    expect(find.text('Modificar perfil'), findsOneWidget);

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de edición'), findsOneWidget);
  });
}
