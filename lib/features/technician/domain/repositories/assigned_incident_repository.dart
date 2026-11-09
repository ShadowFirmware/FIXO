import '../../../incidents/domain/entities/evidence_file.dart';
import '../entities/assigned_incident.dart';

abstract interface class AssignedIncidentRepository {
  /// Emite las incidencias asignadas al técnico [technicianId], en
  /// cualquier estado, cada vez que alguna cambia. Los errores llegan como
  /// `IncidentFailure`.
  Stream<List<AssignedIncident>> watchByTechnician(String technicianId);

  /// Emite la incidencia [id] cada vez que cambia, o `null` si no existe.
  /// Los errores llegan como `IncidentFailure`.
  Stream<AssignedIncident?> watchById(String id);

  /// Pasa la incidencia [incidentId] de Asignada a En proceso y avisa al
  /// residente (HU-3.4). Si no se puede, lanza un `IncidentFailure`.
  Future<void> startAttention({
    required String incidentId,
    required String technicianId,
  });

  /// Sube las evidencias del trabajo y registra la solución de la
  /// incidencia [incidentId] (HU-3.6). La incidencia sigue En proceso hasta
  /// que se finaliza (HU-3.7). Si no se puede, lanza un `IncidentFailure`.
  Future<void> registerSolution({
    required String incidentId,
    required String technicianId,
    required String solution,
    required List<EvidenceFile> evidence,
  });

  /// Finaliza la incidencia [incidentId] como resuelta (HU-3.7). Si no se
  /// puede, lanza un `IncidentFailure`.
  Future<void> finalize({
    required String incidentId,
    required String technicianId,
  });
}
