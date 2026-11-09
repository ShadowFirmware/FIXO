import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/assigned_incident.dart';
import '../repositories/assigned_incident_repository.dart';

/// Incidencias asignadas al técnico autenticado (HU-3.3).
///
/// Solo un técnico puede consultarlas, y solo las suyas: una incidencia de
/// otro técnico nunca se muestra, aunque la consulta la devolviera.
class WatchAssignedIncidents {
  const WatchAssignedIncidents(this._repository);

  final AssignedIncidentRepository _repository;

  Stream<List<AssignedIncident>> call({required AppUser? technician}) {
    if (technician?.role != UserRole.technician) {
      return Stream.error(IncidentFailure.assignedAccessDenied);
    }
    final uid = technician!.uid;

    return _repository.watchByTechnician(uid).map((incidents) {
      final own = [
        for (final item in incidents)
          if (item.incident.technicianId == uid) item,
      ];
      return own..sort(compareByArrival);
    });
  }

  /// Primero la llegada estimada más próxima; las que no tienen hora van
  /// al final, de la más antigua a la más reciente.
  static int compareByArrival(AssignedIncident a, AssignedIncident b) {
    final aTime = a.incident.estimatedTime;
    final bTime = b.incident.estimatedTime;
    if (aTime != null && bTime != null) {
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
    } else if (aTime != null || bTime != null) {
      return aTime == null ? 1 : -1;
    }
    return a.incident.folio.compareTo(b.incident.folio);
  }
}
