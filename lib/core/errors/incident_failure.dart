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

  @override
  String toString() => message;
}
