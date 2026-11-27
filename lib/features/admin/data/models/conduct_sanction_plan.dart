import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../../notifications/data/models/notification_notices.dart';

/// Reglas de las sanciones progresivas por reportes de conducta validados
/// (HU-7.4), aplicadas sobre los documentos que se leen dentro de la
/// transacción. Son funciones puras para poder probarlas sin Firestore.
abstract final class ConductSanctionPlan {
  /// Reportes validados con los que la cuenta se deshabilita sin fecha de
  /// término.
  static const reportsToDisable = NotificationNotices.reportsToDisable;

  /// Estado de conducta según la cantidad de reportes validados.
  static ConductStatus conductStatusFor(int validatedReports) {
    if (validatedReports <= 1) return ConductStatus.good;
    if (validatedReports <= 3) return ConductStatus.medium;
    return ConductStatus.bad;
  }

  /// Días de suspensión temporal que corresponden al número de reporte
  /// validado (2 -> 5, 3 -> 10, 4 -> 20). Los demás no suspenden.
  static int suspensionDaysFor(int validatedReports) => switch (validatedReports) {
        2 => 5,
        3 => 10,
        4 => 20,
        _ => 0,
      };

  /// `true` si la cuenta debe quedar deshabilitada de forma indefinida.
  static bool disablesAccount(int validatedReports) =>
      validatedReports >= reportsToDisable;

  /// `true` si el número de reporte validado implica una suspensión temporal.
  static bool suspendsAccount(int validatedReports) =>
      suspensionDaysFor(validatedReports) > 0;

  /// Fecha en la que termina la suspensión temporal, o `null` si no hay.
  static DateTime? suspendedUntil({
    required int validatedReports,
    required DateTime now,
  }) {
    final days = suspensionDaysFor(validatedReports);
    if (days <= 0) return null;
    return now.add(Duration(days: days));
  }

  /// Cambios que se guardan en el documento del usuario reportado cuando se
  /// valida un reporte. Si [decision] no es Validado, no hay cambios.
  ///
  /// [hasActiveIncidents] solo importa para técnicos con una suspensión
  /// temporal pendiente: si tiene incidencias Asignadas o En proceso, la
  /// suspensión se difiere y la cuenta sigue activa pero sin poder recibir
  /// nuevas asignaciones.
  static Map<String, dynamic> userUpdate({
    required Map<String, dynamic>? user,
    required ConductReportStatus decision,
    required DateTime now,
    bool hasActiveIncidents = false,
  }) {
    if (decision != ConductReportStatus.validated || user == null) return const {};

    final current = (user['reportesValidados'] as num?)?.toInt() ?? 0;
    final next = current + 1;
    final role = user['rol'] as String?;
    final isTechnician = role == UserRole.technician.value;
    final disable = disablesAccount(next);
    final days = suspensionDaysFor(next);
    final suspend = days > 0;

    final update = <String, dynamic>{
      'reportesValidados': next,
      'estadoConducta': conductStatusFor(next).value,
    };

    if (disable) {
      update['estadoCuenta'] = AccountStatus.disabled.value;
      update['suspendidaHasta'] = null;
      if (isTechnician) update['disponible'] = false;
      update.remove('suspensionPendiente');
      update.remove('diasSuspensionPendiente');
    } else if (suspend) {
      if (isTechnician && hasActiveIncidents) {
        // Se difiere la suspensión: la cuenta sigue activa pero no puede
        // recibir nuevas asignaciones.
        update['estadoCuenta'] = AccountStatus.active.value;
        update['suspendidaHasta'] = null;
        update['disponible'] = false;
        update['suspensionPendiente'] = true;
        update['diasSuspensionPendiente'] = days;
      } else {
        update['estadoCuenta'] = AccountStatus.suspended.value;
        update['suspendidaHasta'] = Timestamp.fromDate(
          now.add(Duration(days: days)),
        );
        if (isTechnician) update['disponible'] = false;
        update['suspensionPendiente'] = false;
        update['diasSuspensionPendiente'] = 0;
      }
    } else {
      // Advertencia: la cuenta no cambia.
    }

    return update;
  }

  /// Aplica una suspensión temporal que estaba diferida por incidencias
  /// activas, cuando el técnico ya no tiene ninguna. Devuelve los cambios
  /// que se guardan, o vacío si no había suspensión pendiente.
  static Map<String, dynamic> applyPendingSuspension(
    Map<String, dynamic>? user, {
    required DateTime now,
  }) {
    if (user == null) return const {};
    if (user['suspensionPendiente'] != true) return const {};
    final days = (user['diasSuspensionPendiente'] as num?)?.toInt() ?? 0;
    if (days <= 0) return const {};
    return {
      'estadoCuenta': AccountStatus.suspended.value,
      'suspendidaHasta': Timestamp.fromDate(now.add(Duration(days: days))),
      'disponible': false,
      'suspensionPendiente': false,
      'diasSuspensionPendiente': 0,
    };
  }

  /// Notificaciones que se generan al validar un reporte, según la sanción.
  static List<Map<String, dynamic>> notices({
    required String userId,
    required String reportId,
    required int validatedReports,
    required String reason,
    required DateTime now,
    DateTime? suspendedUntil,
  }) {
    final list = <Map<String, dynamic>>[];
    // Advertencia siempre.
    list.add(
      NotificationNotices.conductWarning(
        userId: userId,
        reportId: reportId,
        validatedReports: validatedReports,
        reason: reason,
      ),
    );
    if (disablesAccount(validatedReports)) {
      list.add(
        NotificationNotices.accountDisabled(userId: userId, reportId: reportId),
      );
    } else if (suspendsAccount(validatedReports) && suspendedUntil != null) {
      list.add(
        NotificationNotices.accountSuspended(
          userId: userId,
          from: now,
          until: suspendedUntil,
          reportId: reportId,
        ),
      );
    }
    return list;
  }
}
