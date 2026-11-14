import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

/// Convierte los documentos de `notificaciones` en [AppNotification]:
///
/// | Campo | Contenido |
/// |---|---|
/// | `usuarioId` | UID de quien lo recibe |
/// | `tipo` | Valor de [NotificationType] |
/// | `titulo` | Título corto |
/// | `mensaje` | Detalle del aviso |
/// | `refId` | Documento relacionado (por ejemplo, la incidencia) o `null` |
/// | `leida` | Si ya lo vio |
/// | `fecha` | Hora del servidor |
class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.refId,
    super.read,
    super.date,
  });

  /// Lanza [FormatException] si no tiene destinatario o título.
  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    final userId = data['usuarioId'] as String? ?? '';
    final title = (data['titulo'] as String? ?? '').trim();
    if (userId.isEmpty || title.isEmpty) {
      throw FormatException('Aviso no válido: $id');
    }
    final date = data['fecha'];
    return NotificationModel(
      id: id,
      userId: userId,
      type: NotificationType.fromValue(data['tipo'] as String?),
      title: title,
      message: (data['mensaje'] as String? ?? '').trim(),
      refId: data['refId'] as String?,
      read: data['leida'] == true,
      date: date is Timestamp ? date.toDate() : null,
    );
  }

  /// Campos de un aviso nuevo, sin leer. La fecha la pone el servidor.
  static Map<String, dynamic> newNotice({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? refId,
  }) => {
    'usuarioId': userId,
    'tipo': type.value,
    'titulo': title,
    'mensaje': message,
    'refId': refId,
    'leida': false,
    'fecha': FieldValue.serverTimestamp(),
  };

  /// Cambio para marcarlo como leído.
  static const markRead = <String, dynamic>{'leida': true};
}
