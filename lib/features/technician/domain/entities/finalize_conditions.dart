import '../../../../core/errors/incident_failure.dart';
import '../../../incidents/domain/entities/incident.dart';

/// Condiciones para finalizar una incidencia como resuelta (HU-3.7): debe
/// estar asignada al técnico, En proceso y con la solución registrada.
abstract final class FinalizeConditions {
  /// Por qué [technicianId] no puede finalizar [incident], o `null` si
  /// puede. La transacción las revisa de nuevo al guardar.
  static IncidentFailure? check(
    Incident incident, {
    required String? technicianId,
  }) {
    if (technicianId == null || incident.technicianId != technicianId) {
      return IncidentFailure.notAssignedToYou;
    }
    return switch (incident.status) {
      IncidentStatus.inProgress
          when incident.solution?.trim().isNotEmpty ?? false =>
        null,
      IncidentStatus.inProgress => IncidentFailure.solutionRequired,
      IncidentStatus.resolved => IncidentFailure.incidentAlreadyFinalized,
      IncidentStatus.pending ||
      IncidentStatus.assigned ||
      IncidentStatus.rejected => IncidentFailure.finalizeNotAvailable,
    };
  }
}
