import '../entities/housing.dart';

abstract interface class HousingRepository {
  /// Devuelve `null` si la vivienda no existe.
  Future<Housing?> getById(String id);

  /// Lista las viviendas activas y disponibles (sin residente activo).
  Future<List<Housing>> listAvailable();

  /// Asigna un residente a una vivienda disponible.
  Future<void> assignResident({
    required String housingId,
    required String residentId,
  });

  /// Libera la vivienda (quita el residente activo).
  Future<void> unassignResident(String housingId);
}
