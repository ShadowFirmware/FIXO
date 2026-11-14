import '../../../../core/utils/date_formats.dart';
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

  /// Reportes validados con los que la cuenta se deshabilita sin fecha de
  /// término (HU-7.x).
  static const reportsToDisable = 5;

  /// Al usuario reportado: se validó un reporte de conducta en su contra
  /// (T 6.1.10). [validatedReports] cuenta este reporte.
  static Map<String, dynamic> conductWarning({
    required String userId,
    required String reportId,
    required int validatedReports,
    String reason = '',
  }) {
    final detail = reason.trim();
    final left = reportsToDisable - validatedReports;
    return NotificationModel.newNotice(
      userId: userId,
      type: NotificationType.conductWarning,
      title: 'Advertencia por conducta',
      message: [
        'Se validó un reporte de conducta en tu contra.',
        if (detail.isNotEmpty) 'Motivo: ${_shorten(detail)}',
        'Llevas $validatedReports de $reportsToDisable reportes validados.',
        if (left > 0)
          'Al llegar a $reportsToDisable tu cuenta se deshabilitará.',
      ].join(' '),
      refId: reportId,
    );
  }

  /// Al usuario: su cuenta se suspendió desde [from] hasta [until]
  /// (T 6.1.11). El aviso dice cuánto dura y cuándo termina.
  static Map<String, dynamic> accountSuspended({
    required String userId,
    required DateTime from,
    required DateTime until,
    String? reportId,
  }) => NotificationModel.newNotice(
    userId: userId,
    type: NotificationType.accountSuspended,
    title: 'Cuenta suspendida',
    message:
        'Tu cuenta se suspendió por ${durationLabel(until.difference(from))}, '
        'hasta el ${DateFormats.dateTime(until)}. Mientras tanto no podrás '
        'iniciar sesión.',
    refId: reportId,
  );

  /// "3 días", "1 día", "5 horas" o "30 minutos". Se redondea hacia arriba
  /// para no prometer menos tiempo del real.
  static String durationLabel(Duration duration) {
    String plural(int n, String one, String many) =>
        n == 1 ? '1 $one' : '$n $many';
    final minutes = (duration.inSeconds / 60).ceil();
    if (minutes < 60) {
      return plural(minutes < 1 ? 1 : minutes, 'minuto', 'minutos');
    }
    final hours = (minutes / 60).ceil();
    if (hours < 24) return plural(hours, 'hora', 'horas');
    return plural((hours / 24).ceil(), 'día', 'días');
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
