/// Error de autenticación con un mensaje listo para mostrarse al usuario.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  static const invalidCredentials = AuthFailure(
    'El correo o la contraseña no son válidos.',
  );
  static const notRegistered = AuthFailure(
    'Este usuario no está registrado en el sistema.',
  );
  static const tooManyRequests = AuthFailure(
    'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
  );
  static const network = AuthFailure(
    'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.',
  );
  static const unknown = AuthFailure(
    'Ocurrió un error inesperado. Inténtalo de nuevo.',
  );
  static const accountRemoved = AuthFailure(
    'Tu cuenta fue dada de baja y ya no tiene acceso al sistema.',
  );
  static const accountDisabled = AuthFailure(
    'Tu cuenta está deshabilitada. Contacta al administrador.',
  );

  factory AuthFailure.accountSuspended(DateTime? until) {
    if (until == null) return const AuthFailure('Tu cuenta está suspendida.');
    final date =
        '${until.day.toString().padLeft(2, '0')}/'
        '${until.month.toString().padLeft(2, '0')}/${until.year}';
    return AuthFailure('Tu cuenta está suspendida hasta el $date.');
  }

  @override
  String toString() => message;
}
