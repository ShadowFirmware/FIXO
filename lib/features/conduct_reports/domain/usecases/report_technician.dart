import '../../../../core/errors/conduct_report_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/conduct_report.dart';
import '../repositories/conduct_report_repository.dart';

/// La descripción del reporte no es válida.
class ConductReportIncompleteException implements Exception {
  const ConductReportIncompleteException(this.message);

  final String message;
}

/// El residente reporta la conducta del técnico que atendió su incidencia
/// resuelta (HU-7.1).
class ReportTechnician {
  const ReportTechnician(this._repository);

  final ConductReportRepository _repository;

  /// Máximo de fotos, videos o capturas del chat por reporte.
  static const maxEvidence = 5;

  /// Lanza [ConductReportIncompleteException] si falta la descripción y un
  /// [ConductReportFailure] si no se puede reportar. Las condiciones de la
  /// incidencia se revisan con los datos actuales en la transacción.
  Future<ConductReport> call({
    required AppUser? resident,
    required NewConductReport data,
  }) async {
    if (resident == null || resident.role != UserRole.resident) {
      throw ConductReportFailure.notResident;
    }
    if (resident.accountStatus != AccountStatus.active) {
      throw ConductReportFailure.accountNotActive;
    }
    final invalid = Validators.conductDescription(data.description);
    if (invalid != null) throw ConductReportIncompleteException(invalid);
    if (data.evidence.length > maxEvidence) {
      throw ConductReportFailure.tooManyEvidence;
    }

    return _repository.reportTechnician(
      reporterId: resident.uid,
      data: NewConductReport(
        target: data.target,
        reason: data.reason,
        description: data.description.trim(),
        evidence: data.evidence,
      ),
    );
  }
}
