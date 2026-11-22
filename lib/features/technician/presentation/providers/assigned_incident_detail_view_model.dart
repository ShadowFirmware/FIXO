import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../conduct_reports/data/repositories/conduct_report_repository_impl.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../../conduct_reports/domain/entities/conduct_report_conditions.dart';
import '../../../conduct_reports/domain/repositories/conduct_report_repository.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/entities/finalize_conditions.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/finalize_incident.dart';
import '../../domain/usecases/start_attention.dart';
import '../../domain/usecases/watch_assigned_incident.dart';

enum AssignedIncidentDetailState { loading, loaded, notFound, error }

/// ViewModel del detalle de una incidencia asignada (HU-3.3 y HU-3.4).
///
/// Escucha la incidencia en Firestore, así que la pantalla se actualiza
/// sola cuando cambia su estado o la hora estimada de llegada.
class AssignedIncidentDetailViewModel extends ChangeNotifier {
  AssignedIncidentDetailViewModel({
    required String incidentId,
    AssignedIncident? initial,
    AuthSession? session,
    AssignedIncidentRepository? repository,
    DateTime Function()? clock,
    ConductReportRepository? conductReports,
  }) : _incidentId = incidentId,
       _clock = clock ?? DateTime.now,
       _session = session ?? AuthSession.instance,
       _repository = repository ?? AssignedIncidentRepositoryImpl(),
       _conductReportsOverride = conductReports {
    // Al abrirla desde la lista se muestra de inmediato lo que ya se tiene,
    // mientras llegan los datos actualizados.
    if (initial != null && initial.id == incidentId) _onIncident(initial);
    _listen();
  }

  static const _noData = 'Sin registrar';

  final String _incidentId;
  final DateTime Function() _clock;
  final AuthSession _session;
  final AssignedIncidentRepository _repository;
  StreamSubscription<AssignedIncident?>? _subscription;
  bool _disposed = false;

  // Solo se reciben los datos si la incidencia es del técnico en sesión.
  void _listen() {
    _subscription?.cancel();
    _subscription = WatchAssignedIncident(_repository)(
      technician: _session.currentUser,
      id: _incidentId,
    ).listen(_onIncident, onError: _onError);
  }

  /// Vuelve a consultar la incidencia después de un error.
  void retry() {
    if (_state != AssignedIncidentDetailState.error) return;
    _state = AssignedIncidentDetailState.loading;
    _errorMessage = null;
    _accessDenied = false;
    notifyListeners();
    _listen();
  }

  bool _starting = false;

  /// Se está guardando el inicio de la atención.
  bool get isStarting => _starting;

  /// La opción Comenzar atención solo está disponible mientras la
  /// incidencia está Asignada.
  bool get canStartAttention =>
      _state == AssignedIncidentDetailState.loaded &&
      incident?.status == IncidentStatus.assigned;

  /// La solución se registra cuando la incidencia está En proceso (HU-3.6).
  bool get canRegisterSolution =>
      _state == AssignedIncidentDetailState.loaded &&
      incident?.status == IncidentStatus.inProgress &&
      !hasSolution;

  /// Con la solución registrada, la incidencia En proceso se puede
  /// finalizar (HU-3.7). Ver [FinalizeConditions].
  bool get canFinalize =>
      _state == AssignedIncidentDetailState.loaded &&
      FinalizeConditions.check(
            incident!,
            technicianId: _session.currentUser?.uid,
          ) ==
          null;

  bool _finalizing = false;

  /// Se está guardando la finalización.
  bool get isFinalizing => _finalizing;

  /// Finaliza la incidencia como resuelta (HU-3.7). Devuelve el mensaje de
  /// error, o `null` si se guardó.
  Future<String?> finalize() async {
    if (!canFinalize || _finalizing) return null;
    _finalizing = true;
    notifyListeners();
    try {
      await FinalizeIncident(_repository)(
        technician: _session.currentUser,
        incidentId: _incidentId,
      );
      return null;
    } on IncidentFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return IncidentFailure.actionFailed.message;
    } finally {
      _finalizing = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Pasa la incidencia a En proceso. Devuelve el mensaje de error, o
  /// `null` si se guardó; la pantalla se actualiza sola con el nuevo
  /// estado.
  Future<String?> startAttention() async {
    if (!canStartAttention || _starting) return null;
    _starting = true;
    notifyListeners();
    try {
      await StartAttention(_repository)(
        technician: _session.currentUser,
        incidentId: _incidentId,
      );
      return null;
    } on IncidentFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return IncidentFailure.actionFailed.message;
    } finally {
      _starting = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Solo tiene sentido reintentar si el error no fue por permisos.
  bool get canRetry =>
      _state == AssignedIncidentDetailState.error && !_accessDenied;

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
  String get residentEmail => _item?.residentEmail ?? _noData;

  /// Teléfono para copiarlo, o `null` si el residente no lo registró.
  String? get phoneToCopy => _item?.residentPhone;

  String get housingType => _item?.housing?.type.displayName ?? _noData;
  String get housingNumber {
    final number = _item?.housing?.number.trim() ?? '';
    return number.isEmpty ? _noData : number;
  }

  /// Edificio, torre o sección, o `null` si la vivienda no tiene (por
  /// ejemplo, una casa).
  String? get building {
    final building = _item?.housing?.building?.trim() ?? '';
    return building.isEmpty ? null : building;
  }

  String get description {
    final text = incident?.description.trim() ?? '';
    return text.isEmpty ? _noData : text;
  }

  String get status => incident?.status.label ?? _noData;
  String get createdAt => _date(incident?.createdAt);
  String get estimatedArrival => _date(incident?.estimatedTime);

  /// Cuándo comenzó la atención (HU-3.5), o `null` si no ha comenzado.
  String? get startedAt {
    final date = incident?.startedAt;
    return date == null ? null : DateFormats.dateTime(date);
  }

  /// Cuánto falta para la hora estimada de llegada, o cuánto pasó. Solo
  /// mientras la incidencia está Asignada: después ya no hace falta.
  String? get arrivalCountdown {
    final arrival = incident?.estimatedTime;
    if (arrival == null || incident!.status != IncidentStatus.assigned) {
      return null;
    }
    return countdown(arrival, _clock());
  }

  static String countdown(DateTime arrival, DateTime now) {
    final minutes = arrival.difference(now).inMinutes;
    if (minutes == 0) return 'Es la hora estimada de llegada';
    final text = _duration(minutes.abs());
    return minutes > 0 ? 'Faltan $text' : 'La hora estimada pasó hace $text';
  }

  static String _duration(int minutes) {
    final days = minutes ~/ (24 * 60);
    final hours = minutes % (24 * 60) ~/ 60;
    final rest = minutes % 60;
    if (days > 0) return hours > 0 ? '$days d $hours h' : '$days d';
    if (hours > 0) return rest > 0 ? '$hours h $rest min' : '$hours h';
    return '$rest min';
  }

  /// La incidencia ya se resolvió: dejó la lista de asignadas y está en el
  /// historial.
  bool get isResolved => incident?.status == IncidentStatus.resolved;

  /// El técnico ya registró la solución (HU-3.6), aunque la incidencia siga
  /// En proceso.
  bool get hasSolution => incident?.solution?.trim().isNotEmpty ?? false;

  /// Cuándo se registró la solución, o `null` si no se sabe.
  String? get solutionRegisteredAt {
    final date = incident?.solutionRegisteredAt;
    return date == null ? null : DateFormats.dateTime(date);
  }

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
    _updateTicker();
    _watchConduct();
    notifyListeners();
  }

  // HU-7.2 Reportar la conducta de un residente.

  final ConductReportRepository? _conductReportsOverride;

  // Se crea al usarse, solo cuando la incidencia ya está resuelta.
  late final ConductReportRepository _conductReports =
      _conductReportsOverride ?? ConductReportRepositoryImpl();
  StreamSubscription<List<ConductReport>>? _reportsSubscription;

  /// La sección de conducta del residente solo aparece en incidencias
  /// resueltas (T 7.2.1).
  bool get showConductSection =>
      _state == AssignedIncidentDetailState.loaded && isResolved;

  bool _residentsLoading = false;
  bool _reportsLoading = false;

  /// Se consulta a quién se puede reportar y qué reportes ya se enviaron.
  bool get isConductLoading => _residentsLoading || _reportsLoading;

  List<ReportableResident> _residents = const [];

  /// El residente que registró la incidencia y quienes escribieron en su
  /// chat (T 7.2.5).
  List<ReportableResident> get residents => _residents;

  List<ConductReport> _ownReports = const [];

  /// Reportes que el técnico ya envió en esta incidencia (T 7.2.6).
  List<ConductReport> get ownReports => _ownReports;

  String? _conductError;

  /// No se pudo consultar a quién reportar o los reportes enviados.
  String? get conductError => _conductError;

  /// Residentes que todavía no reporta en esta incidencia.
  List<ReportableResident> get pendingResidents {
    final reported = {for (final report in _ownReports) report.reportedId};
    return [
      for (final resident in _residents)
        if (!reported.contains(resident.id)) resident,
    ];
  }

  /// Por qué no se puede reportar a un residente, o `null` si se puede.
  ConductReportFailure? get reportBlockReason {
    final current = incident;
    if (current == null) return ConductReportFailure.incidentNotFound;
    final failure = ConductReportConditions.checkForTechnician(
      current,
      technician: _session.currentUser,
    );
    if (failure != null) return failure;
    if (isConductLoading || _conductError != null) return null;
    if (_residents.isEmpty) return ConductReportFailure.noResidents;
    if (pendingResidents.isEmpty) {
      return ConductReportFailure.allResidentsReported;
    }
    return null;
  }

  /// Se puede abrir el formulario: la incidencia está resuelta y queda
  /// algún residente por reportar.
  bool get canReportResident =>
      showConductSection &&
      !isConductLoading &&
      _conductError == null &&
      reportBlockReason == null;

  /// Datos para el formulario del reporte, o `null` si no se puede.
  ResidentReportTarget? get residentReportTarget {
    if (!canReportResident) return null;
    final current = incident!;
    return ResidentReportTarget(
      incidentId: current.id,
      incidentNumber: current.reportNumber,
      incidentTitle: current.title,
      residents: pendingResidents,
    );
  }

  /// Guarda el reporte recién enviado mientras llega de Firestore, para que
  /// el residente ya no aparezca como pendiente.
  void reportSent(ConductReport report) {
    if (_ownReports.any((r) => r.id == report.id)) return;
    _ownReports = [..._ownReports, report];
    notifyListeners();
  }

  /// Consulta a quién se puede reportar y escucha los reportes enviados en
  /// cuanto la incidencia se resuelve. Se hace una sola vez por pantalla.
  void _watchConduct() {
    final technicianId = _session.currentUser?.uid;
    if (_reportsSubscription != null || !showConductSection) return;
    if (technicianId == null) return;
    final current = incident!;

    _residentsLoading = true;
    _reportsLoading = true;
    try {
      _reportsSubscription = _conductReports
          .watchOwnReports(incidentId: current.id, reporterId: technicianId)
          .listen(_onOwnReports, onError: _onConductError);
    } catch (_) {
      _reportsLoading = false;
      _conductError = ConductReportFailure.loadFailed.message;
    }
    _loadResidents(current);
  }

  Future<void> _loadResidents(Incident current) async {
    try {
      final residents = await _conductReports.reportableResidents(
        incidentId: current.id,
        createdBy: current.createdBy,
      );
      if (_disposed) return;
      _residents = residents;
    } catch (error) {
      if (_disposed) return;
      _conductError = error is ConductReportFailure
          ? error.message
          : ConductReportFailure.residentsLoadFailed.message;
    }
    _residentsLoading = false;
    notifyListeners();
  }

  void _onOwnReports(List<ConductReport> reports) {
    // Se conservan los recién enviados que todavía no llegan.
    final ids = {for (final report in reports) report.id};
    _ownReports = [
      ...reports,
      for (final report in _ownReports)
        if (!ids.contains(report.id)) report,
    ];
    _reportsLoading = false;
    if (!_disposed) notifyListeners();
  }

  void _onConductError(Object error) {
    _reportsLoading = false;
    _conductError = error is ConductReportFailure
        ? error.message
        : ConductReportFailure.loadFailed.message;
    if (!_disposed) notifyListeners();
  }

  Timer? _ticker;

  /// Actualiza cada minuto el tiempo que falta para la llegada, solo
  /// mientras la pantalla está abierta.
  void _updateTicker() {
    if (arrivalCountdown == null || !hasListeners) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(minutes: 1), (_) {
        notifyListeners();
      });
    }
  }

  void _onError(Object error) {
    // No se conserva nada de una incidencia que el técnico no puede ver.
    _item = null;
    _updateTicker();
    _accessDenied = identical(error, IncidentFailure.notAssignedToYou);
    _errorMessage = error is IncidentFailure
        ? error.message
        : IncidentFailure.loadFailed.message;
    _state = AssignedIncidentDetailState.error;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _updateTicker();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _updateTicker();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _reportsSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
