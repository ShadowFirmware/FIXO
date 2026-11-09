import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/start_attention.dart';
import '../../domain/usecases/watch_assigned_incidents.dart';

enum AssignedIncidentsState { loading, loaded, error }

/// ViewModel de las incidencias asignadas al técnico (HU-3.3 y HU-3.5).
///
/// Escucha las incidencias en Firestore, así que la lista se actualiza
/// sola cuando el administrador asigna una nueva o cambia su estado.
class AssignedIncidentsViewModel extends ChangeNotifier {
  AssignedIncidentsViewModel({
    AuthSession? session,
    AssignedIncidentRepository? repository,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? AssignedIncidentRepositoryImpl() {
    // Solo se reciben las incidencias del técnico en sesión.
    _subscription = WatchAssignedIncidents(_repository)(
      technician: _session.currentUser,
    ).listen(_onIncidents, onError: _onError);
  }

  final AuthSession _session;
  final AssignedIncidentRepository _repository;
  late final StreamSubscription<List<AssignedIncident>> _subscription;
  bool _disposed = false;

  final _starting = <String>{};

  /// Se está guardando el inicio de la atención de [item].
  bool isStarting(AssignedIncident item) => _starting.contains(item.id);

  /// La opción Comenzar atención solo está disponible mientras la
  /// incidencia está Asignada (HU-3.5).
  bool canStartAttention(AssignedIncident item) =>
      item.status == IncidentStatus.assigned && !isStarting(item);

  /// Pasa [item] a En proceso desde la lista. Devuelve el mensaje de error,
  /// o `null` si se guardó; la lista se actualiza sola con el nuevo estado.
  Future<String?> startAttention(AssignedIncident item) async {
    if (!canStartAttention(item)) return null;
    _starting.add(item.id);
    notifyListeners();
    try {
      await StartAttention(_repository)(
        technician: _session.currentUser,
        incidentId: item.id,
      );
      return null;
    } on IncidentFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return IncidentFailure.actionFailed.message;
    } finally {
      _starting.remove(item.id);
      if (!_disposed) notifyListeners();
    }
  }

  AssignedIncidentsState _state = AssignedIncidentsState.loading;
  AssignedIncidentsState get state => _state;

  List<AssignedIncident> _incidents = const [];

  /// Incidencias que el técnico tiene por atender.
  List<AssignedIncident> get incidents => _incidents;

  IncidentStatus? _statusFilter;

  /// Estado seleccionado, o `null` para mostrar todas.
  IncidentStatus? get statusFilter => _statusFilter;

  void setStatusFilter(IncidentStatus? status) {
    if (status == _statusFilter) return;
    _statusFilter = status;
    notifyListeners();
  }

  /// Incidencias del estado seleccionado.
  List<AssignedIncident> get results => _statusFilter == null
      ? _incidents
      : [
          for (final item in _incidents)
            if (item.status == _statusFilter) item,
        ];

  /// Cuántas incidencias hay en [status], o en total si es `null`.
  int countOf(IncidentStatus? status) => status == null
      ? _incidents.length
      : _incidents.where((item) => item.status == status).length;

  static const noIncidentsMessage =
      'No tienes incidencias asignadas por el momento. Cuando el '
      'administrador te asigne una, aparecerá aquí.';

  /// Mensaje cuando la lista queda vacía, o `null` si hay incidencias que
  /// mostrar.
  String? get emptyMessage {
    if (_state != AssignedIncidentsState.loaded) return null;
    if (_incidents.isEmpty) return noIncidentsMessage;
    if (results.isNotEmpty) return null;
    return 'No tienes incidencias en estado '
        '"${_statusFilter!.label}".';
  }

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
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
