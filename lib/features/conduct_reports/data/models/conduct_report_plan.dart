import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../notifications/data/models/notification_notices.dart';
import '../../domain/entities/conduct_report.dart';
import 'conduct_report_model.dart';

/// Reglas para registrar el reporte de conducta de un residente contra el
/// técnico de una incidencia (HU-7.1), aplicadas sobre los documentos que
/// se leen dentro de la transacción. Son funciones puras para poder
/// probarlas sin Firestore.
abstract final class ConductReportPlan {
  /// Revisa las condiciones con los datos actuales (T 7.1.5) y que no
  /// exista ya un reporte del residente para la incidencia (T 7.1.6).
  /// Lanza un [ConductReportFailure] si no se puede.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? reporter,
    required String technicianId,
    required bool alreadyReported,
  }) {
    if (reporter == null || reporter['rol'] != UserRole.resident.value) {
      throw ConductReportFailure.notResident;
    }
    if (reporter['estadoCuenta'] != AccountStatus.active.value) {
      throw ConductReportFailure.accountNotActive;
    }
    if (incident == null) throw ConductReportFailure.incidentNotFound;

    final housingId = (reporter['viviendaId'] as String?)?.trim() ?? '';
    if (housingId.isEmpty || housingId != incident['viviendaId']) {
      throw ConductReportFailure.notYourIncident;
    }
    if (incident['estado'] != IncidentStatus.resolved.value) {
      throw ConductReportFailure.notResolved;
    }
    final attendedBy = (incident['tecnicoId'] as String?)?.trim() ?? '';
    if (attendedBy.isEmpty) throw ConductReportFailure.noTechnician;
    if (attendedBy != technicianId) {
      throw ConductReportFailure.notAttendingTechnician;
    }
    if (alreadyReported) throw ConductReportFailure.duplicate;
  }

  /// Reporte nuevo, siempre Pendiente de revisión (T 7.1.7). Los nombres y
  /// el folio de la incidencia se copian para que el administrador los vea
  /// aunque después cambien.
  static ConductReportModel build({
    required String id,
    required int folio,
    required String incidentId,
    required Map<String, dynamic> incident,
    required String reporterId,
    required Map<String, dynamic> reporter,
    required String technicianId,
    required Map<String, dynamic>? technician,
    required ConductReason reason,
    required String description,
    required List<String> evidence,
  }) => ConductReportModel(
    id: id,
    folio: folio,
    incidentId: incidentId,
    incidentFolio: (incident['folio'] as num?)?.toInt() ?? 0,
    incidentTitle: incident['nombre'] as String? ?? '',
    reporterId: reporterId,
    reporterName: reporter['nombre'] as String? ?? '',
    reporterRole: UserRole.resident,
    reportedId: technicianId,
    reportedName: technician?['nombre'] as String? ?? 'Técnico',
    reportedRole: UserRole.technician,
    reason: reason,
    description: description.trim(),
    evidence: evidence,
    status: ConductReportStatus.pendingReview,
  );

  /// Aviso para cada administrador de que hay un reporte por revisar
  /// (T 7.1.8).
  static List<Map<String, dynamic>> notices({
    required Iterable<String> adminIds,
    required ConductReport report,
  }) => NotificationNotices.conductReport(
    adminIds: adminIds,
    reportId: report.id,
    reportedName: report.reportedName,
    reportedRole: report.reportedRole,
    reason: '${report.reason.label} (incidencia ${report.incidentNumber})',
  );
}
