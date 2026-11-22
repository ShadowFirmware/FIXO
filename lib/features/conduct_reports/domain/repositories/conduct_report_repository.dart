import '../entities/conduct_report.dart';

abstract interface class ConductReportRepository {
  /// Emite el reporte que [reporterId] levantó en la incidencia
  /// [incidentId] cada vez que cambia, o `null` si todavía no lo levanta.
  /// Los errores llegan como `ConductReportFailure`.
  Stream<ConductReport?> watchOwn({
    required String incidentId,
    required String reporterId,
  });

  /// Sube las evidencias y registra el reporte del residente [reporterId]
  /// contra el técnico de la incidencia. Devuelve el reporte guardado, con
  /// su folio. Si falla lanza un `ConductReportFailure`.
  Future<ConductReport> reportTechnician({
    required String reporterId,
    required NewConductReport data,
  });
}
