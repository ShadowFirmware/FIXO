import '../../../auth/domain/entities/app_user.dart';
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

  /// A cada administrador: se levantó un reporte de conducta contra
  /// [reportedName] (T 6.1.9). Lo usa la HU 7.x al registrar el reporte,
  /// con `NotificationRemoteDataSource.addNotices` en la misma transacción.
  static List<Map<String, dynamic>> conductReport({
    required Iterable<String> adminIds,
    required String reportId,
    required String reportedName,
    required UserRole reportedRole,
    String reason = '',
  }) {
    final detail = reason.trim();
    return [
      for (final adminId in adminIds.toSet())
        NotificationModel.newNotice(
          userId: adminId,
          type: NotificationType.conductReport,
          title: 'Nuevo reporte de conducta',
          message: [
            'Se reportó a $reportedName (${roleLabel(reportedRole)}).',
            if (detail.isNotEmpty) 'Motivo: ${_shorten(detail)}',
            'Revísalo para validarlo o descartarlo.',
          ].join(' '),
          refId: reportId,
        ),
    ];
  }

  /// "Residente", "Técnico" o "Administrador".
  static String roleLabel(UserRole role) => switch (role) {
    UserRole.resident => 'Residente',
    UserRole.technician => 'Técnico',
    UserRole.admin => 'Administrador',
  };

  static const _maxDetail = 200;

  static String _shorten(String text) => text.length <= _maxDetail
      ? text
      : '${text.substring(0, _maxDetail).trimRight()}…';
}
