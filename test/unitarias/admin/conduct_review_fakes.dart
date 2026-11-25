import 'dart:async';

import 'package:fixo/core/errors/conduct_report_failure.dart';
import 'package:fixo/features/admin/data/datasources/conduct_review_remote_data_source.dart';
import 'package:fixo/features/admin/domain/repositories/conduct_review_repository.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/conduct_reports/data/models/conduct_report_model.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';

/// Reporte de conducta como lo guarda Firestore. Por omisión, el de un
/// residente contra el técnico de la incidencia INC-0007, con una foto,
/// un video y una captura del chat.
ConductReportModel conductReport({
  String id = 'inc-7_uid-residente',
  int folio = 1,
  ConductReportStatus status = ConductReportStatus.pendingReview,
  UserRole reporterRole = UserRole.resident,
  String reporterName = 'María López Hernández',
  UserRole reportedRole = UserRole.technician,
  String reportedName = 'Juan Pérez Ramírez',
  ConductReason reason = ConductReason.badAttitude,
  String description = 'Me habló de forma grosera al terminar.',
  List<String> evidence = const [
    'https://res.cloudinary.com/x/image/upload/foto.jpg',
    'https://res.cloudinary.com/x/video/upload/video.mp4',
    'https://res.cloudinary.com/x/image/upload/chat.png',
  ],
  DateTime? createdAt,
  DateTime? reviewedAt,
  String? reviewerName,
}) => ConductReportModel(
  id: id,
  folio: folio,
  incidentId: 'inc-7',
  incidentFolio: 7,
  incidentTitle: 'Fuga en baño',
  reporterId: reporterRole == UserRole.resident ? 'uid-residente' : 'uid-tec',
  reporterName: reporterName,
  reporterRole: reporterRole,
  reportedId: reportedRole == UserRole.technician ? 'uid-tec' : 'uid-residente',
  reportedName: reportedName,
  reportedRole: reportedRole,
  reason: reason,
  description: description,
  status: status,
  evidence: evidence,
  createdAt: createdAt ?? DateTime(2026, 11, 20, 16, 5),
  reviewedAt: reviewedAt,
  reviewerId: reviewedAt == null ? null : 'uid-admin',
  reviewerName: reviewerName,
);

/// Reportes de ejemplo: uno pendiente (RC-0001), uno validado (RC-0002,
/// técnico contra residente, sin evidencias) y uno rechazado (RC-0003).
List<ConductReport> sampleReports() => [
  conductReport(),
  conductReport(
    id: 'inc-8_uid-tec_uid-residente',
    folio: 2,
    status: ConductReportStatus.validated,
    reporterRole: UserRole.technician,
    reporterName: 'Juan Pérez Ramírez',
    reportedRole: UserRole.resident,
    reportedName: 'María López Hernández',
    reason: ConductReason.insults,
    description: 'Me insultó cuando le expliqué el costo.',
    evidence: const [],
    createdAt: DateTime(2026, 11, 19),
    reviewedAt: DateTime(2026, 11, 21, 10),
    reviewerName: 'Ana Admin',
  ),
  conductReport(
    id: 'inc-9_uid-residente',
    folio: 3,
    status: ConductReportStatus.rejected,
    reason: ConductReason.delay,
    description: 'Llegó media hora tarde.',
    createdAt: DateTime(2026, 11, 18),
    reviewedAt: DateTime(2026, 11, 21, 11),
    reviewerName: 'Ana Admin',
  ),
];

/// Simula la revisión de reportes sin conexión. [controller] controla lo
/// que emite [watchAll]; [review] actualiza el reporte y vuelve a emitir.
class FakeConductReviewRepository implements ConductReviewRepository {
  FakeConductReviewRepository({List<ConductReport>? reports})
    : reports = reports ?? sampleReports();

  List<ConductReport> reports;
  final controller = StreamController<List<ConductReport>>.broadcast();

  /// Error que lanza [review], por ejemplo sin conexión.
  Object? reviewError;

  final reviews =
      <({String reportId, String reviewerId, ConductReportStatus decision})>[];

  /// Emite la lista actual, como lo haría Firestore.
  void emit() => controller.add(List.of(reports));

  @override
  Stream<List<ConductReport>> watchAll() => controller.stream;

  @override
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  }) async {
    if (reviewError != null) throw reviewError!;
    final index = reports.indexWhere((r) => r.id == reportId);
    if (index < 0) throw ConductReportFailure.reportNotFound;
    if (!reports[index].isPendingReview) {
      throw ConductReportFailure.alreadyReviewed;
    }
    reviews.add((
      reportId: reportId,
      reviewerId: reviewerId,
      decision: decision,
    ));
    final r = reports[index] as ConductReportModel;
    reports = List.of(reports)
      ..[index] = conductReport(
        id: r.id,
        folio: r.folio,
        status: decision,
        reporterRole: r.reporterRole,
        reporterName: r.reporterName,
        reportedRole: r.reportedRole,
        reportedName: r.reportedName,
        reason: r.reason,
        description: r.description,
        evidence: r.evidence,
        createdAt: r.createdAt,
        reviewedAt: DateTime(2026, 11, 24, 9),
        reviewerName: 'Ana Admin',
      );
    emit();
  }
}

/// Simula `reportesConducta` para probar el repositorio.
class FakeConductReviewRemoteDataSource
    implements ConductReviewRemoteDataSource {
  final controller = StreamController<List<ConductReportModel>>.broadcast();

  /// Error que lanza [review].
  Object? reviewError;

  final reviews =
      <({String reportId, String reviewerId, ConductReportStatus decision})>[];

  @override
  Stream<List<ConductReportModel>> watchAll() => controller.stream;

  @override
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  }) async {
    if (reviewError != null) throw reviewError!;
    reviews.add((
      reportId: reportId,
      reviewerId: reviewerId,
      decision: decision,
    ));
  }
}
