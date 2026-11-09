import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../repositories/assigned_incident_repository.dart';

/// Finalizar una incidencia como resuelta (HU-3.7): pasa de En proceso a
/// Resuelta. Solo puede hacerlo el técnico asignado, con su cuenta activa,
/// y la incidencia debe tener la solución registrada.
class FinalizeIncident {
  const FinalizeIncident(this._repository);

  final AssignedIncidentRepository _repository;

  /// Si no se puede, lanza un [IncidentFailure].
  Future<void> call({
    required AppUser? technician,
    required String incidentId,
  }) async {
    if (technician?.role != UserRole.technician) {
      throw IncidentFailure.assignedAccessDenied;
    }
    // Se revisa de nuevo en la transacción, por si cambió mientras tanto.
    if (technician!.accountStatus != AccountStatus.active) {
      throw IncidentFailure.technicianCannotAttend;
    }
    await _repository.finalize(
      incidentId: incidentId,
      technicianId: technician.uid,
    );
  }
}
