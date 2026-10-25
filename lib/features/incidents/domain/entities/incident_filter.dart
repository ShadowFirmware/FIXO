import 'incident.dart';

/// Filtros del historial de incidencias (HU-2.5). Un campo `null` o vacío
/// no filtra.
class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.status,
    this.type,
    this.from,
    this.to,
  });

  static const none = IncidentFilter();

  /// Texto a buscar en el número de reporte o en el nombre.
  final String query;

  final IncidentStatus? status;
  final IncidentType? type;

  /// Rango de fechas de creación; ambos días se incluyen completos.
  final DateTime? from;
  final DateTime? to;

  bool get hasDateRange => from != null || to != null;

  bool get isEmpty =>
      query.trim().isEmpty && status == null && type == null && !hasDateRange;

  /// Filtros del panel (tipo y fechas), para el contador del botón.
  int get panelCount => (type == null ? 0 : 1) + (hasDateRange ? 1 : 0);

  bool matches(Incident incident) {
    if (status != null && incident.status != status) return false;
    if (type != null && incident.type != type) return false;

    if (hasDateRange) {
      final createdAt = incident.createdAt;
      if (createdAt == null) return false;
      if (from case final from?
          when createdAt.isBefore(DateTime(from.year, from.month, from.day))) {
        return false;
      }
      if (to case final to?
          when !createdAt.isBefore(DateTime(to.year, to.month, to.day + 1))) {
        return false;
      }
    }

    final text = _normalize(query);
    if (text.isEmpty) return true;
    return _normalize(
      '${incident.reportNumber} ${incident.folio} ${incident.title}',
    ).contains(text);
  }

  List<Incident> apply(List<Incident> incidents) =>
      isEmpty ? incidents : incidents.where(matches).toList();

  static const _accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  };

  /// Minúsculas y sin acentos, para que "baño" encuentre "Baño" y
  /// "electrico" encuentre "Eléctrico".
  static String _normalize(String text) => text
      .trim()
      .toLowerCase()
      .split('')
      .map((char) => _accents[char] ?? char)
      .join();
}
