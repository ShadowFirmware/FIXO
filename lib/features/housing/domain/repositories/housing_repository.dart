import '../entities/housing.dart';

abstract interface class HousingRepository {
  /// Devuelve `null` si la vivienda no existe.
  Future<Housing?> getById(String id);
}
