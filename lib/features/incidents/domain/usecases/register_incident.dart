import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../entities/incident.dart';
import '../entities/new_incident.dart';
import '../repositories/incident_repository.dart';

/// Registra una incidencia del residente autenticado (HU-2.3).
class RegisterIncident {
  const RegisterIncident(this._repository, [this._housings]);

  final IncidentRepository _repository;

  /// Si se indica, se revisa que la vivienda siga activa (HU-4.7).
  final HousingRepository? _housings;

  /// La vivienda se toma del perfil del residente: no puede elegir otra.
  Future<Incident> call({
    required AppUser resident,
    required NewIncident data,
  }) async {
    if (resident.role != UserRole.resident) {
      throw IncidentFailure.notResident;
    }
    final housingId = resident.housingId?.trim() ?? '';
    if (housingId.isEmpty) throw IncidentFailure.noHousing;

    // Una vivienda inactiva no admite incidencias nuevas; las que ya
    // estaban abiertas siguen su flujo normal.
    final housings = _housings;
    if (housings != null) {
      final housing = await housings.getById(housingId);
      if (housing == null || !housing.active) {
        throw IncidentFailure.inactiveHousing;
      }
    }

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
