import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

/// Historial de incidencias del residente (HU-2.5).
///
/// Incluye todas las incidencias de su departamento, también las que
/// reportaron residentes anteriores, de la más reciente a la más antigua.
class WatchResidentIncidents {
  const WatchResidentIncidents(this._repository);

  final IncidentRepository _repository;

  Stream<List<Incident>> call({required AppUser? resident}) {
    if (resident?.role != UserRole.resident) {
      return Stream.error(IncidentFailure.historyAccessDenied);
    }
    final housingId = resident!.housingId?.trim() ?? '';
    if (housingId.isEmpty) {
      return Stream.error(IncidentFailure.historyNoHousing);
    }

    return _repository.watchByHousing(housingId).map((incidents) {
      // Nunca se muestra una incidencia de otro departamento, aunque la
      // consulta la devolviera.
      final own = [
        for (final incident in incidents)
          if (incident.housingId == housingId) incident,
      ];
      return own..sort(_newestFirst);
    });
  }

  /// Una incidencia recién creada todavía no tiene la fecha del servidor:
  /// se considera la más reciente.
  static int _newestFirst(Incident a, Incident b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null || bDate == null) {
      return (aDate == null ? 0 : 1) - (bDate == null ? 0 : 1);
    }
    final byDate = bDate.compareTo(aDate);
    return byDate != 0 ? byDate : b.folio.compareTo(a.folio);
  }
}
