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

  // HU-7.2 Reportar la conducta de un residente.

  /// Emite los reportes que [reporterId] levantó en la incidencia
  /// [incidentId] cada vez que cambian. Los errores llegan como
  /// `ConductReportFailure`.
  Stream<List<ConductReport>> watchOwnReports({
    required String incidentId,
    required String reporterId,
  });

  /// Residentes que se pueden reportar en la incidencia: el que la
  /// registró ([createdBy]) y quienes escribieron en su chat. Si falla
  /// lanza un `ConductReportFailure`.
  Future<List<ReportableResident>> reportableResidents({
    required String incidentId,
    required String createdBy,
  });

  /// Sube las evidencias y registra el reporte del técnico [reporterId]
  /// contra el residente elegido. Devuelve el reporte guardado, con su
  /// folio. Si falla lanza un `ConductReportFailure`.
  Future<ConductReport> reportResident({
    required String reporterId,
    required NewResidentConductReport data,
  });
}
