import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../data/repositories/incident_admin_repository_impl.dart';
import '../../domain/entities/history_incident.dart';
import '../../domain/entities/incident_stats.dart';
import '../../domain/entities/stats_period.dart';
import '../../domain/repositories/incident_admin_repository.dart';

enum StatsState { loading, loaded, error }

/// ViewModel del dashboard de estadísticas de incidencias (HU-4.12).
///
/// Escucha en Firestore las incidencias creadas en el periodo
/// seleccionado; al cambiar de periodo deja de escuchar el anterior.
class IncidentStatsViewModel extends ChangeNotifier {
  IncidentStatsViewModel({
    IncidentAdminRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? IncidentAdminRepositoryImpl(),
       _clock = clock ?? DateTime.now {
    _period = StatsPeriod.week(_clock());
  }

  final IncidentAdminRepository _repository;
  final DateTime Function() _clock;
  StreamSubscription<List<HistoryIncident>>? _subscription;
  bool _started = false;
  bool _disposed = false;

  StatsState _state = StatsState.loading;
  StatsState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HistoryIncident> _incidents = const [];

  /// Incidencias creadas en el periodo seleccionado.
  List<HistoryIncident> get incidents => _incidents;

  IncidentStats _stats = IncidentStats.empty;

  /// Estadísticas del periodo seleccionado.
  IncidentStats get stats => _stats;

  static const noIncidentsMessage = 'No hay incidencias en este periodo.';
  static const noAssignmentsMessage =
      'Ninguna incidencia del periodo tiene técnico asignado.';

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

  void start() {
    if (_started) return;
    _started = true;
    _listen();
  }

  void _setPeriod(StatsPeriod period) {
    if (period == _period) return;
    _period = period;
    if (_started) _listen();
    _notify();
  }

  void _listen() {
    _subscription?.cancel();
    _state = StatsState.loading;
    _errorMessage = null;
    _subscription = _repository
        .watchPeriod(_period.start, _period.end)
        .listen(_onIncidents, onError: _onError);
  }

  void _onIncidents(List<HistoryIncident> incidents) {
    _incidents = List.unmodifiable(incidents);
    _stats = IncidentStats.from(incidents);
    _errorMessage = null;
    _state = StatsState.loaded;
    _notify();
  }

  void _onError(Object error) {
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.statsLoadFailed.message;
    _state = StatsState.error;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
