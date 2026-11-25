import '../../../conduct_reports/domain/entities/conduct_report.dart';

/// Consulta y revisión de los reportes de conducta por el administrador
/// (HU-7.3).
abstract interface class ConductReviewRepository {
  /// Emite todos los reportes registrados, del más reciente al más antiguo,
  /// cada vez que cambian. Los errores llegan como `ConductReportFailure`.
  Stream<List<ConductReport>> watchAll();

  /// Marca el reporte [reportId] como [decision] (Validado o Rechazado) a
  /// nombre del administrador [reviewerId]. Si falla lanza un
  /// `ConductReportFailure`, por ejemplo si ya fue revisado.
  Future<void> review({
    required String reportId,
    required String reviewerId,
    required ConductReportStatus decision,
  });
}
