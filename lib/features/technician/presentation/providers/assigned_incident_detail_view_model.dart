import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/watch_assigned_incident.dart';

enum AssignedIncidentDetailState { loading, loaded, notFound, error }

/// ViewModel del detalle de una incidencia asignada (HU-3.3).
///
/// Escucha la incidencia en Firestore, así que la pantalla se actualiza
/// sola cuando cambia su estado o la hora estimada de llegada.
class AssignedIncidentDetailViewModel extends ChangeNotifier {
  AssignedIncidentDetailViewModel({
    required String incidentId,
    AuthSession? session,
    AssignedIncidentRepository? repository,
  }) {
    // Solo se reciben los datos si la incidencia es del técnico en sesión.
    _subscription =
        WatchAssignedIncident(repository ?? AssignedIncidentRepositoryImpl())(
          technician: (session ?? AuthSession.instance).currentUser,
          id: incidentId,
        ).listen(_onIncident, onError: _onError);
  }

  static const _noData = 'Sin registrar';

  late final StreamSubscription<AssignedIncident?> _subscription;

  AssignedIncidentDetailState _state = AssignedIncidentDetailState.loading;
  AssignedIncidentDetailState get state => _state;

  AssignedIncident? _item;
  AssignedIncident? get item => _item;
  Incident? get incident => _item?.incident;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// `true` si la incidencia es de otro técnico.
  bool _accessDenied = false;
  bool get isAccessDenied => _accessDenied;

  String get type => incident?.type.label ?? _noData;
  String get housing => _item?.housingLabel ?? _noData;
  String get residentName => _item?.residentName ?? _noData;
  String get residentPhone => _item?.residentPhone ?? _noData;

  String get description {
    final text = incident?.description.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get createdAt => _date(incident?.createdAt);
  String get estimatedArrival => _date(incident?.estimatedTime);

  /// La incidencia ya se resolvió: dejó la lista de asignadas y está en el
  /// historial.
  bool get isResolved => incident?.status == IncidentStatus.resolved;

  String get solution {
    final text = incident?.solution?.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get resolvedAt => _date(incident?.resolvedAt);

  static String _date(DateTime? date) =>
      date == null ? _noData : DateFormats.dateTime(date);

  void _onIncident(AssignedIncident? item) {
    _item = item;
    _errorMessage = null;
    _accessDenied = false;
    _state = item == null
        ? AssignedIncidentDetailState.notFound
        : AssignedIncidentDetailState.loaded;
    notifyListeners();
  }

  void _onError(Object error) {
    // No se conserva nada de una incidencia que el técnico no puede ver.
    _item = null;
    _accessDenied = identical(error, IncidentFailure.notAssignedToYou);
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.loadFailed.message;
    _state = AssignedIncidentDetailState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
