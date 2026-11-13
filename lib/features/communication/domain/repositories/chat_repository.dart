import '../entities/chat_access.dart';
import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  /// Incidencia y residente activo de su vivienda, para decidir quién
  /// puede usar el chat. `null` si la incidencia no existe. Si falla, lanza
  /// un `ChatFailure`.
  Future<ChatContext?> context(String incidentId);

  /// Mensajes de la incidencia [incidentId], del más antiguo al más
  /// reciente, cada vez que alguien envía uno. Si falla, el stream emite un
  /// `ChatFailure`.
  Stream<List<ChatMessage>> watchMessages(String incidentId);

  /// Envía [text] como mensaje de [authorId]. Si no se puede, lanza un
  /// `ChatFailure`.
  Future<void> send({
    required String incidentId,
    required String authorId,
    required String text,
  });
}
