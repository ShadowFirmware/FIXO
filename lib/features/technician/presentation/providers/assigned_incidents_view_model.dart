import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';

enum AssignedIncidentsState { loading, loaded, error }

/// ViewModel de las incidencias asignadas al técnico (HU-3.3).
///
/// Escucha las incidencias en Firestore, así que la lista se actualiza
/// sola cuando el administrador asigna una nueva o cambia su estado.
class AssignedIncidentsViewModel extends ChangeNotifier {
  AssignedIncidentsViewModel({
    AuthSession? session,
    AssignedIncidentRepository? repository,
  }) {
    final technicianId =
        (session ?? AuthSession.instance).currentUser?.uid ?? '';
    _subscription = (repository ?? AssignedIncidentRepositoryImpl())
        .watchByTechnician(technicianId)
        .listen(_onIncidents, onError: _onError);
  }

  late final StreamSubscription<List<AssignedIncident>> _subscription;

  AssignedIncidentsState _state = AssignedIncidentsState.loading;
  AssignedIncidentsState get state => _state;

  List<AssignedIncident> _incidents = const [];

  /// Incidencias que el técnico tiene por atender.
  List<AssignedIncident> get incidents => _incidents;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _onIncidents(List<AssignedIncident> incidents) {
    _incidents = List.unmodifiable(incidents);
    _errorMessage = null;
    _state = AssignedIncidentsState.loaded;
    notifyListeners();
  }

  void _onError(Object error) {
    _incidents = const [];
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.assignedLoadFailed.message;
    _state = AssignedIncidentsState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
