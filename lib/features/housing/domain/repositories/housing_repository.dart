import '../entities/housing.dart';

abstract interface class HousingRepository {
  /// Devuelve `null` si la vivienda no existe.
  Future<Housing?> getById(String id);

  Future<List<Housing>> getAll();
  Future<void> assignResident({required String housingId, required String residentId});
  Future<void> unassignResident({required String housingId});
}
