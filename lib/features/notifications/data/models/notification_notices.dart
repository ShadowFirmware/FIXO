import '../../domain/entities/app_notification.dart';
import 'notification_model.dart';

/// Catálogo de los avisos del sistema (HU-6.1). Cada función arma los
/// campos de un aviso para un destinatario; los módulos los guardan con
/// `NotificationRemoteDataSource` junto con el cambio que los provoca.
///
/// Son funciones puras para poder probarlas sin Firestore.
abstract final class NotificationNotices {
  /// Al administrador: una incidencia nueva espera asignación (T 6.1.5).
  static Map<String, dynamic> newIncident({
    required String adminId,
    required String incidentId,
    required String reportNumber,
    required String title,
    String typeLabel = '',
  }) => NotificationModel.newNotice(
    userId: adminId,
    type: NotificationType.newIncident,
    title: 'Nueva incidencia $reportNumber',
    message: typeLabel.isEmpty
        ? '"$title" está pendiente de asignación.'
        : '"$title" ($typeLabel) está pendiente de asignación.',
    refId: incidentId,
  );
}
