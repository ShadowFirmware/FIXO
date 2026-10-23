import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/incident.dart';
import '../entities/new_incident.dart';
import '../repositories/incident_repository.dart';

/// Registra una incidencia del residente autenticado (HU-2.3).
class RegisterIncident {
  const RegisterIncident(this._repository);

  final IncidentRepository _repository;

  /// La vivienda se toma del perfil del residente: no puede elegir otra.
  Future<Incident> call({
    required AppUser resident,
    required NewIncident data,
  }) {
    if (resident.role != UserRole.resident) {
      throw IncidentFailure.notResident;
    }
    final housingId = resident.housingId?.trim() ?? '';
    if (housingId.isEmpty) throw IncidentFailure.noHousing;

    return _repository.register(
      data: NewIncident(
        title: data.title.trim(),
        type: data.type,
        description: data.description.trim(),
        evidence: data.evidence,
      ),
      residentId: resident.uid,
      housingId: housingId,
    );
  }
}
