import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../repositories/assigned_incident_repository.dart';

/// Comenzar la atención de una incidencia asignada (HU-3.4): pasa de
/// Asignada a En proceso. Solo puede hacerlo el técnico asignado.
class StartAttention {
  const StartAttention(this._repository);

  final AssignedIncidentRepository _repository;

  /// Si no se puede, lanza un [IncidentFailure].
  Future<void> call({
    required AppUser? technician,
    required String incidentId,
  }) async {
    if (technician?.role != UserRole.technician) {
      throw IncidentFailure.assignedAccessDenied;
    }
    await _repository.startAttention(
      incidentId: incidentId,
      technicianId: technician!.uid,
    );
  }
}
