import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/profile_failure.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({ProfileRemoteDataSource? remote})
    : _remote = remote ?? ProfileRemoteDataSource();

  final ProfileRemoteDataSource _remote;

  @override
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String phone,
  }) async {
    try {
      await _remote.updateContactInfo(uid: uid, name: name, phone: phone);
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => ProfileFailure.network,
        'permission-denied' => ProfileFailure.permissionDenied,
        'not-found' => ProfileFailure.notFound,
        _ => ProfileFailure.unknown,
      };
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? currentEmail,
  }) async {
    try {
      await _remote.updateProfile(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        currentEmail: currentEmail,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        throw ProfileFailure.emailAlreadyInUse;
      }
      throw switch (e.code) {
        'unavailable' || 'deadline-exceeded' => ProfileFailure.network,
        'permission-denied' => ProfileFailure.permissionDenied,
        'not-found' => ProfileFailure.notFound,
        _ => ProfileFailure.unknown,
      };
    }
  }
}
