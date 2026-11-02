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
    this.from,
    this.to,
  });

  static const none = AdminHistoryFilter();

  final IncidentStatus? status;
  final IncidentType? type;

  /// UID del técnico asignado.
  final String? technicianId;

  /// Vivienda (departamento) donde se reportó.
  final String? housingId;

  /// Rango de fechas de creación; ambos días se incluyen completos.
  final DateTime? from;
  final DateTime? to;

  bool get hasDateRange => from != null || to != null;

  /// Cuántos filtros están activos. El rango de fechas cuenta como uno.
  int get activeCount =>
      [
        status,
        type,
        technicianId,
        housingId,
      ].where((value) => value != null).length +
      (hasDateRange ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  /// Copia con los campos indicados. Cada uno se pasa como función para
  /// poder quitar un filtro, por ejemplo `copyWith(type: () => null)`.
  AdminHistoryFilter copyWith({
    IncidentStatus? Function()? status,
    IncidentType? Function()? type,
    String? Function()? technicianId,
    String? Function()? housingId,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => AdminHistoryFilter(
    status: status == null ? this.status : status(),
    type: type == null ? this.type : type(),
    technicianId: technicianId == null ? this.technicianId : technicianId(),
    housingId: housingId == null ? this.housingId : housingId(),
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
  );

  /// Valida un rango de fechas; devuelve el error o `null`.
  static String? validateDateRange(DateTime? from, DateTime? to) {
    if (from != null && to != null && _day(to).isBefore(_day(from))) {
      return 'La fecha final no puede ser anterior a la inicial';
    }
    return null;
  }

  bool matches(HistoryIncident record) {
    final incident = record.incident;
    if (status != null && incident.status != status) return false;
    if (type != null && incident.type != type) return false;
    if (technicianId != null && incident.technicianId != technicianId) {
      return false;
    }
    if (housingId != null && incident.housingId != housingId) return false;
    return !hasDateRange || _inRange(incident.createdAt);
  }

  /// Las incidencias sin fecha de creación no entran en ningún rango.
  bool _inRange(DateTime? createdAt) {
    if (createdAt == null) return false;
    if (from case final from? when createdAt.isBefore(_day(from))) {
      return false;
    }
    if (to case final to?
        when !createdAt.isBefore(DateTime(to.year, to.month, to.day + 1))) {
      return false;
    }
    return true;
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<HistoryIncident> apply(List<HistoryIncident> records) =>
      isEmpty ? records : records.where(matches).toList();
}
