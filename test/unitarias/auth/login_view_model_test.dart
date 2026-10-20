import 'package:fixo/core/errors/auth_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/domain/usecases/sign_in.dart';
import 'package:fixo/features/auth/presentation/providers/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// T-1.1.3 Validación de credenciales y T-1.1.6 Mensajes de error.
void main() {
  LoginViewModel viewModelWith(FakeAuthRepository repository) =>
      LoginViewModel(signIn: SignIn(repository));

  test(
    'PU-24 inicio de sesión exitoso devuelve el usuario sin error',
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
    'PU-25 credenciales inválidas dejan el mensaje de error (T-1.1.6)',
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

  test('PU-26 un error inesperado muestra un mensaje genérico', () async {
    final viewModel = viewModelWith(
      FakeAuthRepository(error: StateError('fallo')),
    );

    await viewModel.signIn(email: 'a@b.com', password: 'x');

    expect(viewModel.errorMessage, AuthFailure.unknown.message);
  });

  test('PU-27 indica que está cargando mientras valida', () async {
    final viewModel = viewModelWith(FakeAuthRepository(user: TestUsers.admin));
    final loadingStates = <bool>[];
    viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

    await viewModel.signIn(email: 'admin@correo.com', password: 'x');

    expect(loadingStates, [true, false]);
  });
}
