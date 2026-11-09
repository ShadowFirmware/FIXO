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

  /// Título de una incidencia (HU-2.3).
  static String? incidentTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Ingresa un título';
    if (title.length < 5) return 'El título debe tener al menos 5 caracteres';
    if (title.length > 80) return 'El título no debe pasar de 80 caracteres';
    return null;
  }

  /// Descripción de una incidencia (HU-2.3).
  static String? incidentDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) return 'Describe el problema';
    if (description.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }
    if (description.length > 500) {
      return 'La descripción no debe pasar de 500 caracteres';
    }
    return null;
  }

  /// Descripción de la solución aplicada por el técnico (HU-3.6).
  static String? solutionDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) return 'Describe la solución aplicada';
    if (description.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }
    if (description.length > 500) {
      return 'La descripción no debe pasar de 500 caracteres';
    }
    return null;
  }

  /// Contraseña de una cuenta nueva que registra el administrador (HU-4.3
  /// y HU-4.4): mínimo 8 caracteres.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Ingresa una contraseña';
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  /// Especialidad del técnico, por ejemplo "Electricidad".
  static String? specialty(String? value) {
    final specialty = value?.trim() ?? '';
    if (specialty.isEmpty) return 'Ingresa la especialidad';
    if (specialty.length < 3) return 'La especialidad es demasiado corta';
    if (specialty.length > 40) {
      return 'La especialidad no debe pasar de 40 caracteres';
    }
    return null;
  }
}
