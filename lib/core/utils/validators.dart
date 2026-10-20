/// Validaciones de formularios. Devuelven el mensaje de error o `null` si
/// el valor es válido, como espera `TextFormField.validator`.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(email)) return 'Correo no válido';
    return null;
  }

  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }
}
