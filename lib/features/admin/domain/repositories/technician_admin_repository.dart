import '../../../auth/domain/entities/app_user.dart';

abstract interface class TechnicianAdminRepository {
  Future<List<AppUser>> listTechnicians();

  Future<void> registerTechnician({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
  });

  Future<void> updateTechnician({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? specialty,
  });

  Future<void> deleteTechnician({
    required String uid,
  });
}
