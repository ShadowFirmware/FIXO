import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../incidents/data/datasources/evidence_storage_data_source.dart';
import '../../domain/entities/conduct_report.dart';
import '../../domain/repositories/conduct_report_repository.dart';
import '../datasources/conduct_report_remote_data_source.dart';
import '../models/resident_report_plan.dart';

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

  @override
  Stream<List<ConductReport>> watchOwnReports({
    required String incidentId,
    required String reporterId,
  }) => _remote
      .watchByReporter(incidentId: incidentId, reporterId: reporterId)
      .handleError((Object e) {
        throw _failureFor(e, fallback: ConductReportFailure.loadFailed);
      });

  @override
  Future<List<ReportableResident>> reportableResidents({
    required String incidentId,
    required String createdBy,
  }) async {
    try {
      final authors = await _remote.residentChatAuthors(incidentId);
      final registeredName = createdBy.trim().isEmpty
          ? null
          : await _remote.userName(createdBy);
      return ResidentReportPlan.reportable(
        createdBy: createdBy,
        registeredName: registeredName,
        chatAuthors: authors,
      );
    } catch (e) {
      throw _failureFor(e, fallback: ConductReportFailure.residentsLoadFailed);
    }
  }

  @override
  Future<ConductReport> reportResident({
    required String reporterId,
    required NewResidentConductReport data,
  }) async {
    final residentId = data.resident.id;
    final id = ConductReport.docIdFor(
      incidentId: data.incidentId,
      reporterId: reporterId,
      reportedId: residentId,
    );

    try {
      // Si ya lo reportó no se suben las evidencias en vano (T 7.2.6).
      if (await _remote.exists(id)) {
        throw ConductReportFailure.duplicateResident;
      }
      // Se revisa con el chat actual, no con lo que se mostró en pantalla.
      final wroteInChat = await _remote.wroteInChat(
        incidentId: data.incidentId,
        residentId: residentId,
      );

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
      return await _remote.createResidentReport(
        incidentId: data.incidentId,
        reporterId: reporterId,
        residentId: residentId,
        wroteInChat: wroteInChat,
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
