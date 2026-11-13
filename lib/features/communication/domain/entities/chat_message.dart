import '../../../auth/domain/entities/app_user.dart';

/// Mensaje del chat de una incidencia (HU-5.1).
///
/// El nombre y el rol de quien lo envió se guardan en el mensaje, así el
/// historial conserva su contexto aunque después cambie el residente de la
/// vivienda o el técnico asignado.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.incidentId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    this.sentAt,
  });

  final String id;
  final String incidentId;

  /// UID de quien lo envió.
  final String authorId;
  final String authorName;
  final UserRole authorRole;
  final String text;

  /// Hora del servidor, o `null` mientras el mensaje no llega a Firestore.
  final DateTime? sentAt;

  bool get isPending => sentAt == null;

  /// Largo máximo de un mensaje.
  static const maxLength = 1000;

  /// Mensaje de error del texto, o `null` si se puede enviar.
  static String? validate(String text) {
    final value = text.trim();
    if (value.isEmpty) return 'Escribe un mensaje';
    if (value.length > maxLength) {
      return 'El mensaje no debe pasar de $maxLength caracteres';
    }
    return null;
  }
}
