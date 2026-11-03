/// Estadísticas de las incidencias de un periodo (HU-4.12).
class IncidentStats {
  const IncidentStats({required this.total});

  static const empty = IncidentStats(total: 0);

  /// Incidencias creadas en el periodo.
  final int total;

  bool get isEmpty => total == 0;
}
