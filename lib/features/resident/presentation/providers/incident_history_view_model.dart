import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../../incidents/data/repositories/incident_repository_impl.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/entities/incident_filter.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';
import '../../../incidents/domain/usecases/watch_resident_incidents.dart';

enum IncidentHistoryState { loading, loaded, error }

/// ViewModel del historial de incidencias (HU-2.5).
///
/// Escucha las incidencias del departamento del residente, así que el
/// historial se actualiza solo cuando se registra o cambia una incidencia.
class IncidentHistoryViewModel extends ChangeNotifier {
  IncidentHistoryViewModel({
    AuthSession? session,
    IncidentRepository? incidents,
    HousingRepository? housings,
  }) : _housings = housings ?? HousingRepositoryImpl() {
    final resident = (session ?? AuthSession.instance).currentUser;
    _subscription = WatchResidentIncidents(
      incidents ?? IncidentRepositoryImpl(),
    )(resident: resident).listen(_onIncidents, onError: _onError);

    final housingId = resident?.housingId?.trim() ?? '';
    if (housingId.isNotEmpty) _loadHousing(housingId);
  }

  final HousingRepository _housings;
  late final StreamSubscription<List<Incident>> _subscription;
  bool _disposed = false;

  IncidentHistoryState _state = IncidentHistoryState.loading;
  IncidentHistoryState get state => _state;

  /// Todas las incidencias del departamento, de la más reciente a la más
  /// antigua.
  List<Incident> _incidents = const [];
  List<Incident> get incidents => _incidents;

  IncidentFilter _filter = IncidentFilter.none;
  IncidentFilter get filter => _filter;

  /// Incidencias que cumplen los filtros seleccionados.
  List<Incident> get results => _filter.apply(_incidents);

  void setQuery(String query) => _setFilter(
    IncidentFilter(
      query: query,
      status: _filter.status,
      type: _filter.type,
      from: _filter.from,
      to: _filter.to,
    ),
  );

  void setStatus(IncidentStatus? status) => _setFilter(
    IncidentFilter(
      query: _filter.query,
      status: status,
      type: _filter.type,
      from: _filter.from,
      to: _filter.to,
    ),
  );

  void setType(IncidentType? type) => _setFilter(
    IncidentFilter(
      query: _filter.query,
      status: _filter.status,
      type: type,
      from: _filter.from,
      to: _filter.to,
    ),
  );

  void setDateRange({DateTime? from, DateTime? to}) => _setFilter(
    IncidentFilter(
      query: _filter.query,
      status: _filter.status,
      type: _filter.type,
      from: from,
      to: to,
    ),
  );

  void clearFilters() => _setFilter(IncidentFilter.none);

  static const noIncidentsMessage =
      'Aún no hay incidencias registradas en tu departamento.';
  static const noResultsMessage =
      'No se encontraron incidencias con los filtros seleccionados.';

  /// Mensaje cuando la lista queda vacía, o `null` si hay resultados.
  String? get emptyMessage {
    if (_state != IncidentHistoryState.loaded) return null;
    if (_incidents.isEmpty) return noIncidentsMessage;
    return results.isEmpty ? noResultsMessage : null;
  }

  void _setFilter(IncidentFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Departamento del residente, por ejemplo "Torre A – 4B", o `null`
  /// mientras se carga.
  String? _housing;
  String? get housing => _housing;

  void _onIncidents(List<Incident> incidents) {
    _incidents = List.unmodifiable(incidents);
    _errorMessage = null;
    _state = IncidentHistoryState.loaded;
    notifyListeners();
  }

  void _onError(Object error) {
    _incidents = const [];
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.historyLoadFailed.message;
    _state = IncidentHistoryState.error;
    notifyListeners();
  }

  Future<void> _loadHousing(String housingId) async {
    String? label;
    try {
      label = (await _housings.getById(housingId))?.label;
    } catch (_) {
      label = null;
    }
    if (_disposed || label == null) return;
    _housing = label;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
