import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/technician/presentation/providers/technician_profile_view_model.dart';
import 'package:fixo/features/technician/presentation/screens/technician_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';

/// HU-3.1 Consultar perfil del técnico: interfaz.
void main() {
  late AuthSession session;
  late TechnicianProfileViewModel viewModel;

  const technician = AppUser(
    uid: 'uid-tecnico',
    name: 'Jorge Ramírez Soto',
    email: 'jorge@correo.com',
    phone: '7774445566',
    role: UserRole.technician,
    accountStatus: AccountStatus.active,
    specialty: 'Luz',
  );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    viewModel = TechnicianProfileViewModel(session: session);
  });

  tearDown(() => viewModel.dispose());

  Widget buildApp() => MaterialApp(
    theme: AppTheme.light,
    home: TechnicianProfileScreen(viewModel: viewModel),
    routes: {
      RouteNames.technicianEditProfile: (_) =>
          const Scaffold(body: Text('Pantalla de edición')),
    },
  );

  testWidgets('PU-498 muestra el perfil del técnico autenticado', (
    tester,
  ) async {
    session.start(technician);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Jorge Ramírez Soto'), findsNWidgets(2));
    expect(find.text('jorge@correo.com'), findsNWidgets(2));
    expect(find.text('7774445566'), findsOneWidget);
    expect(find.text('Técnico'), findsOneWidget);
    expect(find.text('Luz'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
  });

  testWidgets('PU-499 la especialidad se muestra como solo lectura', (
    tester,
  ) async {
    session.start(technician);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('PU-500 "Modificar perfil" abre la pantalla de edición', (
    tester,
  ) async {
    session.start(technician);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final button = find.text('Modificar perfil');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de edición'), findsOneWidget);
  });
}
