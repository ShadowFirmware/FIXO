/// Error al guardar el perfil, con un mensaje listo para mostrarse.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  static const network = ProfileFailure(
    'No hay conexión a internet. Tus cambios no se guardaron.',
  );
  static const permissionDenied = ProfileFailure(
    'No tienes permiso para modificar este perfil.',
  );
  static const notFound = ProfileFailure(
    'No se encontró tu perfil. Contacta al administrador.',
  );
  static const unknown = ProfileFailure(
    'No se pudieron guardar los cambios. Inténtalo de nuevo.',
  );

  @override
  String toString() => message;
}
