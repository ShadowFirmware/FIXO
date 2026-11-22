import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/repositories/conduct_report_repository_impl.dart';
import '../../domain/entities/conduct_report.dart';
import '../../domain/repositories/conduct_report_repository.dart';
import '../../domain/usecases/report_resident.dart';
import 'conduct_report_form_view_model.dart';

/// ViewModel del formulario para reportar la conducta de un residente
/// (HU-7.2).
class ReportResidentViewModel extends ConductReportFormViewModel {
  ReportResidentViewModel({
    required this.target,
    AuthSession? session,
    ConductReportRepository? repository,
    super.picker,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? ConductReportRepositoryImpl(),
       // Si solo hay un residente, queda elegido.
       _resident = target.residents.length == 1
           ? target.residents.single
           : null;

  /// Incidencia resuelta y residentes que se pueden reportar.
  final ResidentReportTarget target;

  final AuthSession _session;
  final ConductReportRepository _repository;

  /// Motivos que puede elegir el técnico (T 7.2.3).
  @override
  List<ConductReason> get reasons => ConductReason.forResident;

  /// Hay más de un residente: el técnico elige a quién reporta.
  bool get choosesResident => target.residents.length > 1;

  ReportableResident? _resident;
  ReportableResident? get resident => _resident;

  /// Se muestra si se intenta enviar sin elegir al residente.
  String? _residentError;
  String? get residentError => _residentError;

  void selectResident(ReportableResident resident) {
    if (isSaving || _resident?.id == resident.id) return;
    if (!target.residents.any((r) => r.id == resident.id)) return;
    _resident = resident;
    _residentError = null;
    notifyListeners();
  }

  @override
  String? validateTarget() {
    _residentError = _resident == null
        ? ConductReportFailure.residentRequired.message
        : null;
    return _residentError;
  }

  @override
  Future<ConductReport> send(ConductReason reason) =>
      ReportResident(_repository)(
        technician: _session.currentUser,
        data: NewResidentConductReport(
          incidentId: target.incidentId,
          resident: _resident!,
          reason: reason,
          description: description,
          evidence: evidence,
        ),
      );
}
