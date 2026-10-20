import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// HU-1.1 Iniciar sesión con correo y contraseña.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.signIn(email: email.trim(), password: password);
  }
}
