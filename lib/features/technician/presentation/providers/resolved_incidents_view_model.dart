import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/watch_resolved_incidents.dart';

enum ResolvedIncidentsState { loading, loaded, error }

/// ViewModel del historial del técnico (HU-3.6).
///
/// Escucha las incidencias en Firestore, así que una incidencia aparece en
/// cuanto el técnico registra su solución.
class ResolvedIncidentsViewModel extends ChangeNotifier {
  ResolvedIncidentsViewModel({
    AuthSession? session,
    AssignedIncidentRepository? repository,
  }) {
    _subscription =
        WatchResolvedIncidents(repository ?? AssignedIncidentRepositoryImpl())(
          technician: (session ?? AuthSession.instance).currentUser,
        ).listen(_onIncidents, onError: _onError);
  }

  late final StreamSubscription<List<AssignedIncident>> _subscription;

  ResolvedIncidentsState _state = ResolvedIncidentsState.loading;
  ResolvedIncidentsState get state => _state;

  List<AssignedIncident> _incidents = const [];

  /// Incidencias que el técnico resolvió.
  List<AssignedIncident> get incidents => _incidents;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const noIncidentsMessage =
      'Aún no has resuelto incidencias. Cuando registres una solución, '
      'aparecerá aquí.';

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
        : IncidentFailure.assignedLoadFailed.message;
    _state = ResolvedIncidentsState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
