import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../models/user_model.dart';

/// Acceso a Firebase Authentication y a la colección `usuarios`.
class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  // Se resuelven al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Devuelve el UID del usuario autenticado.
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  }

  /// UID de la sesión guardada por Firebase, o `null` si no hay sesión.
  String? get currentUid => _auth.currentUser?.uid;

  /// Correo con el que el usuario está registrado en Authentication.
  String? get currentEmail => _auth.currentUser?.email;

  /// Aplica en `usuarios` el correo que ya se confirmó con el enlace.
  Future<void> confirmEmail(String uid, String email) {
    return _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'correo': email,
      'correoPendiente': FieldValue.delete(),
      'enlaceCorreoEnviado': FieldValue.delete(),
    });
  }

  /// Envía el enlace de verificación al correo [email] que dejó pendiente el
  /// administrador (HU-4.5). Authentication cambia el correo cuando se abre.
  Future<void> sendEmailChangeLink(String uid, String email) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.verifyBeforeUpdateEmail(email);
    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'enlaceCorreoEnviado': true,
    });
  }

  /// Devuelve `null` si no existe el documento del usuario.
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();
}
