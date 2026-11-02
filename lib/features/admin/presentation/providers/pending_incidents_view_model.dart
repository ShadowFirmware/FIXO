import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/incident_admin_repository_impl.dart';
import '../../domain/entities/pending_incident.dart';
import '../../domain/repositories/incident_admin_repository.dart';

/// ViewModel de las incidencias pendientes de asignación (HU-4.8).
///
/// Escucha Firestore: cuando una incidencia se asigna o se rechaza deja de
/// estar pendiente y desaparece sola de la lista.
class PendingIncidentsViewModel extends ChangeNotifier {
  PendingIncidentsViewModel({IncidentAdminRepository? repository})
    : _repository = repository ?? IncidentAdminRepositoryImpl();

  /// Cuántas se muestran en el inicio del administrador.
  static const previewCount = 3;

  final IncidentAdminRepository _repository;
  StreamSubscription<List<PendingIncident>>? _subscription;
  bool _disposed = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<PendingIncident> _all = const [];

  /// Todas las pendientes, de la más antigua a la más reciente.
  List<PendingIncident> get all => _all;

  IncidentType? _typeFilter;
  IncidentType? get typeFilter => _typeFilter;

  /// Pendientes que cumplen el filtro por tipo.
  List<PendingIncident> get incidents => _typeFilter == null
      ? _all
      : _all.where((p) => p.incident.type == _typeFilter).toList();

  /// Las [previewCount] más antiguas, para el inicio.
  List<PendingIncident> get preview => _all.take(previewCount).toList();

  bool get hasMore => _all.length > previewCount;

  void start() {
    if (_subscription != null) return;
    _subscription = _repository.watchPending().listen(
      (incidents) {
        _all = incidents;
        _isLoading = false;
        _errorMessage = null;
        _notify();
      },
      onError: (Object e) {
        _isLoading = false;
        _errorMessage = e is IncidentFailure
            ? e.message
            : IncidentFailure.pendingLoadFailed.message;
        _notify();
      },
    );
  }

  void setTypeFilter(IncidentType? type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _notify();
  }

  Future<List<AppUser>> availableTechnicians() =>
      _repository.availableTechnicians();

  /// Valida el comentario de rechazo; devuelve el error o `null`.
  static String? validateRejection(String comment) {
    final text = comment.trim();
    if (text.isEmpty) return 'Escribe el motivo del rechazo';
    if (text.length > 500) return 'El motivo no debe exceder 500 caracteres';
    return null;
  }

  /// Valida los datos de asignación; devuelve el error o `null`.
  static String? validateAssignment({
    String? technicianId,
    DateTime? estimatedTime,
    DateTime? now,
  }) {
    if (technicianId == null) return 'Selecciona un técnico';
    return validateEstimatedTime(estimatedTime, now: now);
  }

  /// Valida la hora estimada de llegada; devuelve el error o `null`.
  static String? validateEstimatedTime(
    DateTime? estimatedTime, {
    DateTime? now,
  }) {
    if (estimatedTime == null) return 'Selecciona la hora estimada de llegada';
    if (estimatedTime.isBefore(now ?? DateTime.now())) {
      return 'La hora estimada no puede ser en el pasado';
    }
    return null;
  }

  Future<bool> assign(
    PendingIncident pending, {
    required String? technicianId,
    required DateTime? estimatedTime,
  }) => _run(
    () => _repository.assign(
      incidentId: pending.id,
      technicianId: technicianId!,
      estimatedTime: estimatedTime!,
    ),
    invalid: validateAssignment(
      technicianId: technicianId,
      estimatedTime: estimatedTime,
    ),
    success: 'Incidencia ${pending.incident.reportNumber} asignada.',
  );

  Future<bool> reject(PendingIncident pending, {required String comment}) =>
      _run(
        () => _repository.reject(incidentId: pending.id, comment: comment),
        invalid: validateRejection(comment),
        success: 'Incidencia ${pending.incident.reportNumber} rechazada.',
      );

  Future<bool> _run(
    Future<void> Function() action, {
    String? invalid,
    required String success,
  }) async {
    _errorMessage = null;
    _successMessage = null;
    if (invalid != null) {
      _errorMessage = invalid;
      _notify();
      return false;
    }
    _isSaving = true;
    _notify();
    try {
      await action();
      _successMessage = success;
      return true;
    } catch (e) {
      _errorMessage = e is IncidentFailure
          ? e.message
          : IncidentFailure.actionFailed.message;
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
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
