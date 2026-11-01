import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../firebase_options.dart';
import '../../../auth/data/models/user_model.dart';

class TechnicianAdminRemoteDataSource {
  TechnicianAdminRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? secondaryAuth,
  })  : _firestoreOverride = firestore,
        _secondaryAuthOverride = secondaryAuth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _secondaryAuthOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

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
      app = Firebase.app('TechnicianRegistration');
    } catch (_) {
      app = await Firebase.initializeApp(
        name: 'TechnicianRegistration',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<List<UserModel>> fetchTechnicians() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where('rol', isEqualTo: 'tecnico')
        .get();
    return snapshot.docs.map(UserModel.fromFirestore).toList();
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

  Future<void> createTechnicianProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String specialty,
  }) async {
    final now = DateTime.now();
    await _firestore.collection(FirestoreCollections.users).doc(uid).set({
      'nombre': name,
      'correo': email.trim().toLowerCase(),
      'telefono': phone.trim(),
      'rol': 'tecnico',
      'estadoCuenta': 'activa',
      'estadoConducta': 'bueno',
      'especialidad': specialty.trim(),
      'disponible': true,
      'reportesValidados': 0,
      'creadoEn': now.toIso8601String(),
      'fechaRegistro': now,
    });
  }

  Future<void> updateTechnicianProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? specialty,
  }) async {
    final data = <String, dynamic>{
      'nombre': name,
      'correo': email.trim().toLowerCase(),
      'telefono': phone.trim(),
    };
    if (specialty != null) data['especialidad'] = specialty.trim();
    await _firestore.collection(FirestoreCollections.users).doc(uid).update(data);
  }

  Future<void> deleteTechnicianProfile(String uid) async {
    await _firestore.collection(FirestoreCollections.users).doc(uid).delete();
  }
}
