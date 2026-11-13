import '../entities/chat_access.dart';
import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  /// Incidencia y residente activo de su vivienda, para decidir quién
  /// puede usar el chat. `null` si la incidencia no existe. Si falla, lanza
  /// un `ChatFailure`.
  Future<ChatContext?> context(String incidentId);

  /// Mensajes de la incidencia [incidentId], del más antiguo al más
  /// reciente. Si falla, lanza un `ChatFailure`.
  Future<List<ChatMessage>> messages(String incidentId);
}
