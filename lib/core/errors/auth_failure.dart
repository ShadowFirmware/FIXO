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

  @override
  String toString() => message;
}
