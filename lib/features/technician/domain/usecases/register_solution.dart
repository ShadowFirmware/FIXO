import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../repositories/assigned_incident_repository.dart';

/// No se pudo registrar la solución porque faltan datos obligatorios.
class SolutionIncompleteException implements Exception {
  const SolutionIncompleteException(this.message);

  final String message;
}

/// Registrar la solución y las evidencias de una incidencia (HU-3.6): pasa
/// de En proceso a Resuelta. Solo puede hacerlo el técnico asignado, con su
/// cuenta activa.
class RegisterSolution {
  const RegisterSolution(this._repository);

  final AssignedIncidentRepository _repository;

  static const missingEvidenceMessage =
      'Agrega al menos una foto o video del trabajo realizado.';

  /// Lanza [SolutionIncompleteException] si falta la descripción o las
  /// evidencias, o un [IncidentFailure] si no se pudo guardar. Se valida
  /// antes de subir las evidencias, para no subirlas en vano.
  Future<void> call({
    required AppUser? technician,
    required String incidentId,
    required String solution,
    required List<EvidenceFile> evidence,
  }) async {
    if (technician?.role != UserRole.technician) {
      throw IncidentFailure.assignedAccessDenied;
    }
    if (technician!.accountStatus != AccountStatus.active) {
      throw IncidentFailure.technicianCannotAttend;
    }
    if (Validators.solutionDescription(solution) case final error?) {
      throw SolutionIncompleteException(error);
    }
    if (evidence.isEmpty) {
      throw const SolutionIncompleteException(missingEvidenceMessage);
    }

    await _repository.registerSolution(
      incidentId: incidentId,
      technicianId: technician.uid,
      solution: solution.trim(),
      evidence: evidence,
    );
  }
}
