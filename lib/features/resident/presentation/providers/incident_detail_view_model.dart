import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
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
    HousingRepository? housings,
  }) : _incidents = incidents ?? IncidentRepositoryImpl(),
       _housings = housings ?? HousingRepositoryImpl() {
    _subscription = _incidents
        .watchById(incidentId)
        .listen(_onIncident, onError: _onError);
  }

  static const _noData = 'Sin registrar';

  final IncidentRepository _incidents;
  final HousingRepository _housings;
  late final StreamSubscription<Incident?> _subscription;
  bool _disposed = false;

  IncidentDetailState _state = IncidentDetailState.loading;
  IncidentDetailState get state => _state;

  Incident? _incident;
  Incident? get incident => _incident;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Departamento de la incidencia, por ejemplo "Torre A – 4B".
  String _housing = 'Cargando…';
  String get housing => _housing;
  String? _loadedHousingId;

  String get type => _incident?.type.label ?? _noData;

  String get description {
    final text = _incident?.description.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get createdAt {
    final date = _incident?.createdAt;
    return date == null ? _noData : DateFormats.dateTime(date);
  }

  void _onIncident(Incident? incident) {
    _incident = incident;
    _errorMessage = null;
    _state = incident == null
        ? IncidentDetailState.notFound
        : IncidentDetailState.loaded;
    if (incident != null && incident.housingId != _loadedHousingId) {
      _loadHousing(incident.housingId);
    }
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

  Future<void> _loadHousing(String housingId) async {
    _loadedHousingId = housingId;
    _housing = 'Cargando…';
    String label;
    try {
      label = (await _housings.getById(housingId))?.label ?? 'No disponible';
    } catch (_) {
      label = 'No disponible';
    }
    if (_disposed || housingId != _loadedHousingId) return;
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
