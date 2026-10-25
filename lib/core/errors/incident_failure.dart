/// Error al registrar una incidencia, con un mensaje listo para mostrarse.
class IncidentFailure implements Exception {
  const IncidentFailure(this.message);

  final String message;

  static const noHousing = IncidentFailure(
    'No tienes una vivienda asignada. Contacta al administrador para poder '
    'registrar incidencias.',
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

  @override
  String toString() => message;
}
