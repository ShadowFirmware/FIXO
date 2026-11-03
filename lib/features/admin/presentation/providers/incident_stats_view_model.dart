import 'package:flutter/foundation.dart';

import '../../domain/entities/incident_stats.dart';

enum StatsState { loading, loaded, error }

/// ViewModel del dashboard de estadísticas de incidencias (HU-4.12).
class IncidentStatsViewModel extends ChangeNotifier {
  final StatsState _state = StatsState.loaded;
  StatsState get state => _state;

  final String? _errorMessage = null;
  String? get errorMessage => _errorMessage;

  final IncidentStats _stats = IncidentStats.empty;

  /// Estadísticas del periodo seleccionado.
  IncidentStats get stats => _stats;

  static const noIncidentsMessage = 'No hay incidencias en este periodo.';

  void start() {}
}
