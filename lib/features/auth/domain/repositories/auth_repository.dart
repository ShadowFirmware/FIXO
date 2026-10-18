import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Valida las credenciales y devuelve el perfil del usuario.
  ///
  /// Lanza [AuthFailure] si las credenciales no son válidas o el usuario no
  /// está registrado en el sistema.
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();
}
