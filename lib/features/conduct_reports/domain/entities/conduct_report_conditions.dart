import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';

/// Condiciones para que el residente reporte la conducta del técnico de una
/// incidencia (T 7.1.5). Son funciones puras para poder probarlas sin
/// Firestore; la transacción las vuelve a revisar con los datos actuales.
abstract final class ConductReportConditions {
  /// Por qué [resident] no puede reportar al técnico de [incident], o
  /// `null` si puede. No revisa si ya existe un reporte (T 7.1.6).
  static ConductReportFailure? check(
    Incident incident, {
    required AppUser? resident,
  }) {
    if (resident == null || resident.role != UserRole.resident) {
      return ConductReportFailure.notResident;
    }
    if (resident.accountStatus != AccountStatus.active) {
      return ConductReportFailure.accountNotActive;
    }
    final housingId = resident.housingId?.trim() ?? '';
    if (housingId.isEmpty || housingId != incident.housingId) {
      return ConductReportFailure.notYourIncident;
    }
    // Mientras la incidencia esté Pendiente, Asignada o En proceso (o si se
    // rechazó) no se puede reportar.
    if (incident.status != IncidentStatus.resolved) {
      return ConductReportFailure.notResolved;
    }
    if (incident.technicianId?.trim().isEmpty ?? true) {
      return ConductReportFailure.noTechnician;
    }
    return null;
  }

  /// Igual que [check], y además que [technicianId] sea el técnico que
  /// atendió la incidencia.
  static ConductReportFailure? checkTarget(
    Incident incident, {
    required AppUser? resident,
    required String technicianId,
  }) =>
      check(incident, resident: resident) ??
      (incident.technicianId == technicianId
          ? null
          : ConductReportFailure.notAttendingTechnician);
}
