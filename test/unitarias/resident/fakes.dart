import 'package:fixo/core/errors/profile_failure.dart';
import 'package:fixo/features/resident/domain/repositories/profile_repository.dart';

/// Simula la escritura del perfil en `usuarios` sin conexión.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.error, this.emailError});

  /// Error que lanza [updateContactInfo], por ejemplo sin conexión.
  final ProfileFailure? error;

  /// Error que lanza [requestEmailChange].
  final ProfileFailure? emailError;

  /// Datos recibidos en cada guardado.
  final saved = <({String uid, String name, String email, String phone})>[];

  /// Correos a los que se pidió enviar el enlace de verificación.
  final emailRequests = <String>[];

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    if (error != null) throw error!;
    saved.add((uid: uid, name: name, email: email, phone: phone));
  }

  @override
  Future<void> requestEmailChange({
    required String uid,
    required String email,
  }) async {
    if (emailError != null) throw emailError!;
    emailRequests.add(email);
  }
}
