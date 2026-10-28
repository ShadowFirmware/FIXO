import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/resident/domain/repositories/profile_repository.dart';

/// Simula la escritura del perfil en `usuarios` sin conexión.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.error});

  /// Error que lanza [updateContactInfo], por ejemplo sin conexión.
  final ProfileFailure? error;

  /// Datos recibidos en cada guardado.
  final saved = <({String uid, String name, String phone})>[];

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String phone,
  }) async {
    if (error != null) throw error!;
    saved.add((uid: uid, name: name, phone: phone));
  }
}
