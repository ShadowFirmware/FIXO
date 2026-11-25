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

  // Técnico que reporta a un residente (HU-7.2)
  static const notTechnician = ConductReportFailure(
    'Solo los técnicos pueden reportar la conducta de un residente.',
  );
  static const notYourAttendedIncident = ConductReportFailure(
    'Solo puedes reportar residentes de incidencias que atendiste.',
  );
  static const residentNotResolved = ConductReportFailure(
    'Solo puedes reportar al residente cuando la incidencia esté Resuelta.',
  );
  static const notParticipant = ConductReportFailure(
    'Solo puedes reportar al residente que registró la incidencia o '
    'participó en su chat.',
  );
  static const noResidents = ConductReportFailure(
    'No hay un residente que puedas reportar en esta incidencia.',
  );
  static const residentRequired = ConductReportFailure(
    'Elige al residente que quieres reportar.',
  );
  static const duplicateResident = ConductReportFailure(
    'Ya enviaste un reporte de conducta contra este residente para esta '
    'incidencia.',
  );
  static const allResidentsReported = ConductReportFailure(
    'Ya reportaste a los residentes de esta incidencia.',
  );
  static const residentsLoadFailed = ConductReportFailure(
    'No se pudo consultar a quién puedes reportar. Inténtalo de nuevo.',
  );

  // Administrador que revisa los reportes (HU-7.3)
  static const reportsLoadFailed = ConductReportFailure(
    'No se pudieron cargar los reportes de conducta. Inténtalo de nuevo.',
  );
  static const notAdmin = ConductReportFailure(
    'Solo un administrador activo puede revisar reportes de conducta.',
  );
  static const reportNotFound = ConductReportFailure(
    'El reporte de conducta ya no existe.',
  );
  static const alreadyReviewed = ConductReportFailure(
    'Este reporte ya fue revisado. Solo se pueden validar o rechazar los '
    'reportes pendientes de revisión.',
  );
  static const invalidDecision = ConductReportFailure(
    'El reporte solo se puede marcar como Validado o Rechazado.',
  );
  static const reviewFailed = ConductReportFailure(
    'No se pudo guardar la revisión del reporte. Inténtalo de nuevo.',
  );
  static const reviewNetwork = ConductReportFailure(
    'No hay conexión a internet. La revisión no se guardó.',
  );

  @override
  String toString() => message;
}
