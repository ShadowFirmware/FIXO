/// Fechas en español sin depender del paquete `intl`.
abstract final class DateFormats {
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// "9 de octubre de 2026".
  static String longDate(DateTime date) =>
      '${date.day} de ${_months[date.month - 1]} de ${date.year}';

  /// "4:05 p. m.".
  static String time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'a. m.' : 'p. m.';
    return '$hour:$minute $period';
  }

  /// "9 de octubre de 2026, 4:05 p. m.".
  static String dateTime(DateTime date) => '${longDate(date)}, ${time(date)}';
}
