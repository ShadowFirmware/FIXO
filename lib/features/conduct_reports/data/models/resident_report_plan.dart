import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/conduct_report.dart';
import 'conduct_report_model.dart';
import 'conduct_report_plan.dart';

/// Reglas para registrar el reporte de conducta de un técnico contra un
/// residente de una incidencia (HU-7.2), aplicadas sobre los documentos que
/// se leen dentro de la transacción. Son funciones puras para poder
/// probarlas sin Firestore.
abstract final class ResidentReportPlan {
  /// Revisa las condiciones con los datos actuales (T 7.2.5) y que no
  /// exista ya un reporte del técnico contra ese residente en la
  /// incidencia (T 7.2.6). Lanza un [ConductReportFailure] si no se puede.
  ///
  /// [wroteInChat] indica si [residentId] envió mensajes en el chat de la
  /// incidencia: los mensajes no se borran (HU-5.1), así que se puede
  /// consultar antes de la transacción.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? reporter,
    required String reporterId,
    required Map<String, dynamic>? resident,
    required String residentId,
    required bool wroteInChat,
    required bool alreadyReported,
  }) {
    if (reporter == null || reporter['rol'] != UserRole.technician.value) {
      throw ConductReportFailure.notTechnician;
    }
    if (reporter['estadoCuenta'] != AccountStatus.active.value) {
      throw ConductReportFailure.accountNotActive;
    }
    if (incident == null) throw ConductReportFailure.incidentNotFound;
    if (incident['tecnicoId'] != reporterId) {
      throw ConductReportFailure.notYourAttendedIncident;
    }
    if (incident['estado'] != IncidentStatus.resolved.value) {
      throw ConductReportFailure.residentNotResolved;
    }
    // Solo el residente que registró la incidencia o que escribió en su
    // chat.
    final registered = incident['creadaPor'] == residentId;
    if (resident == null ||
        resident['rol'] != UserRole.resident.value ||
        !(registered || wroteInChat)) {
      throw ConductReportFailure.notParticipant;
    }
    if (alreadyReported) throw ConductReportFailure.duplicateResident;
  }

  /// Reporte nuevo, siempre Pendiente de revisión (T 7.2.7). Los nombres y
  /// el folio de la incidencia se copian para que el administrador los vea
  /// aunque después cambien.
  static ConductReportModel build({
    required String id,
    required int folio,
    required String incidentId,
    required Map<String, dynamic> incident,
    required String reporterId,
    required Map<String, dynamic> reporter,
    required String residentId,
    required Map<String, dynamic> resident,
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
    reporterRole: UserRole.technician,
    reportedId: residentId,
    reportedName: (resident['nombre'] as String?)?.trim().isNotEmpty == true
        ? (resident['nombre'] as String).trim()
        : 'Residente',
    reportedRole: UserRole.resident,
    reason: reason,
    description: description.trim(),
    evidence: evidence,
    status: ConductReportStatus.pendingReview,
  );

  /// Aviso para cada administrador de que hay un reporte por revisar
  /// (T 7.2.8). Es el mismo aviso que el de la HU-7.1, con el rol del
  /// residente.
  static List<Map<String, dynamic>> notices({
    required Iterable<String> adminIds,
    required ConductReport report,
  }) => ConductReportPlan.notices(adminIds: adminIds, report: report);

  /// Residentes que el técnico puede reportar: el que registró la
  /// incidencia y quienes escribieron en su chat, sin repetir y sin los
  /// que ya reportó. [chatAuthors] son los autores residentes del chat
  /// (UID → nombre); [registeredName] es el nombre de quien la registró.
  static List<ReportableResident> reportable({
    required String createdBy,
    required String? registeredName,
    required Map<String, String> chatAuthors,
    Set<String> alreadyReported = const {},
  }) {
    final residents = <ReportableResident>[
      if (createdBy.trim().isNotEmpty)
        ReportableResident(
          id: createdBy,
          name: _name(registeredName ?? chatAuthors[createdBy]),
          registeredIncident: true,
          wroteInChat: chatAuthors.containsKey(createdBy),
        ),
      for (final MapEntry(key: id, value: name) in chatAuthors.entries)
        if (id != createdBy && id.trim().isNotEmpty)
          ReportableResident(id: id, name: _name(name), wroteInChat: true),
    ];
    return [
      for (final resident in residents)
        if (!alreadyReported.contains(resident.id)) resident,
    ];
  }

  static String _name(String? name) {
    final text = name?.trim() ?? '';
    return text.isEmpty ? 'Residente' : text;
  }
}
