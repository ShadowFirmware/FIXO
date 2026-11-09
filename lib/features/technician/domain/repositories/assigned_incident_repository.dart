import '../entities/assigned_incident.dart';

abstract interface class AssignedIncidentRepository {
  /// Emite las incidencias asignadas al técnico [technicianId], en
  /// cualquier estado, cada vez que alguna cambia. Los errores llegan como
  /// `IncidentFailure`.
  Stream<List<AssignedIncident>> watchByTechnician(String technicianId);
}
