import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../housing/data/models/housing_model.dart';
import '../../../incidents/data/models/incident_model.dart';

/// Acceso a Firestore para las incidencias asignadas al técnico (HU-3.3).
class AssignedIncidentRemoteDataSource {
  AssignedIncidentRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestoreCollections.incidents);

  /// Escucha las incidencias asignadas al técnico [technicianId], en
  /// cualquier estado. El estado se filtra en la app para no necesitar un
  /// índice compuesto en Firestore.
  Stream<List<IncidentModel>> watchByTechnician(String technicianId) {
    return _incidents
        .where('tecnicoId', isEqualTo: technicianId)
        .snapshots()
        .map((query) => [for (final doc in query.docs) ?_tryParse(doc)]);
  }

  /// Escucha el documento `incidencias/{id}`: emite cada cambio, o `null`
  /// si no existe.
  Stream<IncidentModel?> watchById(String id) {
    return _incidents
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? IncidentModel.fromFirestore(doc) : null);
  }

  /// Un documento con un tipo o estado que no existe (por ejemplo,
  /// capturado a mano) se omite para no dejar vacía la lista del técnico.
  static IncidentModel? _tryParse(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return IncidentModel.fromFirestore(doc);
    } on FormatException {
      return null;
    }
  }

  /// Nombre para mostrar de la vivienda [id], o `null` si no existe.
  Future<String?> housingLabel(String id) async {
    final doc = await _firestore
        .collection(FirestoreCollections.housings)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    try {
      return HousingModel.fromFirestore(doc).label;
    } on FormatException {
      return null;
    }
  }

  /// Nombre y teléfono del usuario [uid], o `null` si no existe.
  Future<({String? name, String? phone})?> contact(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null) return null;
    return (
      name: data['nombre'] as String?,
      phone: data['telefono'] as String?,
    );
  }
}
