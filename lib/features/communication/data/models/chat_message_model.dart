import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/chat_message.dart';

/// Convierte los documentos de `incidencias/{id}/mensajes` en
/// [ChatMessage]:
///
/// | Campo | Contenido |
/// |---|---|
/// | `autorId` | UID de quien lo envió |
/// | `autorNombre` | Nombre al momento de enviarlo |
/// | `autorRol` | `residente` o `tecnico` |
/// | `texto` | Contenido del mensaje |
/// | `fecha` | Hora del servidor |
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.incidentId,
    required super.authorId,
    required super.authorName,
    required super.authorRole,
    required super.text,
    super.sentAt,
  });

  /// Lanza [FormatException] si el documento no tiene autor, rol o texto.
  factory ChatMessageModel.fromMap(
    String id,
    String incidentId,
    Map<String, dynamic> data,
  ) {
    final authorId = data['autorId'] as String? ?? '';
    final role = UserRole.fromValue(data['autorRol'] as String?);
    final text = data['texto'] as String? ?? '';
    if (authorId.isEmpty || role == null || text.trim().isEmpty) {
      throw FormatException('Mensaje no válido: $id');
    }
    final date = data['fecha'];
    return ChatMessageModel(
      id: id,
      incidentId: incidentId,
      authorId: authorId,
      authorName: (data['autorNombre'] as String?)?.trim() ?? '',
      authorRole: role,
      text: text,
      sentAt: date is Timestamp ? date.toDate() : null,
    );
  }

  /// Campos de un mensaje nuevo. La fecha la pone el servidor.
  static Map<String, dynamic> newMessage({
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    required String text,
  }) => {
    'autorId': authorId,
    'autorNombre': authorName.trim(),
    'autorRol': authorRole.value,
    'texto': text.trim(),
    'fecha': FieldValue.serverTimestamp(),
  };
}
