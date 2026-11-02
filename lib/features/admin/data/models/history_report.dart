import '../../../../core/utils/date_formats.dart';
import '../../domain/entities/admin_history_filter.dart';
import '../../domain/entities/history_incident.dart';

/// Contenido del reporte del historial (HU-4.11), separado del formato
/// PDF para poder probarlo sin generar el archivo.
abstract final class HistoryReport {
  static const title = 'Historial de incidencias';

  static const headers = [
    'No. reporte',
    'Nombre',
    'Tipo',
    'Estado',
    'Detalles',
    'Evidencias',
    'Departamento',
    'Reportó',
    'Técnico',
    'Creación',
    'Resolución',
  ];

  /// Hasta cuántos caracteres de los detalles caben en la tabla.
  static const maxDetails = 120;

  /// Una fila por incidencia, en el orden de [headers].
  static List<List<String>> rows(List<HistoryIncident> records) => [
    for (final record in records) row(record),
  ];

  static List<String> row(HistoryIncident record) {
    final incident = record.incident;
    return [
      incident.reportNumber,
      incident.title,
      incident.type.label,
      incident.status.label,
      _truncate(incident.description.trim(), maxDetails),
      'Antes: ${incident.evidenceBefore.length} · '
          'Después: ${incident.evidenceAfter.length}',
      record.housingLabel,
      record.reporterName,
      record.technicianName ?? 'Sin asignar',
      _date(incident.createdAt),
      _date(incident.resolvedAt),
    ];
  }

  /// Filtros aplicados, para que el reporte diga qué incluye.
  /// [technicianName] y [housingLabel] traducen los identificadores.
  static List<String> filterLines(
    AdminHistoryFilter filter, {
    String? technicianName,
    String? housingLabel,
  }) {
    if (filter.isEmpty) {
      return const ['Filtros: ninguno (todas las incidencias)'];
    }
    final from = filter.from;
    final to = filter.to;
    return [
      if (filter.status != null) 'Estado: ${filter.status!.label}',
      if (filter.type != null) 'Tipo: ${filter.type!.label}',
      if (filter.technicianId != null)
        'Técnico: ${technicianName ?? 'Sin registrar'}',
      if (filter.housingId != null)
        'Departamento: ${housingLabel ?? 'Sin registrar'}',
      if (filter.hasDateRange)
        'Fecha de creación: '
            '${from == null ? 'cualquiera' : DateFormats.shortDate(from)} – '
            '${to == null ? 'hoy' : DateFormats.shortDate(to)}',
    ];
  }

  /// "Generado el 2 de noviembre de 2026, 4:05 p. m. · 12 incidencias".
  static String generatedLine(DateTime now, int count) =>
      'Generado el ${DateFormats.dateTime(now)} · '
      '${count == 1 ? '1 incidencia' : '$count incidencias'}';

  /// Nombre del archivo, por ejemplo "historial-incidencias-2026-11-02.pdf".
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'historial-incidencias-${now.year}-${two(now.month)}-'
        '${two(now.day)}.pdf';
  }

  static const _replacements = {
    '–': '-',
    '—': '-',
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
    '…': '...',
  };

  /// Las fuentes estándar del PDF solo tienen los caracteres Latin-1
  /// (incluye acentos y ñ). Los guiones largos, comillas tipográficas y
  /// puntos suspensivos se cambian por su equivalente simple, y lo demás
  /// (por ejemplo emojis) por "?", para que no desaparezca sin aviso.
  static String pdfSafe(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_replacements[char] ?? (rune <= 0xFF ? char : '?'));
    }
    return buffer.toString();
  }

  static String _date(DateTime? date) =>
      date == null ? '-' : DateFormats.shortDate(date);

  static String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 1)}…';
}
