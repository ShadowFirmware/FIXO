import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/errors/profile_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../datasources/technician_admin_remote_data_source.dart';
import '../../domain/repositories/technician_admin_repository.dart';

class TechnicianAdminRepositoryImpl implements TechnicianAdminRepository {
  TechnicianAdminRepositoryImpl({
    TechnicianAdminRemoteDataSource? remote,
  }) : _remote = remote ?? TechnicianAdminRemoteDataSource();

  final TechnicianAdminRemoteDataSource _remote;

  @override
  Future<List<AppUser>> listTechnicians() async {
    final models = await _remote.fetchTechnicians();
    return models.cast<AppUser>();
  }

  @override
  Future<void> registerTechnician({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await _remote.fetchUserByEmail(normalizedEmail);
    if (existing != null) {
      throw const ProfileFailure(
        'El correo electrónico ya está registrado por otro usuario.',
      );
    }

    String uid;
    try {
      uid = await _remote.createUser(email: normalizedEmail, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.network
          : AuthFailure.unknown;
    }

    try {
      await _remote.createTechnicianProfile(
        uid: uid,
        name: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        specialty: specialty.trim(),
      );
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.network
          : AuthFailure.unknown;
    }
  }

  @override
  Future<void> updateTechnician({
    required String uid,
    required String name,
    required String phone,
    String? specialty,
  }) async {
    try {
      await _remote.updateTechnicianProfile(
        uid: uid,
        name: name,
        phone: phone,
        specialty: specialty,
      );
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable' ? AuthFailure.network : AuthFailure.unknown;
    }
  }

  @override
  Future<void> deleteTechnician({
    required String uid,
  }) async {
    try {
      await _remote.deleteTechnicianProfile(uid);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable' ? AuthFailure.network : AuthFailure.unknown;
    }
  }

  AuthFailure _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthFailure('El correo electrónico ya está registrado.');
      case 'invalid-email':
        return const AuthFailure('El correo electrónico no es válido.');
      case 'weak-password':
        return const AuthFailure('La contraseña es demasiado débil.');
      case 'network-request-failed':
        return AuthFailure.network;
      default:
        return AuthFailure.unknown;
    }
  }
}
