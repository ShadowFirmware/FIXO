import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/repositories/conduct_report_repository_impl.dart';
import '../../domain/entities/conduct_report.dart';
import '../../domain/repositories/conduct_report_repository.dart';
import '../../domain/usecases/report_technician.dart';
import 'conduct_report_form_view_model.dart';

/// ViewModel del formulario para reportar la conducta del técnico
/// (HU-7.1).
class ReportTechnicianViewModel extends ConductReportFormViewModel {
  ReportTechnicianViewModel({
    required this.target,
    AuthSession? session,
    ConductReportRepository? repository,
    super.picker,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? ConductReportRepositoryImpl();

  /// Incidencia resuelta y técnico al que se reporta.
  final ConductReportTarget target;

  final AuthSession _session;
  final ConductReportRepository _repository;

  static const maxDescriptionLength =
      ConductReportFormViewModel.maxDescriptionLength;
  static const maxEvidence = ConductReportFormViewModel.maxEvidence;
  static const maxPhotoBytes = ConductReportFormViewModel.maxPhotoBytes;
  static const maxVideoBytes = ConductReportFormViewModel.maxVideoBytes;

  /// Motivos que puede elegir el residente (T 7.1.3).
  @override
  List<ConductReason> get reasons => ConductReason.forTechnician;

  @override
  Future<ConductReport> send(ConductReason reason) =>
      ReportTechnician(_repository)(
        resident: _session.currentUser,
        data: NewConductReport(
          target: target,
          reason: reason,
          description: description,
          evidence: evidence,
        ),
      );
}
