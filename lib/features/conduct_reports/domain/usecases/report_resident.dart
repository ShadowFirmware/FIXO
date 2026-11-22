import '../../../../core/errors/conduct_report_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/conduct_report.dart';
import '../repositories/conduct_report_repository.dart';
import 'report_technician.dart';

/// El técnico reporta la conducta del residente de una incidencia que
/// atendió y ya está resuelta (HU-7.2).
class ReportResident {
  const ReportResident(this._repository);

  final ConductReportRepository _repository;

  /// Máximo de fotos, videos o capturas del chat por reporte.
  static const maxEvidence = ReportTechnician.maxEvidence;

  /// Lanza [ConductReportIncompleteException] si falta la descripción y un
  /// [ConductReportFailure] si no se puede reportar. Las condiciones de la
  /// incidencia y del residente se revisan con los datos actuales en la
  /// transacción.
  Future<ConductReport> call({
    required AppUser? technician,
    required NewResidentConductReport data,
  }) async {
    if (technician == null || technician.role != UserRole.technician) {
      throw ConductReportFailure.notTechnician;
    }
    if (technician.accountStatus != AccountStatus.active) {
      throw ConductReportFailure.accountNotActive;
    }
    if (data.resident.id.trim().isEmpty) {
      throw ConductReportFailure.residentRequired;
    }
    final invalid = Validators.conductDescription(data.description);
    if (invalid != null) throw ConductReportIncompleteException(invalid);
    if (data.evidence.length > maxEvidence) {
      throw ConductReportFailure.tooManyEvidence;
    }

    return _repository.reportResident(
      reporterId: technician.uid,
      data: NewResidentConductReport(
        incidentId: data.incidentId,
        resident: data.resident,
        reason: data.reason,
        description: data.description.trim(),
        evidence: data.evidence,
      ),
    );
  }
}
