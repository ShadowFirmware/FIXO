/// Error al gestionar viviendas (HU-4.7), con un mensaje listo para mostrarse.
class HousingFailure implements Exception {
  const HousingFailure(this.message);

  final String message;

  static const duplicated = HousingFailure(
    'Ya existe una vivienda con ese número en el mismo edificio o sección.',
  );
  static const network = HousingFailure(
    'No hay conexión a internet. Inténtalo de nuevo.',
  );
  static const unknown = HousingFailure(
    'No se pudo completar la operación. Inténtalo de nuevo.',
  );

  @override
  String toString() => message;
}
