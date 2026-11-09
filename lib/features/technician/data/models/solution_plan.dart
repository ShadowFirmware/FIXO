import 'package:cloud_firestore/cloud_firestore.dart';

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

  static const resolvedType = 'incidencia_resuelta';

  /// La incidencia pasa a Resuelta con la solución y las evidencias del
  /// trabajo. La fecha de resolución la pone el servidor.
  static Map<String, dynamic> incidentUpdate({
    required String solution,
    required List<String> evidenceUrls,
  }) => {
    'estado': IncidentStatus.resolved.value,
    'solucion': solution.trim(),
    'evidenciasDespues': evidenceUrls,
    'fechaResolucion': FieldValue.serverTimestamp(),
  };

  /// El técnico vuelve a estar Disponible: se le había marcado como No
  /// disponible al asignarle la incidencia (HU-4.9).
  static const technicianUpdate = <String, dynamic>{'disponible': true};

  /// Aviso para el residente y cada administrador de que la incidencia se
  /// resolvió, con la solución resumida.
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
        '$technicianName resolvió "$title". Solución: ${_shorten(solution)}',
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
