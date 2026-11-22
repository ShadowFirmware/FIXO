import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../conduct_reports/data/repositories/conduct_report_repository_impl.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../../conduct_reports/domain/entities/conduct_report_conditions.dart';
import '../../../conduct_reports/domain/repositories/conduct_report_repository.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../../incidents/data/repositories/incident_repository_impl.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';
import '../../../incidents/domain/usecases/watch_resident_incident.dart';
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
    AuthSession? session,
    IncidentRepository? incidents,
    HousingRepository? housings,
    TechnicianRepository? technicians,
    ConductReportRepository? conductReports,
  }) : _session = session ?? AuthSession.instance,
       _incidents = incidents ?? IncidentRepositoryImpl(),
       _housings = housings ?? HousingRepositoryImpl(),
       _technicians = technicians ?? TechnicianRepositoryImpl(),
       _conductReportsOverride = conductReports {
    // Solo se reciben los datos si la incidencia es del departamento del
    // residente en sesión.
    _subscription = WatchResidentIncident(_incidents)(
      resident: _session.currentUser,
      id: incidentId,
    ).listen(_onIncident, onError: _onError);
  }

  final AuthSession _session;

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

  /// Cuándo el técnico comenzó la atención (HU-3.5), solo si ya comenzó.
  String? get startedAt {
    final date = _incident?.startedAt;
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
    _watchOwnReport();
    notifyListeners();
  }

  // HU-7.1 Reportar la conducta del técnico.

  final ConductReportRepository? _conductReportsOverride;

  // Se crea al usarse, solo cuando la incidencia ya está resuelta.
  late final ConductReportRepository _conductReports =
      _conductReportsOverride ?? ConductReportRepositoryImpl();
  StreamSubscription<ConductReport?>? _reportSubscription;

  /// `true` mientras se consulta si el residente ya levantó un reporte.
  bool _reportLoading = false;
  bool get isReportLoading => _reportLoading;

  ConductReport? _ownReport;

  /// Reporte que el residente ya levantó contra el técnico de esta
  /// incidencia, si existe (T 7.1.6).
  ConductReport? get ownReport => _ownReport;

  String? _reportError;

  /// No se pudo consultar si ya existe el reporte.
  String? get reportError => _reportError;

  /// La sección de conducta del técnico solo aparece en incidencias
  /// resueltas que tuvieron técnico (T 7.1.1).
  bool get showConductSection =>
      isResolved && (_incident?.technicianId?.trim().isNotEmpty ?? false);

  /// Por qué no se puede reportar al técnico, o `null` si se puede.
  ConductReportFailure? get reportBlockReason {
    final incident = _incident;
    if (incident == null) return ConductReportFailure.incidentNotFound;
    final failure = ConductReportConditions.check(
      incident,
      resident: _session.currentUser,
    );
    if (failure != null) return failure;
    if (_ownReport != null) return ConductReportFailure.duplicate;
    return null;
  }

  /// Se puede abrir el formulario: la incidencia está resuelta, el
  /// residente no ha reportado y ya se cargó el técnico.
  bool get canReportTechnician =>
      showConductSection &&
      !_reportLoading &&
      _reportError == null &&
      _technician != null &&
      reportBlockReason == null;

  /// Datos para el formulario del reporte, o `null` si no se puede.
  ConductReportTarget? get reportTarget {
    if (!canReportTechnician) return null;
    final incident = _incident!;
    return ConductReportTarget(
      incidentId: incident.id,
      incidentNumber: incident.reportNumber,
      incidentTitle: incident.title,
      technicianId: incident.technicianId!,
      technicianName: _technician!.name,
    );
  }

  /// Guarda el reporte recién enviado mientras llega de Firestore, para que
  /// la opción desaparezca de inmediato.
  void reportSent(ConductReport report) {
    _ownReport = report;
    notifyListeners();
  }

  /// Empieza a escuchar el reporte propio en cuanto la incidencia se
  /// resuelve. Se escucha una sola vez por pantalla.
  void _watchOwnReport() {
    final residentId = _session.currentUser?.uid;
    if (_reportSubscription != null || !showConductSection) return;
    if (residentId == null) return;

    _reportLoading = true;
    try {
      _reportSubscription = _conductReports
          .watchOwn(incidentId: _incident!.id, reporterId: residentId)
          .listen(_onOwnReport, onError: _onOwnReportError);
    } catch (_) {
      _onOwnReportError(ConductReportFailure.loadFailed);
    }
  }

  void _onOwnReport(ConductReport? report) {
    // Un reporte no se borra: si todavía no llega, se conserva el enviado.
    _ownReport = report ?? _ownReport;
    _reportLoading = false;
    _reportError = null;
    if (!_disposed) notifyListeners();
  }

  void _onOwnReportError(Object error) {
    _reportLoading = false;
    _reportError = error is ConductReportFailure
        ? error.message
        : ConductReportFailure.loadFailed.message;
    if (!_disposed) notifyListeners();
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

  /// `true` si la incidencia es de otro departamento.
  bool _accessDenied = false;
  bool get isAccessDenied => _accessDenied;

  void _onError(Object error) {
    // No se conserva nada de una incidencia que el residente no puede ver.
    _incident = null;
    _accessDenied = identical(error, IncidentFailure.accessDenied);
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
    _reportSubscription?.cancel();
    super.dispose();
  }
}
