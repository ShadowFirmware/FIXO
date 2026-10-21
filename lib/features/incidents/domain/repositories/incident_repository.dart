import '../entities/incident.dart';
import '../entities/new_incident.dart';

abstract interface class IncidentRepository {
  /// Guarda la incidencia y devuelve la versión guardada, con su folio.
  /// Si falla lanza un `IncidentFailure`.
  Future<Incident> register({
    required NewIncident data,
    required String residentId,
    required String housingId,
  });
}
