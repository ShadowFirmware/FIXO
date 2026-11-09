import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/assigned_incident.dart';
import '../repositories/assigned_incident_repository.dart';

/// Detalle de una incidencia asignada al técnico (HU-3.3).
///
/// El técnico solo puede consultar las incidencias que le asignaron: si es
/// de otro técnico, el stream emite [IncidentFailure.notAssignedToYou] en
/// lugar de los datos.
class WatchAssignedIncident {
  const WatchAssignedIncident(this._repository);

  final AssignedIncidentRepository _repository;

  Stream<AssignedIncident?> call({
    required AppUser? technician,
    required String id,
  }) {
    if (technician?.role != UserRole.technician) {
      return Stream.error(IncidentFailure.assignedAccessDenied);
    }

    return _repository.watchById(id).map((item) {
      if (item != null && item.incident.technicianId != technician!.uid) {
        throw IncidentFailure.notAssignedToYou;
      }
      return item;
    });
  }
}
