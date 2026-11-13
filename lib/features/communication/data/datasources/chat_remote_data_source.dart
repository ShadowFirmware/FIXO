import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../models/chat_message_model.dart';

/// Acceso a Firestore para el chat de una incidencia (HU-5.1).
class ChatRemoteDataSource {
  ChatRemoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Se resuelve al usarse para que crear la clase no requiera Firebase
  // inicializado (por ejemplo, en pruebas de widgets).
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String incidentId) =>
      _firestore
          .collection(FirestoreCollections.incidents)
          .doc(incidentId)
          .collection(FirestoreCollections.messages);

  /// Mensajes de la incidencia, del más antiguo al más reciente. Ordenar
  /// por un solo campo no necesita índice compuesto.
  Future<List<ChatMessageModel>> fetchMessages(String incidentId) async {
    final query = await _messages(incidentId).orderBy('fecha').get();
    return _parse(incidentId, query);
  }

  /// Un mensaje con datos inválidos se omite para no ocultar el resto.
  static List<ChatMessageModel> _parse(
    String incidentId,
    QuerySnapshot<Map<String, dynamic>> query,
  ) {
    final messages = <ChatMessageModel>[];
    for (final doc in query.docs) {
      try {
        messages.add(ChatMessageModel.fromMap(doc.id, incidentId, doc.data()));
      } on FormatException {
        continue;
      }
    }
    return messages;
  }
}
