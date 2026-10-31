import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../firebase_options.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../housing/data/models/housing_model.dart';

/// Acceso a Firebase Authentication y Firestore para la gestión de residentes
/// por parte del administrador.
class ResidentAdminRemoteDataSource {
  ResidentAdminRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? secondaryAuth,
  })  : _firestoreOverride = firestore,
        _secondaryAuthOverride = secondaryAuth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _secondaryAuthOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Crea el usuario en Firebase Authentication sin cerrar la sesión del
  /// administrador, usando una app secundaria.
  Future<String> createUser({
    required String email,
    required String password,
  }) async {
    final auth = _secondaryAuthOverride ?? await _secondaryAuth();
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await auth.signOut();
      return uid;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    FirebaseApp app;
    try {
      app = Firebase.app('ResidentRegistration');
    } catch (_) {
      app = await Firebase.initializeApp(
        name: 'ResidentRegistration',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<List<HousingModel>> fetchAvailableHousings() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.housings)
        .where('activa', isEqualTo: true)
        .get();
    return snapshot.docs
        .map(HousingModel.fromFirestore)
        .where((housing) => housing.residentId == null)
        .toList();
  }

  Future<UserModel?> fetchUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where('correo', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromFirestore(snapshot.docs.first);
  }

  Future<List<UserModel>> fetchResidents() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where('rol', isEqualTo: 'residente')
        .get();
    return snapshot.docs.map(UserModel.fromFirestore).toList();
  }

  Future<void> createResidentProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String housingId,
  }) async {
    final now = DateTime.now();
    await _firestore.collection(FirestoreCollections.users).doc(uid).set({
      'nombre': name,
      'correo': email.trim().toLowerCase(),
      'telefono': phone.trim(),
      'rol': 'residente',
      'estadoCuenta': 'activa',
      'estadoConducta': 'bueno',
      'viviendaId': housingId,
      'reportesValidados': 0,
      'creadoEn': now.toIso8601String(),
    });
  }

  Future<void> assignHousing({
    required String housingId,
    required String residentId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.housings)
        .doc(housingId)
        .update({'residenteActivoId': residentId});
  }

  Future<void> unassignHousing(String housingId) async {
    await _firestore
        .collection(FirestoreCollections.housings)
        .doc(housingId)
        .update({'residenteActivoId': null});
  }

  Future<void> updateResidentProfile({
    required String uid,
    required String name,
    required String phone,
    String? housingId,
  }) async {
    final data = <String, dynamic>{
      'nombre': name,
      'telefono': phone.trim(),
    };
    if (housingId != null) data['viviendaId'] = housingId;
    await _firestore.collection(FirestoreCollections.users).doc(uid).update(data);
  }

  Future<void> deleteResidentProfile(String uid) async {
    await _firestore.collection(FirestoreCollections.users).doc(uid).delete();
  }
}