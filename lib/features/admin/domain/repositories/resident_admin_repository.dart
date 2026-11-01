import '../../../housing/domain/entities/housing.dart';
import '../../../auth/domain/entities/app_user.dart';

abstract interface class ResidentAdminRepository {
  Future<List<Housing>> listAvailableHousings();

  Future<List<Housing>> listHousings();

  Future<List<AppUser>> listResidents();

  Future<void> registerResident({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String housingId,
  });

  Future<void> updateResident({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? housingId,
    String? previousHousingId,
  });

  Future<void> deleteResident({
    required String uid,
    String? housingId,
  });
}