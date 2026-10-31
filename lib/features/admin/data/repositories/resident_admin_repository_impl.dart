import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/errors/profile_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../datasources/resident_admin_remote_data_source.dart';
import '../../domain/repositories/resident_admin_repository.dart';

class ResidentAdminRepositoryImpl implements ResidentAdminRepository {
  ResidentAdminRepositoryImpl({
    ResidentAdminRemoteDataSource? remote,
    HousingRepository? housings,
  })  : _remote = remote ?? ResidentAdminRemoteDataSource(),
        _housings = housings ?? HousingRepositoryImpl();

  final ResidentAdminRemoteDataSource _remote;
  final HousingRepository _housings;

  @override
  Future<List<Housing>> listAvailableHousings() =>
      _remote.fetchAvailableHousings();

  @override
  Future<List<AppUser>> listResidents() async {
    final models = await _remote.fetchResidents();
    return models.cast<AppUser>();
  }

  @override
  Future<void> registerResident({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String housingId,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await _remote.fetchUserByEmail(normalizedEmail);
    if (existing != null) {
      throw const ProfileFailure(
        'El correo electrónico ya está registrado por otro usuario.',
      );
    }

    final housing = await _housings.getById(housingId);
    if (housing == null || !housing.active || housing.residentId != null) {
      throw const ProfileFailure(
        'La vivienda seleccionada no está disponible.',
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
      await _remote.createResidentProfile(
        uid: uid,
        name: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        housingId: housingId,
      );
      await _remote.assignHousing(housingId: housingId, residentId: uid);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.network
          : AuthFailure.unknown;
    }
  }

  @override
  Future<void> updateResident({
    required String uid,
    required String name,
    required String phone,
    String? housingId,
  }) async {
    try {
      await _remote.updateResidentProfile(
        uid: uid,
        name: name,
        phone: phone,
        housingId: housingId,
      );
      if (housingId != null) {
        await _remote.assignHousing(housingId: housingId, residentId: uid);
      }
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable' ? AuthFailure.network : AuthFailure.unknown;
    }
  }

  @override
  Future<void> deleteResident({
    required String uid,
    String? housingId,
  }) async {
    try {
      await _remote.deleteResidentProfile(uid);
      if (housingId != null) {
        await _remote.unassignHousing(housingId);
      }
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