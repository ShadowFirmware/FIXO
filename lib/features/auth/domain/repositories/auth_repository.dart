import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Valida las credenciales y devuelve el perfil del usuario.
  ///
  /// Lanza [AuthFailure] si las credenciales no son válidas, el usuario no
  /// está registrado en el sistema o su cuenta no tiene acceso.
  Future<AppUser> signIn({required String email, required String password});

  /// Devuelve el usuario de la sesión guardada, o `null` si no hay sesión o
  /// la cuenta ya no tiene acceso.
  Future<AppUser?> restoreSession();

  Future<void> signOut();
}
