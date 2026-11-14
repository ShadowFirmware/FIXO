import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  /// Avisos de [userId], del más reciente al más antiguo, cada vez que
  /// cambian. Si falla, el stream emite un `NotificationFailure`.
  Stream<List<AppNotification>> watchFor(String userId);
}
