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
}

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

  Future<void> close() => changes.close();
}
