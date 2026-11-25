import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';

/// Reglas para que el administrador marque un reporte de conducta como
/// Validado o Rechazado (HU-7.3), aplicadas sobre los documentos que se
/// leen dentro de la transacción. Son funciones puras para poder probarlas
/// sin Firestore.
abstract final class ConductReviewPlan {
  /// Revisa con los datos actuales que quien revisa sea un administrador
  /// activo, que el reporte exista y siga Pendiente de revisión, y que la
  /// decisión sea Validado o Rechazado. Lanza un [ConductReportFailure] si
  /// no se puede.
  static void validate({
    required Map<String, dynamic>? report,
    required Map<String, dynamic>? reviewer,
    required ConductReportStatus decision,
  }) {
    if (decision == ConductReportStatus.pendingReview) {
      throw ConductReportFailure.invalidDecision;
    }
    if (reviewer == null ||
        reviewer['rol'] != UserRole.admin.value ||
        reviewer['estadoCuenta'] != AccountStatus.active.value) {
      throw ConductReportFailure.notAdmin;
    }
    if (report == null) throw ConductReportFailure.reportNotFound;
    // La revisión es definitiva: si otro administrador ya lo revisó, no se
    // cambia su decisión.
    if (report['estado'] != ConductReportStatus.pendingReview.value) {
      throw ConductReportFailure.alreadyReviewed;
    }
  }

  /// Cambios en el reporte: el estado nuevo, la fecha del servidor y quién
  /// lo revisó.
  ///
  /// No toca el perfil del usuario reportado: el contador de reportes
  /// validados, el estado de conducta y las sanciones corresponden a la
  /// HU-7.4.
  static Map<String, dynamic> reportUpdate({
    required ConductReportStatus decision,
    required String reviewerId,
    required String reviewerName,
  }) => {
    'estado': decision.value,
    'fechaRevision': FieldValue.serverTimestamp(),
    'revisadoPorId': reviewerId,
    'revisadoPorNombre': reviewerName,
  };
}
