/// Error al registrar una incidencia, con un mensaje listo para mostrarse.
class IncidentFailure implements Exception {
  const IncidentFailure(this.message);

  final String message;

  static const noHousing = IncidentFailure(
    'No tienes una vivienda asignada. Contacta al administrador para poder '
    'registrar incidencias.',
  );
  static const inactiveHousing = IncidentFailure(
    'Tu vivienda está inactiva, así que no se pueden registrar incidencias '
    'nuevas. Contacta al administrador.',
  );
  static const notResident = IncidentFailure(
    'Solo los residentes pueden registrar incidencias.',
  );
  static const network = IncidentFailure(
    'No hay conexión a internet. La incidencia no se registró.',
  );
  static const permissionDenied = IncidentFailure(
    'No tienes permiso para registrar incidencias.',
  );
  static const evidenceUpload = IncidentFailure(
    'No se pudieron subir las evidencias. Inténtalo de nuevo.',
  );
  static const unknown = IncidentFailure(
    'No se pudo registrar la incidencia. Inténtalo de nuevo.',
  );

  static const loadFailed = IncidentFailure(
    'No se pudo cargar la incidencia. Inténtalo de nuevo.',
  );
  static const accessDenied = IncidentFailure(
    'No tienes permiso para consultar esta incidencia.',
  );
  static const offline = IncidentFailure(
    'No hay conexión a internet. Revisa tu conexión e inténtalo de nuevo.',
  );

  static const historyLoadFailed = IncidentFailure(
    'No se pudo cargar el historial. Inténtalo de nuevo.',
  );
  static const historyAccessDenied = IncidentFailure(
    'Solo los residentes pueden consultar el historial de incidencias.',
  );
  static const historyNoHousing = IncidentFailure(
    'No tienes una vivienda asignada, así que no hay historial que mostrar. '
    'Contacta al administrador.',
  );

  // Administrador (HU-4.8 y acciones de asignar / rechazar)
  static const pendingLoadFailed = IncidentFailure(
    'No se pudieron cargar las incidencias pendientes. Inténtalo de nuevo.',
  );
  static const pendingAccessDenied = IncidentFailure(
    'Solo los administradores pueden consultar las incidencias pendientes.',
  );
  static const notPending = IncidentFailure(
    'La incidencia ya no está pendiente. Es posible que otro administrador '
    'la haya atendido.',
  );
  static const alreadyRejected = IncidentFailure(
    'La incidencia fue rechazada y ya no se puede asignar.',
  );
  static const technicianUnavailable = IncidentFailure(
    'El técnico seleccionado ya no está disponible. Elige otro.',
  );
  static const adminHistoryAccessDenied = IncidentFailure(
    'Solo los administradores pueden consultar el historial completo.',
  );
  static const statsLoadFailed = IncidentFailure(
    'No se pudieron cargar las estadísticas. Inténtalo de nuevo.',
  );
  static const statsAccessDenied = IncidentFailure(
    'Solo los administradores pueden consultar las estadísticas.',
  );
  static const actionFailed = IncidentFailure(
    'No se pudo completar la acción. Inténtalo de nuevo.',
  );

  // Técnico (HU-3.3)
  static const assignedLoadFailed = IncidentFailure(
    'No se pudieron cargar tus incidencias asignadas. Inténtalo de nuevo.',
  );
  static const assignedAccessDenied = IncidentFailure(
    'Solo los técnicos pueden consultar las incidencias asignadas.',
  );
  static const notAssignedToYou = IncidentFailure(
    'Esta incidencia no está asignada a ti.',
  );

  @override
  String toString() => message;
}
