import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/watch_resolved_incidents.dart';

enum ResolvedIncidentsState { loading, loaded, error }

/// ViewModel del historial de incidencias atendidas (HU-3.8).
///
/// Escucha las incidencias en Firestore, así que una incidencia aparece en
/// cuanto el técnico la finaliza.
class ResolvedIncidentsViewModel extends ChangeNotifier {
  ResolvedIncidentsViewModel({
    AuthSession? session,
    AssignedIncidentRepository? repository,
  }) : _session = session ?? AuthSession.instance,
       _watch = WatchResolvedIncidents(
         repository ?? AssignedIncidentRepositoryImpl(),
       ) {
    _listen();
  }

  final AuthSession _session;
  final WatchResolvedIncidents _watch;
  StreamSubscription<List<AssignedIncident>>? _subscription;

  ResolvedIncidentsState _state = ResolvedIncidentsState.loading;
  ResolvedIncidentsState get state => _state;

  List<AssignedIncident> _incidents = const [];

  /// Incidencias que el técnico atendió, de la resuelta más recientemente a
  /// la más antigua.
  List<AssignedIncident> get incidents => _incidents;

  IncidentType? _type;

  /// Tipo seleccionado, o `null` para todos.
  IncidentType? get type => _type;

  DateTime? _from;
  DateTime? _to;

  /// Rango de fechas de resolución; ambos días se incluyen completos.
  DateTime? get from => _from;
  DateTime? get to => _to;
  bool get hasDateRange => _from != null || _to != null;

  bool get hasFilters => _type != null || hasDateRange;

  void setType(IncidentType? type) {
    if (type == _type) return;
    _type = type;
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    _from = from == null ? null : DateTime(from.year, from.month, from.day);
    _to = to == null ? null : DateTime(to.year, to.month, to.day);
    notifyListeners();
  }

  void clearFilters() {
    if (!hasFilters) return;
    _type = null;
    _from = null;
    _to = null;
    notifyListeners();
  }

  /// Incidencias que cumplen los filtros de tipo y fecha de resolución.
  List<AssignedIncident> get results =>
      hasFilters ? _incidents.where(_matches).toList() : _incidents;

  bool _matches(AssignedIncident item) {
    final incident = item.incident;
    if (_type != null && incident.type != _type) return false;
    if (!hasDateRange) return true;

    final resolvedAt = incident.resolvedAt;
    if (resolvedAt == null) return false;
    if (_from case final from? when resolvedAt.isBefore(from)) return false;
    if (_to case final to?
        when !resolvedAt.isBefore(DateTime(to.year, to.month, to.day + 1))) {
      return false;
    }
    return true;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const noIncidentsMessage =
      'Aún no has atendido incidencias. Cuando finalices una, aparecerá '
      'aquí.';

  // Solo se reciben las incidencias del técnico en sesión.
  void _listen() {
    _subscription?.cancel();
    _subscription = _watch(
      technician: _session.currentUser,
    ).listen(_onIncidents, onError: _onError);
  }

  /// Vuelve a consultar el historial después de un error.
  void retry() {
    if (_state != ResolvedIncidentsState.error) return;
    _state = ResolvedIncidentsState.loading;
    _errorMessage = null;
    notifyListeners();
    _listen();
  }

  void _onIncidents(List<AssignedIncident> incidents) {
    _incidents = List.unmodifiable(incidents);
    _errorMessage = null;
    _state = ResolvedIncidentsState.loaded;
    notifyListeners();
  }

  void _onError(Object error) {
    _incidents = const [];
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.technicianHistoryLoadFailed.message;
    _state = ResolvedIncidentsState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
