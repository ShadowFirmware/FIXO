import '../../../incidents/domain/entities/incident.dart';
import 'history_incident.dart';

/// Estadísticas de las incidencias de un periodo (HU-4.12).
class IncidentStats {
  const IncidentStats({
    required this.total,
    this.byType = const {},
    this.byStatus = const {},
    this.byTechnician = const [],
  });

  static const empty = IncidentStats(total: 0);

  /// Calcula las estadísticas de las incidencias del periodo.
  factory IncidentStats.from(List<HistoryIncident> records) {
    final byType = {for (final type in IncidentType.values) type: 0};
    final byStatus = {for (final status in IncidentStatus.values) status: 0};
    final loads = <String, TechnicianLoad>{};
    for (final record in records) {
      final incident = record.incident;
      byType[incident.type] = byType[incident.type]! + 1;
      byStatus[incident.status] = byStatus[incident.status]! + 1;

      final technicianId = incident.technicianId ?? '';
      if (technicianId.isEmpty) continue;
      final load = loads[technicianId];
      final resolved = incident.status == IncidentStatus.resolved ? 1 : 0;
      loads[technicianId] = TechnicianLoad(
        technicianId: technicianId,
        name: load?.name ?? record.technicianName ?? 'Sin registrar',
        assigned: (load?.assigned ?? 0) + 1,
        resolved: (load?.resolved ?? 0) + resolved,
      );
    }
    final byTechnician = loads.values.toList()
      ..sort((a, b) {
        final byCount = b.assigned.compareTo(a.assigned);
        return byCount != 0
            ? byCount
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return IncidentStats(
      total: records.length,
      byType: byType,
      byStatus: byStatus,
      byTechnician: byTechnician,
    );
  }

  /// Incidencias creadas en el periodo.
  final int total;

  /// Cuántas hay de cada tipo, incluidos los que no tienen ninguna.
  final Map<IncidentType, int> byType;

  /// Cuántas hay en cada estado, incluidos los que no tienen ninguna.
  final Map<IncidentStatus, int> byStatus;

  /// Técnicos con incidencias asignadas en el periodo, de más a menos.
  final List<TechnicianLoad> byTechnician;

  bool get isEmpty => total == 0;

  int countOf(IncidentStatus status) => byStatus[status] ?? 0;

  /// Incidencias del periodo que tienen técnico asignado.
  int get assignedCount =>
      byTechnician.fold(0, (sum, load) => sum + load.assigned);
}

/// Incidencias asignadas a un técnico en el periodo.
class TechnicianLoad {
  const TechnicianLoad({
    required this.technicianId,
    required this.name,
    required this.assigned,
    required this.resolved,
  });

  final String technicianId;
  final String name;

  /// Incidencias que tiene o tuvo asignadas, en cualquier estado.
  final int assigned;

  /// Cuántas de ellas ya resolvió.
  final int resolved;
}
