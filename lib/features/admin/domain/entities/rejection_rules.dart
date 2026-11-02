/// Reglas del motivo de rechazo de una incidencia (HU-4.10).
abstract final class RejectionRules {
  static const maxLength = 500;

  /// Devuelve el error del [comment], o `null` si es válido. Un motivo con
  /// solo espacios cuenta como vacío.
  static String? validate(String comment) {
    final text = comment.trim();
    if (text.isEmpty) return 'Escribe el motivo del rechazo';
    if (text.length > maxLength) {
      return 'El motivo no debe exceder $maxLength caracteres';
    }
    return null;
  }
}
