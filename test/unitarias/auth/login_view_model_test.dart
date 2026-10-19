import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/domain/usecases/sign_in.dart';
import 'package:fixo/features/auth/presentation/providers/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// T-1.1.3 Validación de credenciales y T-1.1.6 Mensajes de error.
void main() {
  group('SignIn', () {
    test('PU-24 quita los espacios del correo antes de validar', () async {
      final repository = FakeAuthRepository(user: TestUsers.admin);

      await SignIn(repository)
          .call(email: '  admin@correo.com ', password: ' clave ');

      expect(repository.lastEmail, 'admin@correo.com');
      // La contraseña no se modifica: los espacios pueden ser parte de ella.
      expect(repository.lastPassword, ' clave ');
    });
  });

  group('LoginViewModel', () {
    LoginViewModel viewModelWith(FakeAuthRepository repository) =>
        LoginViewModel(signIn: SignIn(repository));

    test(
      'PU-25 inicio de sesión exitoso devuelve el usuario sin error',
      () async {
        final viewModel = viewModelWith(
          FakeAuthRepository(user: TestUsers.technician),
        );

        final user = await viewModel.signIn(
          email: 'juan@correo.com',
          password: TestUsers.password,
        );

        expect(user?.role, UserRole.technician);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      },
    );

    test(
      'PU-26 credenciales inválidas dejan el mensaje de error (T-1.1.6)',
      () async {
        final viewModel = viewModelWith(
          FakeAuthRepository(error: AuthFailure.invalidCredentials),
        );

        final user = await viewModel.signIn(
          email: 'maria@correo.com',
          password: 'incorrecta',
        );

        expect(user, isNull);
        expect(
          viewModel.errorMessage,
          'El correo o la contraseña no son válidos.',
        );
        expect(viewModel.isLoading, isFalse);
      },
    );

    test('PU-27 un error inesperado muestra un mensaje genérico', () async {
      final viewModel = viewModelWith(
        FakeAuthRepository(error: StateError('fallo')),
      );

      await viewModel.signIn(email: 'a@b.com', password: 'x');

      expect(viewModel.errorMessage, AuthFailure.unknown.message);
    });

    test('PU-28 indica que está cargando mientras valida', () async {
      final viewModel = viewModelWith(
        FakeAuthRepository(user: TestUsers.admin),
      );
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.signIn(email: 'admin@correo.com', password: 'x');

      expect(loadingStates, [true, false]);
    });

    test('PU-29 un nuevo intento limpia el error anterior', () async {
      final repository = FakeAuthRepository(
        error: AuthFailure.invalidCredentials,
      );
      final viewModel = viewModelWith(repository);
      await viewModel.signIn(email: 'a@b.com', password: 'x');
      String? errorWhileLoading = 'sin cambios';
      viewModel.addListener(() {
        if (viewModel.isLoading) errorWhileLoading = viewModel.errorMessage;
      });

      await viewModel.signIn(email: 'a@b.com', password: 'x');

      expect(errorWhileLoading, isNull);
    });
  });
}
