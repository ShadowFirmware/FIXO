import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';

/// Escritura del perfil en la colección `usuarios`.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// `update` falla con `not-found` si el documento no existe, así que no
  /// crea perfiles nuevos por accidente.
  Future<void> updateContactInfo({
    required String uid,
    required String name,
    required String phone,
  }) {
    return _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'nombre': name,
      'telefono': phone,
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? currentEmail,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final current = currentEmail?.trim().toLowerCase();

    if (trimmedEmail.isNotEmpty && trimmedEmail != current) {
      final query = await _firestore
          .collection(FirestoreCollections.users)
          .where('correo', isEqualTo: trimmedEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && query.docs.first.id != uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'Email already in use',
        );
      }
    }

    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'nombre': name,
      'correo': trimmedEmail,
      'telefono': phone,
    });
  }
}
