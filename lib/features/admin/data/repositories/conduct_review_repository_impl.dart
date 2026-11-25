import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../domain/repositories/conduct_review_repository.dart';
import '../datasources/conduct_review_remote_data_source.dart';

class ConductReviewRepositoryImpl implements ConductReviewRepository {
  ConductReviewRepositoryImpl({ConductReviewRemoteDataSource? remote})
    : _remote = remote ?? ConductReviewRemoteDataSource();

  final ConductReviewRemoteDataSource _remote;

  @override
  Stream<List<ConductReport>> watchAll() => _remote.watchAll().handleError((
    Object e,
  ) {
    throw switch (e) {
      ConductReportFailure() => e,
      FirebaseException(code: 'permission-denied') =>
        ConductReportFailure.notAdmin,
      _ => ConductReportFailure.reportsLoadFailed,
    };
  });

  @override
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  }) async {
    try {
      await _remote.review(
        reportId: reportId,
        reviewerId: reviewerId,
        decision: decision,
      );
    } catch (e) {
      throw switch (e) {
        ConductReportFailure() => e,
        FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
          ConductReportFailure.reviewNetwork,
        FirebaseException(code: 'permission-denied') =>
          ConductReportFailure.notAdmin,
        FirebaseException(code: 'not-found') =>
          ConductReportFailure.reportNotFound,
        _ => ConductReportFailure.reviewFailed,
      };
    }
  }
}
