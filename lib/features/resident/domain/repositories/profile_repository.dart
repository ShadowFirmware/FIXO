/// Datos del perfil que el usuario puede modificar.
abstract interface class ProfileRepository {
  /// Guarda el nombre y el teléfono en el documento `usuarios/{uid}`.
  ///
  /// Solo toca esos dos campos: el correo, el rol y la vivienda no se pueden
  /// cambiar desde el perfil. Si falla lanza un `ProfileFailure`.
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String phone,
  });

  /// Guarda nombre, correo y teléfono. Usado por el administrador (HU-4.2).
  /// Valida que el correo no esté registrado por otro usuario.
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? currentEmail,
  });
}
