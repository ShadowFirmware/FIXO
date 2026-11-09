import '../../../incidents/domain/entities/incident.dart';
import 'start_attention_plan.dart';

/// La incidencia ya tiene una solución registrada.
class SolutionAlreadyRegisteredException implements Exception {
  const SolutionAlreadyRegisteredException();
}

/// La incidencia sigue Asignada: primero hay que comenzar su atención.
class AttentionNotStartedException implements Exception {
  const AttentionNotStartedException();
}

/// La incidencia ya no está En proceso por otra razón (por ejemplo, fue
/// rechazada o volvió a quedar pendiente).
class SolutionNotAvailableException implements Exception {
  const SolutionNotAvailableException();
}

/// Reglas para registrar la solución de una incidencia (HU-3.6), aplicadas
/// sobre los documentos que se leen dentro de la transacción. Son funciones
/// puras para poder probarlas sin Firestore.
abstract final class SolutionPlan {
  /// Solo el técnico asignado, con su cuenta activa, puede registrarla, y
  /// solo si la incidencia está En proceso.
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
    throwIfNotInProgress(
      IncidentStatus.fromValue(incident['estado'] as String?),
    );
  }

  /// Lanza la excepción que corresponde si [status] no es En proceso.
  static void throwIfNotInProgress(IncidentStatus? status) {
    switch (status) {
      case IncidentStatus.inProgress:
        return;
      case IncidentStatus.resolved:
        throw const SolutionAlreadyRegisteredException();
      case IncidentStatus.assigned:
        throw const AttentionNotStartedException();
      case IncidentStatus.pending || IncidentStatus.rejected || null:
        throw const SolutionNotAvailableException();
    }
  }
}
