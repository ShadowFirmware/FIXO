import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/presentation/providers/auth_session.dart';
import 'package:fixo/features/admin/presentation/providers/admin_edit_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';
import '../resident/fakes.dart';

/// HU-4.2 Modificar perfil del administrador.
void main() {
  late AuthSession session;
  late FakeProfileRepository profiles;
  late AdminEditProfileViewModel viewModel;

  AppUser adminWith({
    String name = 'Carlos Admin Pérez',
    String email = 'admin@correo.com',
    String phone = '5551234567',
  }) =>
      AppUser(
        uid: 'uid-admin',
        name: name,
        email: email,
        phone: phone,
        role: UserRole.admin,
        accountStatus: AccountStatus.active,
      );

  setUp(() {
    session = AuthSession.withRepository(FakeAuthRepository());
    profiles = FakeProfileRepository();
    session.start(adminWith());
    viewModel = AdminEditProfileViewModel(session: session, profiles: profiles);
  });

  tearDown(() => viewModel.dispose());

  test('PU-450 carga los datos actuales en el formulario', () {
    expect(viewModel.initialName, 'Carlos Admin Pérez');
    expect(viewModel.initialEmail, 'admin@correo.com');
    expect(viewModel.initialPhone, '5551234567');
  });

  test('PU-451 no hay cambios si se deja igual', () {
    expect(viewModel.hasChanges, isFalse);
    viewModel.edit(name: 'Carlos Admin Pérez', email: 'admin@correo.com', phone: '5551234567');
    expect(viewModel.hasChanges, isFalse);
  });

  test('PU-452 hay cambios si se modifica nombre, correo o teléfono', () {
    viewModel.edit(name: 'Otro Nombre', email: 'admin@correo.com', phone: '5551234567');
    expect(viewModel.hasChanges, isTrue);

    viewModel.edit(name: 'Carlos Admin Pérez', email: 'otro@correo.com', phone: '5551234567');
    expect(viewModel.hasChanges, isTrue);

    viewModel.edit(name: 'Carlos Admin Pérez', email: 'admin@correo.com', phone: '5559876543');
    expect(viewModel.hasChanges, isTrue);
  });

  test('PU-453 no guarda con nombre inválido', () async {
    viewModel.edit(name: 'Ab', email: 'admin@correo.com', phone: '5551234567');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, isNotNull);
    expect(profiles.updateProfileCalls, isEmpty);
  });

  test('PU-454 no guarda con correo inválido', () async {
    viewModel.edit(name: 'Carlos Admin', email: 'correo-invalido', phone: '5551234567');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, isNotNull);
    expect(profiles.updateProfileCalls, isEmpty);
  });

  test('PU-455 no guarda con teléfono inválido', () async {
    viewModel.edit(name: 'Carlos Admin', email: 'admin@correo.com', phone: '123');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, isNotNull);
    expect(profiles.updateProfileCalls, isEmpty);
  });

  test('PU-456 guarda nombre, correo y teléfono válidos', () async {
    viewModel.edit(name: '  Carlos   Nuevo  ', email: 'nuevo@correo.com', phone: '5559876543');
    final saved = await viewModel.save();

    expect(saved, isTrue);
    expect(profiles.updateProfileCalls.length, 1);
    expect(profiles.updateProfileCalls.first.name, 'Carlos Nuevo');
    expect(profiles.updateProfileCalls.first.email, 'nuevo@correo.com');
    expect(profiles.updateProfileCalls.first.phone, '5559876543');
    expect(viewModel.hasChanges, isFalse);
  });

  test('PU-457 actualiza la sesión tras guardar', () async {
    viewModel.edit(name: 'Carlos Actualizado', email: 'actualizado@correo.com', phone: '5550001111');
    await viewModel.save();

    expect(session.currentUser?.name, 'Carlos Actualizado');
    expect(session.currentUser?.email, 'actualizado@correo.com');
    expect(session.currentUser?.phone, '5550001111');
  });

  test('PU-458 muestra error si el correo ya está registrado', () async {
    profiles.error = ProfileFailure.emailAlreadyInUse;
    viewModel.edit(name: 'Carlos Admin', email: 'existente@correo.com', phone: '5551234567');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, ProfileFailure.emailAlreadyInUse.message);
  });

  test('PU-459 muestra error de red si falla la conexión', () async {
    profiles.error = ProfileFailure.network;
    viewModel.edit(name: 'Carlos Admin', email: 'nuevo@correo.com', phone: '5551234567');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, ProfileFailure.network.message);
  });

  test('PU-460 muestra error genérico si falla inesperadamente', () async {
    profiles.throwOnUpdate = true;
    viewModel.edit(name: 'Carlos Admin', email: 'nuevo@correo.com', phone: '5551234567');
    final saved = await viewModel.save();

    expect(saved, isFalse);
    expect(viewModel.errorMessage, ProfileFailure.unknown.message);
  });
}
