import 'package:cloud_firestore/cloud_firestore.dart';

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

  static const resolvedType = 'incidencia_resuelta';

  /// La incidencia pasa de En proceso a Resuelta con la fecha de resolución,
  /// que pone el servidor, y su chat se cierra: ya no se pueden enviar
  /// mensajes (HU-5.1).
  static Map<String, dynamic> get incidentUpdate => {
    'estado': IncidentStatus.resolved.value,
    'fechaResolucion': FieldValue.serverTimestamp(),
    'chatCerrado': true,
  };

  /// El técnico vuelve a estar Disponible para recibir nuevas asignaciones:
  /// se le marcó como No disponible al asignarle la incidencia (HU-4.9).
  static const technicianUpdate = <String, dynamic>{'disponible': true};

  /// Aviso de que la incidencia se resolvió, para el residente (que puede
  /// consultar la solución y las evidencias) y para cada administrador.
  static Map<String, dynamic> notice({
    required String userId,
    required String incidentId,
    required String reportNumber,
    required String title,
    required String technicianName,
    required String solution,
  }) => {
    'usuarioId': userId,
    'tipo': resolvedType,
    'titulo': 'Incidencia $reportNumber resuelta',
    'mensaje':
        '$technicianName resolvió "$title". Solución: ${_shorten(solution)} '
        'Consulta la solución y las evidencias en el detalle.',
    'refId': incidentId,
    'leida': false,
    'fecha': FieldValue.serverTimestamp(),
  };

  static const _maxSolution = 200;

  static String _shorten(String text) {
    final solution = text.trim();
    return solution.length <= _maxSolution
        ? solution
        : '${solution.substring(0, _maxSolution).trimRight()}…';
  }
}
