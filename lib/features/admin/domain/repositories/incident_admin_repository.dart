import '../../../auth/domain/entities/app_user.dart';
import '../entities/history_incident.dart';
import '../entities/pending_incident.dart';

abstract interface class IncidentAdminRepository {
  /// Emite las incidencias en estado "Pendiente", de la más antigua a la
  /// más reciente, cada vez que alguna cambia (HU-4.8). Las que cambian de
  /// estado dejan de emitirse. Los errores llegan como `IncidentFailure`.
  Stream<List<PendingIncident>> watchPending();

  /// Emite todas las incidencias, sin importar su estado, cada vez que
  /// alguna cambia (HU-4.11). Los errores llegan como `IncidentFailure`.
  Stream<List<HistoryIncident>> watchHistory();

  /// Emite las incidencias creadas desde [start] (incluido) hasta [end]
  /// (excluido) cada vez que alguna cambia (HU-4.12). Los errores llegan
  /// como `IncidentFailure`.
  Stream<List<HistoryIncident>> watchPeriod(DateTime start, DateTime end);

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
