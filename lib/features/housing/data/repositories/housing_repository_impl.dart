import '../../domain/entities/housing.dart';
import '../../domain/repositories/housing_repository.dart';
import '../datasources/housing_remote_data_source.dart';

class HousingRepositoryImpl implements HousingRepository {
  HousingRepositoryImpl({HousingRemoteDataSource? remote})
    : _remote = remote ?? HousingRemoteDataSource();

  final HousingRemoteDataSource _remote;

  @override
  Future<Housing?> getById(String id) => _remote.fetchById(id);

  @override
  Future<List<Housing>> getAll() => _remote.fetchAll();

  @override
  Future<void> assignResident({
    required String housingId,
    required String residentId,
  }) =>
      _remote.assignResident(housingId: housingId, residentId: residentId);

  @override
  Future<void> unassignResident({required String housingId}) =>
      _remote.unassignResident(housingId: housingId);
}
