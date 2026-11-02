import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../data/repositories/incident_admin_repository_impl.dart';
import '../../domain/entities/history_incident.dart';
import '../../domain/repositories/incident_admin_repository.dart';

enum AdminHistoryState { loading, loaded, error }

/// ViewModel del historial completo de incidencias (HU-4.11).
///
/// Escucha Firestore, así que el historial se actualiza solo cuando se
/// registra, asigna, rechaza o resuelve una incidencia.
class AdminIncidentHistoryViewModel extends ChangeNotifier {
  AdminIncidentHistoryViewModel({IncidentAdminRepository? repository})
    : _repository = repository ?? IncidentAdminRepositoryImpl();

  final IncidentAdminRepository _repository;
  StreamSubscription<List<HistoryIncident>>? _subscription;
  bool _disposed = false;

  AdminHistoryState _state = AdminHistoryState.loading;
  AdminHistoryState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HistoryIncident> _incidents = const [];

  /// Todas las incidencias registradas.
  List<HistoryIncident> get incidents => _incidents;

  /// Incidencias que se muestran.
  List<HistoryIncident> get results => _incidents;

  static const noIncidentsMessage = 'Aún no hay incidencias registradas.';

  /// Mensaje cuando la lista queda vacía, o `null` si hay resultados.
  String? get emptyMessage {
    if (_state != AdminHistoryState.loaded) return null;
    return _incidents.isEmpty ? noIncidentsMessage : null;
  }

  void start() {
    if (_subscription != null) return;
    _subscription = _repository.watchHistory().listen(
      (incidents) {
        _incidents = List.unmodifiable(incidents);
        _errorMessage = null;
        _state = AdminHistoryState.loaded;
        _notify();
      },
      onError: (Object e) {
        _incidents = const [];
        _errorMessage = e is IncidentFailure
            ? e.message
            : IncidentFailure.historyLoadFailed.message;
        _state = AdminHistoryState.error;
        _notify();
      },
    );
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
