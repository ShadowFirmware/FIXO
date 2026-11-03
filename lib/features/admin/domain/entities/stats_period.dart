import '../../../../core/utils/date_formats.dart';

/// Tipo de periodo de las estadísticas (HU-4.12).
enum StatsPeriodKind {
  week('Semanal'),
  month('Mensual'),
  custom('Personalizado');

  const StatsPeriodKind(this.label);

  final String label;
}

/// Periodo de consulta: desde [start] (incluido) hasta [end] (excluido),
/// ambos a medianoche.
class StatsPeriod {
  const StatsPeriod._(this.kind, this.start, this.end);

  /// Semana de lunes a domingo que contiene [date].
  factory StatsPeriod.week(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day - date.weekday + 1);
    return StatsPeriod._(
      StatsPeriodKind.week,
      monday,
      DateTime(monday.year, monday.month, monday.day + 7),
    );
  }

  /// Mes calendario que contiene [date].
  factory StatsPeriod.month(DateTime date) => StatsPeriod._(
    StatsPeriodKind.month,
    DateTime(date.year, date.month),
    DateTime(date.year, date.month + 1),
  );

  /// Rango personalizado; ambos días se incluyen completos. Lanza
  /// [ArgumentError] si no es válido (ver [validateCustom]).
  factory StatsPeriod.custom(DateTime from, DateTime to) {
    final invalid = validateCustom(from, to);
    if (invalid != null) throw ArgumentError(invalid);
    return StatsPeriod._(
      StatsPeriodKind.custom,
      DateTime(from.year, from.month, from.day),
      DateTime(to.year, to.month, to.day + 1),
    );
  }

  /// Periodo del mismo tipo que contiene [date]. Un rango personalizado se
  /// convierte en la semana de [date].
  factory StatsPeriod.of(StatsPeriodKind kind, DateTime date) => switch (kind) {
    StatsPeriodKind.month => StatsPeriod.month(date),
    _ => StatsPeriod.week(date),
  };

  /// Días que puede abarcar un rango personalizado.
  static const maxCustomDays = 366;

  /// Valida un rango personalizado; devuelve el error o `null`.
  static String? validateCustom(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      return 'La fecha final no puede ser anterior a la inicial';
    }
    if (end.difference(start).inDays + 1 > maxCustomDays) {
      return 'El rango no puede ser mayor a $maxCustomDays días';
    }
    return null;
  }

  final StatsPeriodKind kind;
  final DateTime start;
  final DateTime end;

  /// Último día incluido en el periodo.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  /// El periodo anterior o siguiente del mismo tipo. Un rango
  /// personalizado se recorre por su misma cantidad de días.
  StatsPeriod shift(int direction) => switch (kind) {
    StatsPeriodKind.week => StatsPeriod.week(
      DateTime(start.year, start.month, start.day + 7 * direction),
    ),
    StatsPeriodKind.month => StatsPeriod.month(
      DateTime(start.year, start.month + direction),
    ),
    StatsPeriodKind.custom => StatsPeriod._(
      kind,
      DateTime(start.year, start.month, start.day + _days * direction),
      DateTime(end.year, end.month, end.day + _days * direction),
    ),
  };

  int get _days => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  /// Si el periodo ya incluye el día [today], no tiene caso avanzar.
  bool reaches(DateTime today) =>
      !end.isBefore(DateTime(today.year, today.month, today.day + 1));

  /// "Noviembre 2026" o "27 oct 2026 – 2 nov 2026".
  String get label => kind == StatsPeriodKind.month
      ? DateFormats.monthYear(start)
      : '${DateFormats.shortDate(start)} – ${DateFormats.shortDate(lastDay)}';

  @override
  bool operator ==(Object other) =>
      other is StatsPeriod &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}
