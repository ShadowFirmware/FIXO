import '../../../incidents/domain/entities/incident.dart';
import 'solution_plan.dart';
import 'start_attention_plan.dart';

/// La incidencia ya se finalizó como resuelta.
class IncidentAlreadyFinalizedException implements Exception {
  const IncidentAlreadyFinalizedException();
}

/// La incidencia está En proceso pero aún no tiene la solución registrada.
class SolutionRequiredException implements Exception {
  const SolutionRequiredException();
}

/// La incidencia no está En proceso (sigue Asignada, se rechazó o volvió a
/// quedar pendiente).
class FinalizeNotAvailableException implements Exception {
  const FinalizeNotAvailableException();
}

/// Reglas para finalizar una incidencia como resuelta (HU-3.7), aplicadas
/// sobre los documentos que se leen dentro de la transacción. Son funciones
/// puras para poder probarlas sin Firestore.
abstract final class FinalizePlan {
  /// Solo el técnico asignado, con su cuenta activa, puede finalizarla, y
  /// solo si está En proceso con la solución registrada.
  static void validate({
    required Map<String, dynamic>? incident,
    required Map<String, dynamic>? technician,
    required String technicianId,
    required DateTime now,
  }) {
    if (incident == null || incident['tecnicoId'] != technicianId) {
      throw const NotAssignedToTechnicianException();
    }
    if (!StartAttentionPlan.canAttend(technician, now: now)) {
      throw const TechnicianCannotAttendException();
    }
    switch (IncidentStatus.fromValue(incident['estado'] as String?)) {
      case IncidentStatus.inProgress:
        if (!SolutionPlan.hasSolution(incident)) {
          throw const SolutionRequiredException();
        }
      case IncidentStatus.resolved:
        throw const IncidentAlreadyFinalizedException();
      case IncidentStatus.pending ||
          IncidentStatus.assigned ||
          IncidentStatus.rejected ||
          null:
        throw const FinalizeNotAvailableException();
    }
  }

  /// La incidencia pasa de En proceso a Resuelta.
  static Map<String, dynamic> get incidentUpdate => {
    'estado': IncidentStatus.resolved.value,
  };
}
