import 'package:flutter/foundation.dart';

import '../../domain/entities/incident_stats.dart';
import '../../domain/entities/stats_period.dart';

enum StatsState { loading, loaded, error }

/// ViewModel del dashboard de estadísticas de incidencias (HU-4.12).
class IncidentStatsViewModel extends ChangeNotifier {
  IncidentStatsViewModel({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _period = StatsPeriod.week(_clock());
  }

  final DateTime Function() _clock;

  final StatsState _state = StatsState.loaded;
  StatsState get state => _state;

  final String? _errorMessage = null;
  String? get errorMessage => _errorMessage;

  final IncidentStats _stats = IncidentStats.empty;

  /// Estadísticas del periodo seleccionado.
  IncidentStats get stats => _stats;

  static const noIncidentsMessage = 'No hay incidencias en este periodo.';

  late StatsPeriod _period;

  /// Periodo seleccionado; al abrir, la semana actual.
  StatsPeriod get period => _period;

  /// Cambia a la semana o al mes actual. El rango personalizado se elige
  /// con [setCustomRange].
  void selectKind(StatsPeriodKind kind) {
    if (kind == StatsPeriodKind.custom || kind == _period.kind) return;
    _setPeriod(StatsPeriod.of(kind, _clock()));
  }

  /// Elige un rango personalizado. Devuelve el error si no es válido, y en
  /// ese caso no lo aplica.
  String? setCustomRange(DateTime from, DateTime to) {
    final invalid = StatsPeriod.validateCustom(from, to);
    if (invalid != null) return invalid;
    _setPeriod(StatsPeriod.custom(from, to));
    return null;
  }

  void previous() => _setPeriod(_period.shift(-1));

  /// No se avanza más allá del periodo que incluye hoy.
  bool get canGoNext => !_period.reaches(_clock());

  void next() {
    if (canGoNext) _setPeriod(_period.shift(1));
  }

  void start() {}

  void _setPeriod(StatsPeriod period) {
    if (period == _period) return;
    _period = period;
    notifyListeners();
  }
}
