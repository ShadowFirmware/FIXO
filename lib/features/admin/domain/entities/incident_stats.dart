import '../../../incidents/domain/entities/incident.dart';
import 'history_incident.dart';

/// Estadísticas de las incidencias de un periodo (HU-4.12).
class IncidentStats {
  const IncidentStats({
    required this.total,
    this.byType = const {},
    this.byStatus = const {},
  });

  static const empty = IncidentStats(total: 0);

  /// Calcula las estadísticas de las incidencias del periodo.
  factory IncidentStats.from(List<HistoryIncident> records) {
    final byType = {for (final type in IncidentType.values) type: 0};
    final byStatus = {for (final status in IncidentStatus.values) status: 0};
    for (final record in records) {
      final incident = record.incident;
      byType[incident.type] = byType[incident.type]! + 1;
      byStatus[incident.status] = byStatus[incident.status]! + 1;
    }
    return IncidentStats(
      total: records.length,
      byType: byType,
      byStatus: byStatus,
    );
  }

  /// Incidencias creadas en el periodo.
  final int total;

  /// Cuántas hay de cada tipo, incluidos los que no tienen ninguna.
  final Map<IncidentType, int> byType;

  /// Cuántas hay en cada estado, incluidos los que no tienen ninguna.
  final Map<IncidentStatus, int> byStatus;

  bool get isEmpty => total == 0;

  int countOf(IncidentStatus status) => byStatus[status] ?? 0;
}
