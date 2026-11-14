import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/app_notification.dart';

/// Muestra los avisos como notificaciones del teléfono (HU-6.1).
abstract interface class SystemNotifier {
  /// Prepara el plugin. [onOpen] recibe el aviso cuando el usuario toca su
  /// notificación.
  Future<void> init({required void Function(AppNotification) onOpen});

  Future<void> show(AppNotification notification);
}

/// Notificaciones locales con `flutter_local_notifications`.
///
/// Como el plan Spark no incluye Cloud Functions para enviar mensajes push,
/// la app las muestra mientras está abierta o en segundo plano, a partir de
/// los avisos que llegan de Firestore. Con la app cerrada, los avisos se
/// ven al abrirla en la pestaña Avisos.
class LocalSystemNotifier implements SystemNotifier {
  LocalSystemNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'fixo_avisos',
    'Avisos de FIXO',
    channelDescription: 'Cambios en tus incidencias y avisos sobre tu cuenta.',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Solo Android e iOS: en la web y el escritorio los avisos se ven en la
  /// app.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> init({required void Function(AppNotification) onOpen}) async {
    if (!supported || _ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // El permiso se pide aparte, con la explicación de FIXO.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final notification = decodePayload(response.payload);
        if (notification != null) onOpen(notification);
      },
    );
    _ready = true;
  }

  @override
  Future<void> show(AppNotification notification) async {
    if (!_ready) return;
    await _plugin.show(
      id: idFor(notification),
      title: notification.title,
      body: notification.message,
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: encodePayload(notification),
    );
  }

  /// Número estable por aviso, así el mismo aviso no se duplica en la
  /// bandeja.
  static int idFor(AppNotification notification) =>
      notification.id.hashCode & 0x7fffffff;

  /// Lo necesario para abrir el aviso al tocar la notificación.
  static String encodePayload(AppNotification notification) => jsonEncode({
    'id': notification.id,
    'usuarioId': notification.userId,
    'tipo': notification.type?.value,
    'refId': notification.refId,
  });

  static AppNotification? decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) return null;
      return AppNotification(
        id: id,
        userId: data['usuarioId'] as String? ?? '',
        type: NotificationType.fromValue(data['tipo'] as String?),
        title: '',
        message: '',
        refId: data['refId'] as String?,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
