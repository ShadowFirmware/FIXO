import '../../../incidents/domain/entities/incident.dart';
import 'history_incident.dart';

/// Filtros del historial del administrador (HU-4.11). Un campo `null` no
/// filtra.
class AdminHistoryFilter {
  const AdminHistoryFilter({
    this.status,
    this.type,
    this.technicianId,
    this.housingId,
  });

  static const none = AdminHistoryFilter();

  final IncidentStatus? status;
  final IncidentType? type;

  /// UID del técnico asignado.
  final String? technicianId;

  /// Vivienda (departamento) donde se reportó.
  final String? housingId;

  /// Cuántos filtros están activos.
  int get activeCount => [
    status,
    type,
    technicianId,
    housingId,
  ].where((value) => value != null).length;

  bool get isEmpty => activeCount == 0;

  /// Copia con los campos indicados. Cada uno se pasa como función para
  /// poder quitar un filtro, por ejemplo `copyWith(type: () => null)`.
  AdminHistoryFilter copyWith({
    IncidentStatus? Function()? status,
    IncidentType? Function()? type,
    String? Function()? technicianId,
    String? Function()? housingId,
  }) => AdminHistoryFilter(
    status: status == null ? this.status : status(),
    type: type == null ? this.type : type(),
    technicianId: technicianId == null ? this.technicianId : technicianId(),
    housingId: housingId == null ? this.housingId : housingId(),
  );

  bool matches(HistoryIncident record) {
    final incident = record.incident;
    if (status != null && incident.status != status) return false;
    if (type != null && incident.type != type) return false;
    if (technicianId != null && incident.technicianId != technicianId) {
      return false;
    }
    if (housingId != null && incident.housingId != housingId) return false;
    return true;
  }

  List<HistoryIncident> apply(List<HistoryIncident> records) =>
      isEmpty ? records : records.where(matches).toList();
}
