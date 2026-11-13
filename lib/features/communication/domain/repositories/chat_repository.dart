import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  /// Mensajes de la incidencia [incidentId], del más antiguo al más
  /// reciente. Si falla, lanza un `ChatFailure`.
  Future<List<ChatMessage>> messages(String incidentId);
}
