import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// T-1.1.3 Validación de credenciales y T-1.1.4 Control de acceso y sesión.
void main() {
  FakeAuthRemoteDataSource dataSourceWith(List<UserModel> users) {
    return FakeAuthRemoteDataSource(
      passwords: {for (final u in users) u.email: TestUsers.password},
      profiles: {for (final u in users) u.uid: u},
    );
  }

  group('Validación de credenciales (T-1.1.3)', () {
    test(
      'PU-07 credenciales válidas devuelven el perfil del usuario',
      () async {
        final repository = AuthRepositoryImpl(
          remote: dataSourceWith([TestUsers.resident()]),
        );

        final user = await repository.signIn(
          email: 'maria@correo.com',
          password: TestUsers.password,
        );

        expect(user.uid, 'uid-residente');
        expect(user.role, UserRole.resident);
      },
    );

    test('PU-08 contraseña incorrecta lanza credenciales no válidas', () async {
      final repository = AuthRepositoryImpl(
        remote: dataSourceWith([TestUsers.resident()]),
      );

      expect(
        repository.signIn(email: 'maria@correo.com', password: 'otra-clave'),
        throwsA(AuthFailure.invalidCredentials),
      );
    });

    test('PU-09 correo no registrado lanza credenciales no válidas', () async {
      final repository = AuthRepositoryImpl(
        remote: dataSourceWith([TestUsers.resident()]),
      );

      expect(
        repository.signIn(
          email: 'nadie@correo.com',
          password: TestUsers.password,
        ),
        throwsA(AuthFailure.invalidCredentials),
      );
    });

    for (final code in [
      'invalid-credential',
      'invalid-email',
      'wrong-password',
      'user-not-found',
      'user-disabled',
    ]) {
      test(
        'PU-10 el código "$code" se muestra como credenciales no válidas',
        () {
          final repository = AuthRepositoryImpl(
            remote: FakeAuthRemoteDataSource(
              signInError: FirebaseAuthException(code: code),
            ),
          );

          expect(
            repository.signIn(email: 'a@b.com', password: 'x'),
            throwsA(AuthFailure.invalidCredentials),
          );
        },
      );
    }

    test('PU-11 demasiados intentos muestra el mensaje correspondiente', () {
      final repository = AuthRepositoryImpl(
        remote: FakeAuthRemoteDataSource(
          signInError: FirebaseAuthException(code: 'too-many-requests'),
        ),
      );

      expect(
        repository.signIn(email: 'a@b.com', password: 'x'),
        throwsA(AuthFailure.tooManyRequests),
      );
    });

    test('PU-12 sin internet muestra el mensaje de conexión', () {
      final repository = AuthRepositoryImpl(
        remote: FakeAuthRemoteDataSource(
          signInError: FirebaseAuthException(code: 'network-request-failed'),
        ),
      );

      expect(
        repository.signIn(email: 'a@b.com', password: 'x'),
        throwsA(AuthFailure.network),
      );
    });

    test(
      'PU-13 cuenta sin documento en usuarios se rechaza y cierra sesión',
      () async {
        final remote = FakeAuthRemoteDataSource(
          passwords: {'huerfano@correo.com': TestUsers.password},
        );
        final repository = AuthRepositoryImpl(remote: remote);

        await expectLater(
          repository.signIn(
            email: 'huerfano@correo.com',
            password: TestUsers.password,
          ),
          throwsA(AuthFailure.notRegistered),
        );
        expect(remote.signOutCalls, 1);
        expect(remote.currentUid, isNull);
      },
    );

    test('PU-14 sin permiso para leer usuarios cierra la sesión', () async {
      final remote = FakeAuthRemoteDataSource(
        passwords: {'maria@correo.com': TestUsers.password},
        profiles: {'uid-residente': TestUsers.resident()},
        fetchError: firestoreError('permission-denied'),
      );
      final repository = AuthRepositoryImpl(remote: remote);

      await expectLater(
        repository.signIn(
          email: 'maria@correo.com',
          password: TestUsers.password,
        ),
        throwsA(AuthFailure.unknown),
      );
      expect(remote.signOutCalls, 1);
    });
  });

  group('Control de acceso (T-1.1.4)', () {
    Future<AppUser> signInAs(UserModel user) {
      return AuthRepositoryImpl(remote: dataSourceWith([user]))
          .signIn(email: user.email, password: TestUsers.password);
    }

    test('PU-15 cuenta dada de baja no puede iniciar sesión', () {
      expect(
        signInAs(TestUsers.resident(status: AccountStatus.removed)),
        throwsA(AuthFailure.accountRemoved),
      );
    });

    test('PU-16 cuenta deshabilitada no puede iniciar sesión', () {
      expect(
        signInAs(TestUsers.resident(status: AccountStatus.disabled)),
        throwsA(AuthFailure.accountDisabled),
      );
    });

    test('PU-17 cuenta suspendida vigente no puede iniciar sesión', () {
      final until = DateTime.now().add(const Duration(days: 5));

      expect(
        signInAs(
          TestUsers.resident(
            status: AccountStatus.suspended,
            suspendedUntil: until,
          ),
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            contains('suspendida hasta el'),
          ),
        ),
      );
    });

    test('PU-18 suspensión vencida permite iniciar sesión', () async {
      final user = await signInAs(
        TestUsers.resident(
          status: AccountStatus.suspended,
          suspendedUntil: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      expect(user.uid, 'uid-residente');
    });

    test('PU-19 cuenta rechazada deja la sesión cerrada', () async {
      final remote = dataSourceWith([
        TestUsers.resident(status: AccountStatus.removed),
      ]);

      await expectLater(
        AuthRepositoryImpl(remote: remote)
            .signIn(email: 'maria@correo.com', password: TestUsers.password),
        throwsA(isA<AuthFailure>()),
      );
      expect(remote.currentUid, isNull);
    });
  });

  group('Sesión (T-1.1.4)', () {
    test('PU-20 sin sesión guardada restoreSession devuelve null', () async {
      final repository = AuthRepositoryImpl(remote: FakeAuthRemoteDataSource());

      expect(await repository.restoreSession(), isNull);
    });

    test('PU-21 con sesión guardada recupera al usuario', () async {
      final repository = AuthRepositoryImpl(
        remote: FakeAuthRemoteDataSource(
          profiles: {'uid-admin': TestUsers.admin},
          currentUid: 'uid-admin',
        ),
      );

      final user = await repository.restoreSession();

      expect(user?.role, UserRole.admin);
    });

    test(
      'PU-22 sesión guardada de una cuenta dada de baja no se recupera',
      () async {
        final remote = FakeAuthRemoteDataSource(
          profiles: {
            'uid-residente': TestUsers.resident(status: AccountStatus.removed),
          },
          currentUid: 'uid-residente',
        );

        expect(
          await AuthRepositoryImpl(remote: remote).restoreSession(),
          isNull,
        );
        expect(remote.currentUid, isNull);
      },
    );

    test('PU-23 cerrar sesión borra la sesión guardada', () async {
      final remote = FakeAuthRemoteDataSource(currentUid: 'uid-admin');

      await AuthRepositoryImpl(remote: remote).signOut();

      expect(remote.currentUid, isNull);
    });
  });
}
