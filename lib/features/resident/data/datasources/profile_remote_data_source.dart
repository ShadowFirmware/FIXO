import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/profile_failure.dart';

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
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where('correo', isEqualTo: normalizedEmail)
        .limit(5)
        .get();

    for (final doc in query.docs) {
      if (doc.id != uid) {
        throw const ProfileFailure(
          'El correo electrónico ya está registrado por otro usuario.',
        );
      }
    }

    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'nombre': name,
      'correo': normalizedEmail,
      'telefono': phone.trim(),
    });
  }
}
