import '../entities/housing.dart';

abstract interface class HousingRepository {
  /// Devuelve `null` si la vivienda no existe.
  Future<Housing?> getById(String id);

  /// Lista las viviendas activas y disponibles (sin residente activo).
  Future<List<Housing>> listAvailable();

  /// Lista todas las viviendas registradas, activas o no (HU-4.7).
  Future<List<Housing>> listAll();

  /// Registra una vivienda activa y sin residente. Lanza
  /// `HousingFailure.duplicated` si ya existe otra con la misma
  /// identificación en el mismo edificio o sección.
  Future<Housing> register({
    required HousingType type,
    required String number,
    String? building,
  });

  /// Modifica los datos que identifican la vivienda.
  Future<void> update({
    required String id,
    required HousingType type,
    required String number,
    String? building,
  });

  /// Marca la vivienda como activa o inactiva. Las incidencias abiertas
  /// siguen su flujo; solo se bloquean las nuevas.
  Future<void> setActive({required String id, required bool active});

  /// Asigna un residente a una vivienda disponible.
  Future<void> assignResident({
    required String housingId,
    required String residentId,
  });

  /// Libera la vivienda (quita el residente activo).
  Future<void> unassignResident(String housingId);
}
