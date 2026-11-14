import 'dart:async';

import 'package:fixo/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:fixo/features/notifications/data/models/notification_model.dart';
import 'package:fixo/features/notifications/domain/entities/app_notification.dart';
import 'package:fixo/features/notifications/domain/repositories/notification_repository.dart';

/// Aviso [id] para [userId]. Sin [date], todavía no llega al servidor.
AppNotification notice(
  String id, {
  String userId = 'uid-residente',
  NotificationType? type = NotificationType.incidentAssigned,
  String title = 'Incidencia INC-0001 asignada',
  String message = 'Juan Pérez atenderá "Fuga en el baño".',
  String? refId = 'inc-1',
  bool read = false,
  DateTime? date,
}) => NotificationModel(
  id: id,
  userId: userId,
  type: type,
  title: title,
  message: message,
  refId: refId,
  read: read,
  date: date,
);

/// Simula el repositorio: las pruebas emiten los avisos a mano.
class FakeNotificationRepository implements NotificationRepository {
  final controller = StreamController<List<AppNotification>>.broadcast();

  /// Usuarios cuyos avisos se consultaron.
  final watched = <String>[];
  final markedRead = <String>[];
  final markedAll = <List<String>>[];

  /// Error que lanzan `markRead` y `markAllRead`, si hay.
  Object? updateError;

  @override
  Stream<List<AppNotification>> watchFor(String userId) {
    watched.add(userId);
    return controller.stream;
  }

  @override
  Future<void> markRead(String id) async {
    if (updateError case final error?) throw error;
    markedRead.add(id);
  }

  @override
  Future<void> markAllRead(List<String> ids) async {
    if (updateError case final error?) throw error;
    markedAll.add(ids);
  }

  Future<void> close() => controller.close();
}

/// Simula Firestore para probar cómo el repositorio traduce los errores.
class FakeNotificationRemoteDataSource extends NotificationRemoteDataSource {
  final controller = StreamController<List<NotificationModel>>.broadcast();

  /// Error que lanzan `markRead` y `markAllRead`, si hay.
  Object? updateError;
  final markedAll = <List<String>>[];

  @override
  Stream<List<NotificationModel>> watchFor(String userId) => controller.stream;

  @override
  Future<void> markRead(String id) async {
    if (updateError case final error?) throw error;
  }

  @override
  Future<void> markAllRead(Iterable<String> ids) async {
    if (updateError case final error?) throw error;
    markedAll.add(ids.toList());
  }
}
