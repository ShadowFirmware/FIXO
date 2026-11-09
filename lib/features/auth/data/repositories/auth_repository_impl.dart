import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

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
  Future<AppUser?> restoreSession() async {
    final uid = _remote.currentUid;
    if (uid == null) return null;
    try {
      return await _loadProfile(uid);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();

  /// Cierra la sesión de Firebase si la cuenta existe en Authentication pero
  /// no tiene un perfil válido en `usuarios` o no tiene acceso.
  Future<AppUser> _loadProfile(String uid) async {
    try {
      final user = await _remote.fetchUser(uid);
      if (user == null) throw AuthFailure.notRegistered;
      _ensureCanAccess(user);
      return await _applyConfirmedEmail(user);
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

  /// Si Authentication ya tiene el correo pendiente, el enlace se confirmó y
  /// el perfil pasa a usarlo. Solo se compara con el correo pendiente para no
  /// deshacer los cambios de correo hechos por un administrador.
  Future<AppUser> _applyConfirmedEmail(UserModel user) async {
    final pending = user.pendingEmail;
    if (pending == null) return user;
    if (pending != _remote.currentEmail?.toLowerCase()) {
      // El administrador cambió el correo (HU-4.5): como la app no puede
      // cambiar el correo de acceso de otra persona, se le envía el enlace
      // ahora que inició sesión. Si falla, se intenta en el siguiente inicio.
      if (!user.pendingEmailLinkSent) {
        try {
          await _remote.sendEmailChangeLink(user.uid, pending);
        } on Exception {
          return user;
        }
        return user.withPendingLinkSent();
      }
      return user;
    }
    await _remote.confirmEmail(user.uid, pending);
    return user.copyWithEmail(pending);
  }

  /// Una suspensión temporal cuyo plazo ya terminó no bloquea el acceso
  /// (HU-7.4).
  void _ensureCanAccess(AppUser user) {
    switch (user.accountStatus) {
      case AccountStatus.active:
        return;
      case AccountStatus.removed:
        throw AuthFailure.accountRemoved;
      case AccountStatus.disabled:
        throw AuthFailure.accountDisabled;
      case AccountStatus.suspended:
        final until = user.suspendedUntil;
        if (until != null && DateTime.now().isAfter(until)) return;
        throw AuthFailure.accountSuspended(until);
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
