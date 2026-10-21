import 'dart:async';

import 'package:fixo/features/housing/domain/entities/housing.dart';
import 'package:fixo/features/housing/domain/repositories/housing_repository.dart';

/// Vivienda de prueba asignada a la residente de `TestUsers`.
const torreA4B = Housing(
  id: 'vivienda-4b',
  type: HousingType.apartment,
  building: 'Torre A',
  number: '4B',
  residentId: 'uid-residente',
);

/// Simula la colección `viviendas` sin conexión.
class FakeHousingRepository implements HousingRepository {
  FakeHousingRepository({
    this.housings = const {'vivienda-4b': torreA4B},
    this.error,
  });

  /// ID → vivienda registrada.
  final Map<String, Housing> housings;

  /// Error que lanza [getById], por ejemplo sin conexión.
  final Object? error;

  /// Si no es `null`, [getById] espera a que se complete para responder.
  Completer<void>? gate;

  final requestedIds = <String>[];

  @override
  Future<Housing?> getById(String id) async {
    requestedIds.add(id);
    await gate?.future;
    if (error != null) throw error!;
    return housings[id];
  }
}
