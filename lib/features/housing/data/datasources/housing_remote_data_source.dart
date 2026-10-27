import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../models/housing_model.dart';

/// Acceso a la colección `viviendas`.
class HousingRemoteDataSource {
  HousingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Devuelve `null` si no existe el documento.
  Future<HousingModel?> fetchById(String id) async {
    final doc = await _firestore
        .collection(FirestoreCollections.housings)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return HousingModel.fromFirestore(doc);
  }

  Future<List<HousingModel>> fetchAll() async {
    final snapshot = await _firestore.collection(FirestoreCollections.housings).get();
    return snapshot.docs
        .map((doc) => HousingModel.fromFirestore(doc))
        .toList();
  }

  Future<void> assignResident({
    required String housingId,
    required String residentId,
  }) async {
    await _firestore.collection(FirestoreCollections.housings).doc(housingId).update({
      'residenteActivoId': residentId,
    });
  }

  Future<void> unassignResident({required String housingId}) async {
    await _firestore.collection(FirestoreCollections.housings).doc(housingId).update({
      'residenteActivoId': null,
    });
  }
}
