import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
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
