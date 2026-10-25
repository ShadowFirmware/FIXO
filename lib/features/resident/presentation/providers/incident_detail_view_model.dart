import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../incidents/data/repositories/incident_repository_impl.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';

enum IncidentDetailState { loading, loaded, notFound, error }

/// ViewModel de la pantalla de detalle de una incidencia (HU-2.4).
///
/// Escucha la incidencia en Firestore, así que la pantalla se actualiza
/// sola cuando cambia su estado.
class IncidentDetailViewModel extends ChangeNotifier {
  IncidentDetailViewModel({
    required String incidentId,
    IncidentRepository? incidents,
  }) : _incidents = incidents ?? IncidentRepositoryImpl() {
    _subscription = _incidents
        .watchById(incidentId)
        .listen(_onIncident, onError: _onError);
  }

  final IncidentRepository _incidents;
  late final StreamSubscription<Incident?> _subscription;

  IncidentDetailState _state = IncidentDetailState.loading;
  IncidentDetailState get state => _state;

  Incident? _incident;
  Incident? get incident => _incident;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _onIncident(Incident? incident) {
    _incident = incident;
    _errorMessage = null;
    _state = incident == null
        ? IncidentDetailState.notFound
        : IncidentDetailState.loaded;
    notifyListeners();
  }

  void _onError(Object error) {
    _incident = null;
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.loadFailed.message;
    _state = IncidentDetailState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
