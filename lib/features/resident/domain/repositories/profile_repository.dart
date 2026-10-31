/// Datos del perfil que el residente/administrador puede modificar.
abstract interface class ProfileRepository {
  /// Guarda el nombre, el correo y el teléfono en el documento `usuarios/{uid}`.
  ///
  /// Si el correo ya está registrado por otro usuario lanza un [ProfileFailure].
  /// Si falla lanza un `ProfileFailure`.
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String email,
    required String phone,
  });
}
