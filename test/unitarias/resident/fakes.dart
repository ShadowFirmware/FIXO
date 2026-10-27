import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/resident/domain/repositories/profile_repository.dart';

/// Simula la escritura del perfil en `usuarios` sin conexión.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.error});

  /// Error que lanza las actualizaciones.
  ProfileFailure? error;
  bool throwOnUpdate = false;

  /// Datos recibidos en cada guardado.
  final saved = <({String uid, String name, String phone})>[];
  final updateProfileCalls = <({String uid, String name, String email, String phone, String? currentEmail})>[];

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String phone,
  }) async {
    if (error != null) throw error!;
    saved.add((uid: uid, name: name, phone: phone));
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? currentEmail,
  }) async {
    if (throwOnUpdate) throw Exception('unexpected');
    if (error != null) throw error!;
    updateProfileCalls.add((uid: uid, name: name, email: email, phone: phone, currentEmail: currentEmail));
  }
}
