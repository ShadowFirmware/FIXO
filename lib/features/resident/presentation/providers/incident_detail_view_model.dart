import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../../incidents/data/repositories/incident_repository_impl.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';
import '../../../technician/data/repositories/technician_repository_impl.dart';
import '../../../technician/domain/repositories/technician_repository.dart';

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
    TechnicianRepository? technicians,
  }) : _incidents = incidents ?? IncidentRepositoryImpl(),
       _housings = housings ?? HousingRepositoryImpl(),
       _technicians = technicians ?? TechnicianRepositoryImpl() {
    _subscription = _incidents
        .watchById(incidentId)
        .listen(_onIncident, onError: _onError);
  }

  static const _noData = 'Sin registrar';

  final IncidentRepository _incidents;
  final HousingRepository _housings;
  final TechnicianRepository _technicians;
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

  /// El técnico se muestra desde que se asigna. En una incidencia rechazada
  /// nunca se muestra, aunque el documento tenga datos de técnico.
  bool get showTechnician => switch (_incident?.status) {
    IncidentStatus.assigned ||
    IncidentStatus.inProgress ||
    IncidentStatus.resolved => _incident!.technicianId != null,
    _ => false,
  };

  AppUser? _technician;
  String? _loadedTechnicianId;
  bool _technicianFailed = false;

  String get technicianName {
    if (_technician != null) return _technician!.name;
    return _technicianFailed ? 'No disponible' : 'Cargando…';
  }

  String get technicianPhone {
    final phone = _technician?.phone.trim() ?? '';
    return phone.isEmpty ? _noData : phone;
  }

  String get technicianSpecialty {
    final specialty = _technician?.specialty?.trim() ?? '';
    if (specialty.isEmpty) return _noData;
    return specialty[0].toUpperCase() + specialty.substring(1);
  }

  /// Hora estimada de llegada, solo si existe y el técnico se muestra.
  String? get estimatedArrival {
    final date = _incident?.estimatedTime;
    if (!showTechnician || date == null) return null;
    return DateFormats.dateTime(date);
  }

  bool get isResolved => _incident?.status == IncidentStatus.resolved;
  bool get isRejected => _incident?.status == IncidentStatus.rejected;

  String get solution {
    final text = _incident?.solution?.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get resolvedAt {
    final date = _incident?.resolvedAt;
    return date == null ? _noData : DateFormats.dateTime(date);
  }

  List<String> get evidenceAfter => _incident?.evidenceAfter ?? const [];

  String get rejectionComment {
    final text = _incident?.rejectionComment?.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get rejectedAt {
    final date = _incident?.rejectedAt;
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
    final technicianId = showTechnician ? incident!.technicianId : null;
    if (technicianId != _loadedTechnicianId) _loadTechnician(technicianId);
    notifyListeners();
  }

  Future<void> _loadTechnician(String? technicianId) async {
    _loadedTechnicianId = technicianId;
    _technician = null;
    _technicianFailed = false;
    if (technicianId == null) return;

    AppUser? technician;
    try {
      technician = await _technicians.getById(technicianId);
    } catch (_) {
      technician = null;
    }
    if (_disposed || technicianId != _loadedTechnicianId) return;
    _technician = technician;
    _technicianFailed = technician == null;
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
