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
    required String email,
    required String phone,
  }) => _translatingErrors(
    () => _remote.updateContactInfo(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
    ),
  );

  @override
  Future<void> requestEmailChange({
    required String uid,
    required String email,
  }) => _translatingErrors(
    () => _remote.requestEmailChange(uid: uid, email: email),
  );

  /// Traduce los errores de Firestore y Authentication a [ProfileFailure].
  Future<void> _translatingErrors(Future<void> Function() action) async {
    try {
      await action();
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' => ProfileFailure.network,
        'permission-denied' => ProfileFailure.permissionDenied,
        'not-found' => ProfileFailure.notFound,
        'email-already-in-use' => ProfileFailure.emailTaken,
        'requires-recent-login' => ProfileFailure.recentLoginRequired,
        'too-many-requests' => ProfileFailure.tooManyRequests,
        _ => ProfileFailure.unknown,
      };
    }
  }
}
