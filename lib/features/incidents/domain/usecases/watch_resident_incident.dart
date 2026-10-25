import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

/// Detalle de una incidencia para el residente (HU-2.4).
///
/// El residente solo puede consultar incidencias de su departamento: si la
/// incidencia es de otra vivienda, el stream emite
/// [IncidentFailure.accessDenied] en lugar de los datos.
class WatchResidentIncident {
  const WatchResidentIncident(this._repository);

  final IncidentRepository _repository;

  Stream<Incident?> call({required AppUser? resident, required String id}) {
    final housingId = resident?.housingId?.trim() ?? '';
    if (resident?.role != UserRole.resident || housingId.isEmpty) {
      return Stream.error(IncidentFailure.accessDenied);
    }

    return _repository.watchById(id).map((incident) {
      if (incident != null && incident.housingId != housingId) {
        throw IncidentFailure.accessDenied;
      }
      return incident;
    });
  }
}
