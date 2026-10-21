import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../models/incident_model.dart';

/// Acceso a la colección `incidencias`.
class IncidentRemoteDataSource {
  IncidentRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Documento `contadores/incidencias` con el último folio usado.
  DocumentReference<Map<String, dynamic>> get _counter => _firestore
      .collection(FirestoreCollections.counters)
      .doc(FirestoreCollections.incidents);

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestoreCollections.incidents);

  /// ID para una incidencia nueva, antes de guardarla. Sirve para subir las
  /// evidencias a su carpeta antes de crear el documento.
  String newId() => _incidents.doc().id;

  /// Crea el documento `incidencias/{id}` con el siguiente folio, en una
  /// sola transacción con el contador.
  Future<IncidentModel> create({
    required String id,
    required IncidentModel Function(int folio) build,
  }) {
    return _firestore.runTransaction((transaction) async {
      final folio = await reserveFolio(transaction);
      final incident = build(folio);
      transaction.set(_incidents.doc(id), incident.toFirestore());
      return incident;
    });
  }

  /// Reserva el siguiente folio dentro de [transaction]. Como Firestore
  /// repite la transacción si otro residente registra al mismo tiempo, dos
  /// incidencias nunca reciben el mismo número.
  Future<int> reserveFolio(Transaction transaction) async {
    final counter = await transaction.get(_counter);
    final last = counter.exists
        ? (counter.data()?['ultimoFolio'] as num?)?.toInt() ?? 0
        : await _highestExistingFolio();
    final folio = last + 1;
    transaction.set(_counter, {'ultimoFolio': folio});
    return folio;
  }

  /// La primera vez no existe el contador: se continúa después de las
  /// incidencias que ya se hayan capturado a mano.
  Future<int> _highestExistingFolio() async {
    final last = await _incidents
        .orderBy('folio', descending: true)
        .limit(1)
        .get();
    if (last.docs.isEmpty) return 0;
    return (last.docs.first.data()['folio'] as num?)?.toInt() ?? 0;
  }
}
