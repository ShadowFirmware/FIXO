import '../../../auth/domain/entities/app_user.dart';
import '../entities/pending_incident.dart';

abstract interface class IncidentAdminRepository {
  /// Emite las incidencias en estado "Pendiente", de la más antigua a la
  /// más reciente, cada vez que alguna cambia (HU-4.8). Las que cambian de
  /// estado dejan de emitirse. Los errores llegan como `IncidentFailure`.
  Stream<List<PendingIncident>> watchPending();

  /// Técnicos con cuenta activa y disponibles.
  Future<List<AppUser>> availableTechnicians();

  /// Asigna el técnico y la hora estimada. Lanza `IncidentFailure`.
  Future<void> assign({
    required String incidentId,
    required String technicianId,
    required DateTime estimatedTime,
  });

  /// Rechaza la incidencia con el motivo. Lanza `IncidentFailure`.
  Future<void> reject({required String incidentId, required String comment});
}
