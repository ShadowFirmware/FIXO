import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/housing_failure.dart';
import '../../domain/entities/housing.dart';
import '../../domain/repositories/housing_repository.dart';
import '../datasources/housing_remote_data_source.dart';
import '../models/housing_model.dart';

class HousingRepositoryImpl implements HousingRepository {
  HousingRepositoryImpl({HousingRemoteDataSource? remote})
    : _remote = remote ?? HousingRemoteDataSource();

  final HousingRemoteDataSource _remote;

  @override
  Future<Housing?> getById(String id) => _remote.fetchById(id);

  @override
  Future<List<Housing>> listAvailable() => _remote.fetchAvailable();

  @override
  Future<List<Housing>> listAll() => _guard(() async {
    final housings = await _remote.fetchAll();
    housings.sort((a, b) => a.label.compareTo(b.label));
    return housings;
  });

  @override
  Future<Housing> register({
    required HousingType type,
    required String number,
    String? building,
  }) => _guard(() async {
    final cleanBuilding = _clean(building);
    final cleanNumber = number.trim();
    await _ensureUnique(building: cleanBuilding, number: cleanNumber);

    final housing = HousingModel(
      id: '',
      type: type,
      number: cleanNumber,
      building: cleanBuilding,
    );
    final id = await _remote.create(housing);
    return HousingModel(
      id: id,
      type: type,
      number: cleanNumber,
      building: cleanBuilding,
    );
  });

  @override
  Future<void> update({
    required String id,
    required HousingType type,
    required String number,
    String? building,
  }) => _guard(() async {
    final cleanBuilding = _clean(building);
    final cleanNumber = number.trim();
    await _ensureUnique(
      building: cleanBuilding,
      number: cleanNumber,
      excludeId: id,
    );
    await _remote.updateData(
      id: id,
      type: type.value,
      number: cleanNumber,
      building: cleanBuilding,
    );
  });

  @override
  Future<void> setActive({required String id, required bool active}) =>
      _guard(() => _remote.setActive(id: id, active: active));

  @override
  Future<void> assignResident({
    required String housingId,
    required String residentId,
  }) =>
      _remote.assignResident(housingId: housingId, residentId: residentId);

  @override
  Future<void> unassignResident(String housingId) =>
      _remote.unassignResident(housingId);

  Future<void> _ensureUnique({
    String? building,
    required String number,
    String? excludeId,
  }) async {
    final key = Housing.identityKeyFor(building: building, number: number);
    final housings = await _remote.fetchAll();
    final duplicated = housings.any(
      (h) => h.id != excludeId && h.identityKey == key,
    );
    if (duplicated) throw HousingFailure.duplicated;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on HousingFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? HousingFailure.network
          : HousingFailure.unknown;
    }
  }
}
