/// Error de un reporte de conducta (HU-7.1), con un mensaje listo para
/// mostrarse.
class ConductReportFailure implements Exception {
  const ConductReportFailure(this.message);

  final String message;

  static const notResident = ConductReportFailure(
    'Solo los residentes pueden reportar la conducta de un técnico.',
  );
  static const accountNotActive = ConductReportFailure(
    'Tu cuenta no está activa, así que no puedes enviar reportes de '
    'conducta. Contacta al administrador.',
  );
  static const notYourIncident = ConductReportFailure(
    'Solo puedes reportar incidencias de tu vivienda.',
  );
  static const incidentNotFound = ConductReportFailure(
    'No se encontró la incidencia.',
  );
  static const notResolved = ConductReportFailure(
    'Solo puedes reportar al técnico cuando la incidencia esté Resuelta.',
  );
  static const noTechnician = ConductReportFailure(
    'La incidencia no tiene un técnico que la haya atendido.',
  );
  static const notAttendingTechnician = ConductReportFailure(
    'Solo puedes reportar al técnico que atendió la incidencia.',
  );
  static const duplicate = ConductReportFailure(
    'Ya enviaste un reporte de conducta para esta incidencia.',
  );
  static const reasonRequired = ConductReportFailure(
    'Elige el motivo del reporte.',
  );
  static const tooManyEvidence = ConductReportFailure(
    'Solo puedes adjuntar hasta 5 evidencias.',
  );
  static const evidenceUpload = ConductReportFailure(
    'No se pudieron subir las evidencias. Inténtalo de nuevo.',
  );
  static const network = ConductReportFailure(
    'No hay conexión a internet. El reporte no se envió.',
  );
  static const permissionDenied = ConductReportFailure(
    'No tienes permiso para enviar reportes de conducta.',
  );
  static const unknown = ConductReportFailure(
    'No se pudo enviar el reporte. Inténtalo de nuevo.',
  );
  static const loadFailed = ConductReportFailure(
    'No se pudo consultar si ya reportaste al técnico.',
  );

  @override
  String toString() => message;
}
