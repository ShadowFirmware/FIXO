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

  /// Lista las viviendas activas disponibles.
  Future<List<HousingModel>> fetchAvailable() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.housings)
        .where('activa', isEqualTo: true)
        .get();
    return snapshot.docs
        .map(HousingModel.fromFirestore)
        .where((housing) => housing.residentId == null)
        .toList();
  }

  /// Lista todas las viviendas, activas o no.
  Future<List<HousingModel>> fetchAll() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.housings)
        .get();
    return snapshot.docs.map(HousingModel.fromFirestore).toList();
  }

  /// Crea la vivienda y devuelve su ID.
  Future<String> create(HousingModel housing) async {
    final doc = await _firestore
        .collection(FirestoreCollections.housings)
        .add({...housing.toFirestore(), 'creadoEn': DateTime.now()});
    return doc.id;
  }

  Future<void> updateData({
    required String id,
    required String type,
    required String number,
    String? building,
  }) async {
    await _firestore.collection(FirestoreCollections.housings).doc(id).update({
      'tipo': type,
      'edificio': building,
      'numero': number,
    });
  }

  Future<void> setActive({required String id, required bool active}) async {
    await _firestore
        .collection(FirestoreCollections.housings)
        .doc(id)
        .update({'activa': active});
  }

  Future<void> assignResident({
    required String housingId,
    required String residentId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.housings)
        .doc(housingId)
        .update({'residenteActivoId': residentId});
  }

  Future<void> unassignResident(String housingId) async {
    await _firestore
        .collection(FirestoreCollections.housings)
        .doc(housingId)
        .update({'residenteActivoId': null});
  }
}
