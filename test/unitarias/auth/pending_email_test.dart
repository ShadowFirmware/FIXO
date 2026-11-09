import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixo/app/routes/app_router.dart';
import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/features/admin/data/models/email_change_plan.dart';
import 'package:fixo/features/admin/presentation/providers/admin_users_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/resident_admin_view_model.dart';
import 'package:fixo/features/admin/presentation/providers/technician_admin_view_model.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/resident/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin/admin_users_fakes.dart';
import 'fakes.dart';

/// Cambio de correo hecho por el administrador (HU-4.5) y acceso del
/// residente a modificar su perfil (HU-2.2).
void main() {
  /// Residente cuyo correo cambió el administrador a `nuevo@correo.com`.
  UserModel residentWithPending({bool linkSent = false}) => UserModel(
    uid: 'uid-residente',
    name: 'María López Hernández',
    email: 'maria@correo.com',
    phone: '7771112233',
    role: UserRole.resident,
    accountStatus: AccountStatus.active,
    housingId: 'vivienda-4b',
    pendingEmail: 'nuevo@correo.com',
    pendingEmailLinkSent: linkSent,
  );

  test('PU-597 el correo que cambia el administrador queda pendiente', () {
    final changed = EmailChangePlan.update(
      currentEmail: 'maria@correo.com',
      newEmail: ' Nuevo@Correo.com ',
    );
    expect(changed, {
      'correoPendiente': 'nuevo@correo.com',
      'enlaceCorreoEnviado': false,
    });
    // El correo de acceso no se toca.
    expect(changed.containsKey('correo'), isFalse);

    final same = EmailChangePlan.update(
      currentEmail: 'maria@correo.com',
      newEmail: 'MARIA@correo.com',
    );
    expect(same['correoPendiente'], isA<FieldValue>());
    expect(same['enlaceCorreoEnviado'], isA<FieldValue>());
  });

  group('al iniciar sesión', () {
    FakeAuthRemoteDataSource remote(UserModel user) => FakeAuthRemoteDataSource(
      passwords: {'maria@correo.com': 'Password123'},
      profiles: {user.uid: user},
      currentEmail: 'maria@correo.com',
    );

    test('PU-598 con el correo anterior se envía el enlace al correo nuevo '
        'una sola vez', () async {
      final firstLogin = remote(residentWithPending());
      final user = await AuthRepositoryImpl(remote: firstLogin)
          .signIn(email: 'maria@correo.com', password: 'Password123');

      expect(firstLogin.sentLinks, {'uid-residente': 'nuevo@correo.com'});
      expect((user as UserModel).pendingEmailLinkSent, isTrue);
      // Sigue con su correo actual hasta que abra el enlace.
      expect(user.email, 'maria@correo.com');
      expect(firstLogin.confirmedEmails, isEmpty);

      final nextLogin = remote(residentWithPending(linkSent: true));
      await AuthRepositoryImpl(remote: nextLogin)
          .signIn(email: 'maria@correo.com', password: 'Password123');
      expect(nextLogin.sentLinks, isEmpty);
    });

    test('PU-599 si no se puede enviar el enlace, el usuario entra igual y '
        'se reintenta después', () async {
      final failing = remote(residentWithPending())
        ..sendLinkError = Exception('Sin conexión');
      final user = await AuthRepositoryImpl(remote: failing)
          .signIn(email: 'maria@correo.com', password: 'Password123');

      expect(user.uid, 'uid-residente');
      expect((user as UserModel).pendingEmailLinkSent, isFalse);
    });
  });

  test('PU-600 al cambiar el correo el administrador ve que queda '
      'pendiente', () async {
    final residents = FakeResidentAdminRepository(
      residents: [residentUser('res-ana', 'Ana López')],
    );
    final vm = AdminUsersViewModel(
      residents: ResidentAdminViewModel(repository: residents),
      technicians: TechnicianAdminViewModel(
        repository: FakeTechnicianAdminRepository(),
      ),
    );
    addTearDown(vm.dispose);
    await vm.load();
    final ana = vm.users.single;

    await vm.update(
      ana,
      name: ana.name,
      email: 'ana.nueva@correo.com',
      phone: ana.phone,
      housingId: 'viv-4b',
    );
    expect(residents.updated.single['email'], 'ana.nueva@correo.com');
    expect(vm.message, contains('El correo cambiará a ana.nueva@correo.com'));
    expect(vm.message, contains('sigue entrando con su correo actual'));

    await vm.update(
      ana,
      name: 'Ana María López',
      email: ana.email,
      phone: ana.phone,
      housingId: 'viv-4b',
    );
    expect(vm.message, 'Residente actualizado correctamente.');
  });

  testWidgets('PU-601 el residente puede abrir Modificar perfil', (
    tester,
  ) async {
    // La sesión global solo vive en este archivo de pruebas.
    AuthSession.instance.start(TestUsers.resident());

    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: RouteNames.editProfile),
    );
    await tester.pumpWidget(MaterialApp(onGenerateRoute: (_) => route));
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('No disponible para este rol'), findsNothing);
  });
}
