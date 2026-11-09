import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/profile_failure.dart';

/// Escritura del perfil en la colección `usuarios` y solicitud del cambio de
/// correo en Firebase Authentication.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  // Se resuelven al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// `update` falla con `not-found` si el documento no existe, así que no
  /// crea perfiles nuevos por accidente.
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _ensureEmailIsFree(uid, normalizedEmail);

    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'nombre': name,
      'correo': normalizedEmail,
      'telefono': phone.trim(),
    });
  }

  /// Envía el enlace de verificación al correo nuevo y lo deja pendiente en
  /// `correoPendiente`. Authentication solo cambia el correo cuando se abre el
  /// enlace; `correo` se actualiza en el siguiente inicio de sesión.
  Future<void> requestEmailChange({
    required String uid,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _ensureEmailIsFree(uid, normalizedEmail);

    final user = _auth.currentUser;
    if (user == null) throw ProfileFailure.permissionDenied;
    await user.verifyBeforeUpdateEmail(normalizedEmail);

    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'correoPendiente': normalizedEmail,
      // El enlace ya se envió: no hay que reenviarlo al iniciar sesión.
      'enlaceCorreoEnviado': true,
    });
  }

  Future<void> _ensureEmailIsFree(String uid, String email) async {
    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where('correo', isEqualTo: email)
        .limit(5)
        .get();

    for (final doc in query.docs) {
      if (doc.id != uid) throw ProfileFailure.emailTaken;
    }
  }
}
