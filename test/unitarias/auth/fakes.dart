import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fixo/features/auth/data/models/user_model.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/auth/domain/repositories/auth_repository.dart';

/// Usuarios de prueba que simulan la colección `usuarios`.
abstract final class TestUsers {
  static const password = 'Password123';

  static UserModel resident({
    AccountStatus status = AccountStatus.active,
    DateTime? suspendedUntil,
  }) => UserModel(
    uid: 'uid-residente',
    name: 'María López Hernández',
    email: 'maria@correo.com',
    phone: '7771112233',
    role: UserRole.resident,
    accountStatus: status,
    conductStatus: ConductStatus.good,
    suspendedUntil: suspendedUntil,
    housingId: 'vivienda-4b',
  );

  static const technician = UserModel(
    uid: 'uid-tecnico',
    name: 'Juan Pérez Ramírez',
    email: 'juan@correo.com',
    phone: '7774445566',
    role: UserRole.technician,
    accountStatus: AccountStatus.active,
    conductStatus: ConductStatus.good,
    specialty: 'electricidad',
    available: true,
  );

  static const admin = UserModel(
    uid: 'uid-admin',
    name: 'Admin Prueba',
    email: 'admin@correo.com',
    phone: '7771234567',
    role: UserRole.admin,
    accountStatus: AccountStatus.active,
  );
}

/// Simula Firebase Authentication y Firestore sin conexión.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource({
    this.passwords = const {},
    this.profiles = const {},
    this.signInError,
    this.fetchError,
    this.currentUid,
  });

  /// Correo → contraseña registrada en Authentication.
  final Map<String, String> passwords;

  /// UID → documento en `usuarios`.
  final Map<String, UserModel> profiles;

  /// Error que lanza [signIn] en lugar de validar.
  final FirebaseAuthException? signInError;

  /// Error que lanza [fetchUser], por ejemplo `permission-denied`.
  final FirebaseException? fetchError;

  @override
  String? currentUid;

  int signOutCalls = 0;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    if (passwords[email] != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final uid = _uidFor(email);
    currentUid = uid;
    return uid;
  }

  @override
  Future<UserModel?> fetchUser(String uid) async {
    if (fetchError != null) throw fetchError!;
    return profiles[uid];
  }

  @override
  Future<void> createUser({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    final uid = 'uid-nuevo';
    currentUid = uid;
  }

  @override
  Future<void> createUserDocument(UserModel user) async {
    // No-op para pruebas
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentUid = null;
  }

  /// Si el correo no tiene perfil, devuelve un UID sin documento.
  String _uidFor(String email) {
    for (final user in profiles.values) {
      if (user.email == email) return user.uid;
    }
    return 'uid-sin-perfil';
  }
}

/// Repositorio que devuelve una respuesta fija.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.error});

  final AppUser? user;
  final Object? error;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return user!;
  }

  @override
  Future<AppUser?> restoreSession() async => user;

  @override
  Future<void> signOut() async {}
}

/// Atajo para errores de Firestore.
FirebaseException firestoreError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);
