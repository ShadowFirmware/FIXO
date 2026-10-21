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

  /// Letras (con acentos), espacios, apóstrofos, puntos y guiones.
  static final _nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' .-]+$");

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Ingresa tu nombre';
    if (name.length < 3) return 'El nombre es demasiado corto';
    if (name.length > 80) return 'El nombre no debe pasar de 80 caracteres';
    if (!_nameRegex.hasMatch(name)) return 'El nombre solo puede tener letras';
    return null;
  }

  static final _phoneRegex = RegExp(r'^\d{10}$');

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Ingresa tu teléfono';
    if (!_phoneRegex.hasMatch(phone)) {
      return 'El teléfono debe tener 10 dígitos';
    }
    return null;
  }
}
