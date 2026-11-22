import 'dart:async';

import 'package:fixo/core/errors/conduct_report_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/conduct_reports/data/datasources/conduct_report_remote_data_source.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_model.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:fixo/features/conduct_reports/domain/repositories/conduct_report_repository.dart';

const target = ConductReportTarget(
  incidentId: 'inc-1',
  incidentNumber: 'INC-0007',
  incidentTitle: 'Fuga en baño',
  technicianId: 'uid-tecnico',
  technicianName: 'Juan Pérez Ramírez',
);

/// Reporte como lo guardaría la transacción.
ConductReportModel sentReport({
  int folio = 3,
  ConductReason reason = ConductReason.badAttitude,
  ConductReportStatus status = ConductReportStatus.pendingReview,
  List<String> evidence = const [],
  DateTime? createdAt,
}) => ConductReportModel(
  id: ConductReport.docIdFor(incidentId: 'inc-1', reporterId: 'uid-residente'),
  folio: folio,
  incidentId: 'inc-1',
  incidentFolio: 7,
  incidentTitle: 'Fuga en baño',
  reporterId: 'uid-residente',
  reporterName: 'María López Hernández',
  reporterRole: UserRole.resident,
  reportedId: 'uid-tecnico',
  reportedName: 'Juan Pérez Ramírez',
  reportedRole: UserRole.technician,
  reason: reason,
  description: 'Me habló de forma grosera al terminar.',
  status: status,
  evidence: evidence,
  createdAt: createdAt,
);

/// Simula `reportesConducta` sin conexión.
class FakeConductReportRemoteDataSource
    implements ConductReportRemoteDataSource {
  FakeConductReportRemoteDataSource({
    this.existing = const {},
    this.adminIds = const ['uid-admin'],
    this.createError,
  });

  /// IDs de los reportes que ya existen.
  final Set<String> existing;
  final List<String> adminIds;

  /// Error que lanza la transacción, por ejemplo un reporte duplicado.
  final Object? createError;

  final checked = <String>[];
  final created =
      <
        ({
          String incidentId,
          String reporterId,
          String technicianId,
          ConductReason reason,
          String description,
          List<String> evidence,
          List<String> adminIds,
        })
      >[];

  @override
  Future<bool> exists(String id) async {
    checked.add(id);
    return existing.contains(id);
  }

  @override
  Future<List<String>> activeAdminIds() async => adminIds;

  @override
  Future<ConductReportModel> createTechnicianReport({
    required String incidentId,
    required String reporterId,
    required String technicianId,
    required ConductReason reason,
    required String description,
    required List<String> evidence,
    List<String> adminIds = const [],
  }) async {
    if (createError != null) throw createError!;
    created.add((
      incidentId: incidentId,
      reporterId: reporterId,
      technicianId: technicianId,
      reason: reason,
      description: description,
      evidence: evidence,
      adminIds: adminIds,
    ));
    return sentReport(reason: reason, evidence: evidence);
  }

  /// Controla lo que emite [watchById].
  final changes = StreamController<ConductReportModel?>.broadcast();
  final watchedIds = <String>[];

  @override
  Stream<ConductReportModel?> watchById(String id) {
    watchedIds.add(id);
    return changes.stream;
  }

  // HU-7.2

  /// Residentes que escribieron en el chat (UID → nombre).
  Map<String, String> chatAuthors = const {};

  /// Nombres de los usuarios en `usuarios`.
  Map<String, String> names = const {};

  /// Error al consultar el chat.
  Object? chatError;

  @override
  Future<Map<String, String>> residentChatAuthors(String incidentId) async {
    if (chatError != null) throw chatError!;
    return chatAuthors;
  }

  @override
  Future<bool> wroteInChat({
    required String incidentId,
    required String residentId,
  }) async => chatAuthors.containsKey(residentId);

  @override
  Future<String?> userName(String uid) async => names[uid];

  final residentReports =
      <
        ({
          String incidentId,
          String reporterId,
          String residentId,
          bool wroteInChat,
          ConductReason reason,
          List<String> evidence,
          List<String> adminIds,
        })
      >[];

  @override
  Future<ConductReportModel> createResidentReport({
    required String incidentId,
    required String reporterId,
    required String residentId,
    required bool wroteInChat,
    required ConductReason reason,
    required String description,
    required List<String> evidence,
    List<String> adminIds = const [],
  }) async {
    if (createError != null) throw createError!;
    residentReports.add((
      incidentId: incidentId,
      reporterId: reporterId,
      residentId: residentId,
      wroteInChat: wroteInChat,
      reason: reason,
      evidence: evidence,
      adminIds: adminIds,
    ));
    return residentReport(residentId: residentId, reason: reason);
  }

  /// Controla lo que emite [watchByReporter].
  final reporterChanges =
      StreamController<List<ConductReportModel>>.broadcast();

  @override
  Stream<List<ConductReportModel>> watchByReporter({
    required String incidentId,
    required String reporterId,
  }) => reporterChanges.stream;
}

/// Residente que registró la incidencia y otro que escribió en el chat.
const registrant = ReportableResident(
  id: 'uid-residente',
  name: 'María López Hernández',
  registeredIncident: true,
);
const chatResident = ReportableResident(
  id: 'uid-residente-2',
  name: 'Carlos Ruiz Soto',
  wroteInChat: true,
);

const residentTarget = ResidentReportTarget(
  incidentId: 'inc-1',
  incidentNumber: 'INC-0007',
  incidentTitle: 'Fuga en baño',
  residents: [registrant],
);

/// Reporte del técnico contra un residente, como lo guardaría la
/// transacción.
ConductReportModel residentReport({
  String residentId = 'uid-residente',
  String residentName = 'María López Hernández',
  int folio = 4,
  ConductReason reason = ConductReason.insults,
}) => ConductReportModel(
  id: ConductReport.docIdFor(
    incidentId: 'inc-1',
    reporterId: 'uid-tecnico',
    reportedId: residentId,
  ),
  folio: folio,
  incidentId: 'inc-1',
  incidentFolio: 7,
  incidentTitle: 'Fuga en baño',
  reporterId: 'uid-tecnico',
  reporterName: 'Juan Pérez Ramírez',
  reporterRole: UserRole.technician,
  reportedId: residentId,
  reportedName: residentName,
  reportedRole: UserRole.resident,
  reason: reason,
  description: 'Me insultó cuando le expliqué la reparación.',
  status: ConductReportStatus.pendingReview,
);

/// Repositorio que guarda en memoria lo que recibe.
class FakeConductReportRepository implements ConductReportRepository {
  FakeConductReportRepository({this.error});

  ConductReportFailure? error;

  /// Si no es `null`, [reportTechnician] espera a que se complete.
  Completer<void>? gate;

  final received = <({String reporterId, NewConductReport data})>[];

  @override
  Future<ConductReport> reportTechnician({
    required String reporterId,
    required NewConductReport data,
  }) async {
    received.add((reporterId: reporterId, data: data));
    await gate?.future;
    if (error != null) throw error!;
    return sentReport(reason: data.reason);
  }

  /// Controla lo que emite [watchOwn]: con `add` se simula un cambio en
  /// Firestore y con `addError` una falla.
  final changes = StreamController<ConductReport?>.broadcast();
  final watched = <({String incidentId, String reporterId})>[];

  @override
  Stream<ConductReport?> watchOwn({
    required String incidentId,
    required String reporterId,
  }) {
    watched.add((incidentId: incidentId, reporterId: reporterId));
    return changes.stream;
  }

  // HU-7.2

  /// Residentes que devuelve [reportableResidents].
  List<ReportableResident> residents = const [registrant];

  /// Error de [reportableResidents].
  ConductReportFailure? residentsError;

  /// Si no es `null`, [reportableResidents] espera a que se complete.
  Completer<void>? residentsGate;

  final residentQueries = <({String incidentId, String createdBy})>[];

  @override
  Future<List<ReportableResident>> reportableResidents({
    required String incidentId,
    required String createdBy,
  }) async {
    residentQueries.add((incidentId: incidentId, createdBy: createdBy));
    await residentsGate?.future;
    if (residentsError != null) throw residentsError!;
    return residents;
  }

  final residentReports =
      <({String reporterId, NewResidentConductReport data})>[];

  @override
  Future<ConductReport> reportResident({
    required String reporterId,
    required NewResidentConductReport data,
  }) async {
    residentReports.add((reporterId: reporterId, data: data));
    await gate?.future;
    if (error != null) throw error!;
    return residentReport(
      residentId: data.resident.id,
      residentName: data.resident.name,
      reason: data.reason,
    );
  }

  /// Controla lo que emite [watchOwnReports].
  final reportsChanges = StreamController<List<ConductReport>>.broadcast();
  final watchedReports = <({String incidentId, String reporterId})>[];

  @override
  Stream<List<ConductReport>> watchOwnReports({
    required String incidentId,
    required String reporterId,
  }) {
    watchedReports.add((incidentId: incidentId, reporterId: reporterId));
    return reportsChanges.stream;
  }

  Future<void> close() async {
    await changes.close();
    await reportsChanges.close();
  }
}
