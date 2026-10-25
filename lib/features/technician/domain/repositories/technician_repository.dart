import '../../../auth/domain/entities/app_user.dart';

abstract interface class TechnicianRepository {
  /// Devuelve el técnico con ese UID, o `null` si no existe o no es técnico.
  Future<AppUser?> getById(String uid);
}
