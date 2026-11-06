import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/resident/data/datasources/profile_remote_data_source.dart';
import 'package:fixo/features/resident/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fakes.dart';

/// Datasource que falla con el error indicado al pedir el cambio de correo.
class _FailingDataSource implements ProfileRemoteDataSource {
  _FailingDataSource(this.code);

  final String code;

  @override
  Future<void> requestEmailChange({
    required String uid,
    required String email,
  }) async => throw firestoreError(code);

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {}
}

/// HU-3.2 Cambio del correo en Firebase Authentication.
void main() {
  const oldEmail = 'juan@correo.com';
  const newEmail = 'juan.nuevo@correo.com';

  const technician = UserModel(
    uid: 'uid-tecnico',
    name: 'Juan Pérez Ramírez',
    email: oldEmail,
    phone: '7774445566',
    role: UserRole.technician,
    accountStatus: AccountStatus.active,
    pendingEmail: newEmail,
  );

  FakeAuthRemoteDataSource dataSource({required String authEmail}) =>
      FakeAuthRemoteDataSource(
        passwords: {oldEmail: TestUsers.password},
        profiles: {technician.uid: technician},
        currentEmail: authEmail,
      );

  test('PU-512 los errores de Authentication se traducen a mensajes', () async {
    final cases = {
      'requires-recent-login': ProfileFailure.recentLoginRequired,
      'email-already-in-use': ProfileFailure.emailTaken,
      'too-many-requests': ProfileFailure.tooManyRequests,
      'network-request-failed': ProfileFailure.network,
    };

    for (final MapEntry(key: code, value: failure) in cases.entries) {
      final repository = ProfileRepositoryImpl(
        remote: _FailingDataSource(code),
      );
      await expectLater(
        repository.requestEmailChange(uid: 'u', email: newEmail),
        throwsA(same(failure)),
        reason: code,
      );
    }
  });

  test(
    'PU-513 al entrar con el correo confirmado el perfil pasa a usarlo',
    () async {
      final remote = dataSource(authEmail: newEmail);
      final repository = AuthRepositoryImpl(remote: remote);

      final user = await repository.signIn(
        email: oldEmail,
        password: TestUsers.password,
      );

      expect(user.email, newEmail);
      expect(remote.confirmedEmails, {technician.uid: newEmail});
    },
  );

  test('PU-514 sin confirmar el enlace el perfil conserva su correo', () async {
    final remote = dataSource(authEmail: oldEmail);
    final repository = AuthRepositoryImpl(remote: remote);

    final user = await repository.signIn(
      email: oldEmail,
      password: TestUsers.password,
    );

    expect(user.email, oldEmail);
    expect(remote.confirmedEmails, isEmpty);
  });
}
