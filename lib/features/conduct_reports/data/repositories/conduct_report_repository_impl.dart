import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../incidents/data/datasources/evidence_storage_data_source.dart';
import '../../domain/entities/conduct_report.dart';
import '../../domain/repositories/conduct_report_repository.dart';
import '../datasources/conduct_report_remote_data_source.dart';

class ConductReportRepositoryImpl implements ConductReportRepository {
  ConductReportRepositoryImpl({
    ConductReportRemoteDataSource? remote,
    EvidenceStorageDataSource? storage,
  }) : _remote = remote ?? ConductReportRemoteDataSource(),
       _storage = storage ?? EvidenceStorageDataSource();

  final ConductReportRemoteDataSource _remote;
  final EvidenceStorageDataSource _storage;

  @override
  Stream<ConductReport?> watchOwn({
    required String incidentId,
    required String reporterId,
  }) => _remote
      .watchById(
        ConductReport.docIdFor(incidentId: incidentId, reporterId: reporterId),
      )
      .handleError((Object e) {
        throw e is FormatException
            ? ConductReportFailure.loadFailed
            : _failureFor(e, fallback: ConductReportFailure.loadFailed);
      });

  @override
  Future<ConductReport> reportTechnician({
    required String reporterId,
    required NewConductReport data,
  }) async {
    final target = data.target;
    final id = ConductReport.docIdFor(
      incidentId: target.incidentId,
      reporterId: reporterId,
    );

    try {
      // Si ya lo reportó no se suben las evidencias en vano (T 7.1.6).
      if (await _remote.exists(id)) throw ConductReportFailure.duplicate;

      // Primero se suben las evidencias: si fallan, no queda un reporte
      // registrado sin ellas.
      final List<String> urls;
      try {
        urls = await _storage.uploadConductEvidence(id, data.evidence);
      } on EvidenceUploadException catch (e) {
        throw e.network
            ? ConductReportFailure.network
            : ConductReportFailure.evidenceUpload;
      }

      final adminIds = await _remote.activeAdminIds();
      return await _remote.createTechnicianReport(
        incidentId: target.incidentId,
        reporterId: reporterId,
        technicianId: target.technicianId,
        reason: data.reason,
        description: data.description,
        evidence: urls,
        adminIds: adminIds,
      );
    } on ConductReportFailure {
      rethrow;
    } catch (e) {
      throw _failureFor(e, fallback: ConductReportFailure.unknown);
    }
  }

  static ConductReportFailure _failureFor(
    Object error, {
    required ConductReportFailure fallback,
  }) => switch (error) {
    ConductReportFailure() => error,
    FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
      ConductReportFailure.network,
    FirebaseException(code: 'permission-denied') =>
      ConductReportFailure.permissionDenied,
    _ => fallback,
  };
}
