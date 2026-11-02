import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/incident_admin_repository_impl.dart';
import '../../domain/entities/admin_history_filter.dart';
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

  AdminHistoryFilter _filter = AdminHistoryFilter.none;
  AdminHistoryFilter get filter => _filter;

  /// Incidencias que cumplen los filtros seleccionados.
  List<HistoryIncident> get results => _filter.apply(_incidents);

  void setStatus(IncidentStatus? status) =>
      _setFilter(_filter.copyWith(status: () => status));

  void setType(IncidentType? type) =>
      _setFilter(_filter.copyWith(type: () => type));

  void setTechnician(String? technicianId) =>
      _setFilter(_filter.copyWith(technicianId: () => technicianId));

  void setHousing(String? housingId) =>
      _setFilter(_filter.copyWith(housingId: () => housingId));

  /// Filtra por fecha de creación. Sin fechas, quita el filtro. Devuelve
  /// el error si el rango no es válido, y en ese caso no lo aplica.
  String? setDateRange({DateTime? from, DateTime? to}) {
    final invalid = AdminHistoryFilter.validateDateRange(from, to);
    if (invalid != null) return invalid;
    _setFilter(_filter.copyWith(from: () => from, to: () => to));
    return null;
  }

  void clearFilters() => _setFilter(AdminHistoryFilter.none);

  void _setFilter(AdminHistoryFilter filter) {
    _filter = filter;
    _notify();
  }

  /// Técnicos que tienen incidencias asignadas, por nombre: (UID, nombre).
  List<(String, String)> get technicianOptions => _options(
    (r) => r.incident.technicianId,
    (r) => r.technicianName ?? 'Sin registrar',
    selected: _filter.technicianId,
  );

  /// Departamentos con incidencias, por nombre: (id, nombre).
  List<(String, String)> get housingOptions => _options(
    (r) => r.incident.housingId,
    (r) => r.housingLabel,
    selected: _filter.housingId,
  );

  /// Opciones sin repetir. La seleccionada siempre aparece, aunque ya no
  /// tenga incidencias, para que el filtro se pueda ver y quitar.
  List<(String, String)> _options(
    String? Function(HistoryIncident) idOf,
    String Function(HistoryIncident) labelOf, {
    String? selected,
  }) {
    final labels = <String, String>{};
    for (final record in _incidents) {
      final id = idOf(record) ?? '';
      if (id.isEmpty) continue;
      labels.putIfAbsent(id, () => labelOf(record));
    }
    if (selected != null) labels.putIfAbsent(selected, () => 'Sin registrar');
    return [for (final e in labels.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase()));
  }

  /// Cuántas incidencias hay en cada estado, incluidos los que no tienen
  /// ninguna.
  Map<IncidentStatus, int> get statusCounts {
    final counts = {for (final status in IncidentStatus.values) status: 0};
    for (final record in _incidents) {
      counts[record.incident.status] = counts[record.incident.status]! + 1;
    }
    return counts;
  }

  static const noIncidentsMessage = 'Aún no hay incidencias registradas.';
  static const noResultsMessage =
      'No se encontraron incidencias con los filtros seleccionados.';

  /// Mensaje cuando la lista queda vacía, o `null` si hay resultados.
  String? get emptyMessage {
    if (_state != AdminHistoryState.loaded) return null;
    if (_incidents.isEmpty) return noIncidentsMessage;
    return results.isEmpty ? noResultsMessage : null;
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
