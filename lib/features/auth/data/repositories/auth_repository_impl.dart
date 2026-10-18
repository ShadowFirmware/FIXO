import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthRemoteDataSource? remote})
    : _remote = remote ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final uid = await _remote.signIn(email: email, password: password);
      return await _loadProfile(uid);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable' ? AuthFailure.network : AuthFailure.unknown;
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();

  /// Cierra la sesión de Firebase si la cuenta existe en Authentication pero
  /// no tiene un perfil válido en `usuarios`.
  Future<AppUser> _loadProfile(String uid) async {
    try {
      final user = await _remote.fetchUser(uid);
      if (user == null) throw AuthFailure.notRegistered;
      return user;
    } on FormatException {
      await _remote.signOut();
      throw AuthFailure.notRegistered;
    } on AuthFailure {
      await _remote.signOut();
      rethrow;
    } on FirebaseException {
      await _remote.signOut();
      rethrow;
    }
  }

  AuthFailure _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
      case 'user-disabled':
        return AuthFailure.invalidCredentials;
      case 'too-many-requests':
        return AuthFailure.tooManyRequests;
      case 'network-request-failed':
        return AuthFailure.network;
      default:
        return AuthFailure.unknown;
    }
  }
}
