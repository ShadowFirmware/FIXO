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

/// Vivienda disponible para asignar.
const torreA5A = Housing(
  id: 'vivienda-5a',
  type: HousingType.apartment,
  building: 'Torre A',
  number: '5A',
  active: true,
  residentId: null,
);

/// Simula la colección `viviendas` sin conexión.
class FakeHousingRepository implements HousingRepository {
  FakeHousingRepository({
    Map<String, Housing>? housings,
    this.error,
  }) : housings = housings ??
            const {
              'vivienda-4b': torreA4B,
              'vivienda-5a': torreA5A,
            };

  /// ID → vivienda registrada.
  final Map<String, Housing> housings;

  /// Error que lanza [getById], por ejemplo sin conexión.
  final Object? error;

  /// Si no es `null`, [getById] espera a que se complete para responder.
  Completer<void>? gate;

  final requestedIds = <String>[];
  final assignCalls = <({String housingId, String residentId})>[];
  final unassignCalls = <String>[];

  @override
  Future<Housing?> getById(String id) async {
    requestedIds.add(id);
    await gate?.future;
    if (error != null) throw error!;
    return housings[id];
  }

  @override
  Future<List<Housing>> getAll() async {
    if (error != null) throw error!;
    return housings.values.toList();
  }

  @override
  Future<void> assignResident({
    required String housingId,
    required String residentId,
  }) async {
    if (error != null) throw error!;
    assignCalls.add((housingId: housingId, residentId: residentId));
  }

  @override
  Future<void> unassignResident({required String housingId}) async {
    if (error != null) throw error!;
    unassignCalls.add(housingId);
  }
}
