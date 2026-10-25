import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/technician_repository.dart';

class TechnicianRepositoryImpl implements TechnicianRepository {
  TechnicianRepositoryImpl({AuthRemoteDataSource? users})
    : _users = users ?? AuthRemoteDataSource();

  // Los técnicos viven en la misma colección `usuarios`.
  final AuthRemoteDataSource _users;

  @override
  Future<AppUser?> getById(String uid) async {
    final user = await _users.fetchUser(uid);
    return user?.role == UserRole.technician ? user : null;
  }
}
