/// Datos del perfil que el residente puede modificar (HU-2.2).
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
}
