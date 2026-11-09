import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../entities/assigned_incident.dart';
import '../repositories/assigned_incident_repository.dart';

/// Historial de incidencias atendidas (HU-3.8): las que el técnico
/// autenticado finalizó como resueltas, con su solución, de la resuelta más
/// recientemente a la más antigua.
class WatchResolvedIncidents {
  const WatchResolvedIncidents(this._repository);

  final AssignedIncidentRepository _repository;

  Stream<List<AssignedIncident>> call({required AppUser? technician}) {
    if (technician?.role != UserRole.technician) {
      return Stream.error(IncidentFailure.assignedAccessDenied);
    }
    final uid = technician!.uid;

    // La consulta ya trae solo las resueltas; se revisa de nuevo por si
    // llegara otra.
    return _repository.watchResolved(uid).map((incidents) {
      final resolved = [
        for (final item in incidents)
          if (item.incident.technicianId == uid &&
              item.status == IncidentStatus.resolved)
            item,
      ];
      return resolved..sort(newestResolvedFirst);
    });
  }

  /// Las que aún no tienen la fecha del servidor van primero.
  static int newestResolvedFirst(AssignedIncident a, AssignedIncident b) {
    final aDate = a.incident.resolvedAt;
    final bDate = b.incident.resolvedAt;
    if (aDate == null || bDate == null) {
      return (aDate == null ? 0 : 1) - (bDate == null ? 0 : 1);
    }
    final byDate = bDate.compareTo(aDate);
    return byDate != 0 ? byDate : b.incident.folio.compareTo(a.incident.folio);
  }
}
