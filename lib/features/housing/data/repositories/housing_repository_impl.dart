import '../../domain/entities/housing.dart';
import '../../domain/repositories/housing_repository.dart';
import '../datasources/housing_remote_data_source.dart';

class HousingRepositoryImpl implements HousingRepository {
  HousingRepositoryImpl({HousingRemoteDataSource? remote})
    : _remote = remote ?? HousingRemoteDataSource();

  final HousingRemoteDataSource _remote;

  @override
  Future<Housing?> getById(String id) => _remote.fetchById(id);
}
