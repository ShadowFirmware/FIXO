import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../incidents/data/models/incident_model.dart';
import '../../domain/entities/chat_access.dart';
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

  /// Incidencia [incidentId], o `null` si no existe.
  Future<IncidentModel?> fetchIncident(String incidentId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.incidents)
        .doc(incidentId)
        .get();
    return doc.exists ? IncidentModel.fromFirestore(doc) : null;
  }

  /// Residente activo de la vivienda [housingId], o `null` si no tiene.
  Future<String?> fetchHousingResident(String housingId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.housings)
        .doc(housingId)
        .get();
    return doc.data()?['residenteActivoId'] as String?;
  }

  /// Mensajes de la incidencia, del más antiguo al más reciente, cada vez
  /// que cambian. Incluye los que se están enviando (sin fecha todavía), así
  /// el mensaje aparece en cuanto se escribe. Ordenar por un solo campo no
  /// necesita índice compuesto.
  Stream<List<ChatMessageModel>> watchMessages(String incidentId) =>
      _messages(incidentId)
          .orderBy('fecha')
          .snapshots(includeMetadataChanges: true)
          .map((query) => _parse(incidentId, query));

  /// Guarda el mensaje de [authorId] en una transacción que antes revisa,
  /// con los datos actuales, que pueda usar el chat. Lanza
  /// [ChatDeniedException] si ya no puede.
  Future<void> sendMessage({
    required String incidentId,
    required String authorId,
    required String text,
  }) {
    return _firestore.runTransaction((transaction) async {
      final incidentDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.incidents).doc(incidentId),
      );
      final authorDoc = await transaction.get(
        _firestore.collection(FirestoreCollections.users).doc(authorId),
      );
      final incidentData = incidentDoc.data();
      final authorData = authorDoc.data();
      if (incidentData == null || authorData == null) {
        throw const ChatDeniedException(ChatAccess.notAllowed);
      }
      final incident = IncidentModel.fromMap(incidentId, incidentData);
      final author = UserModel.fromMap(authorId, authorData);
      final housingDoc = incident.housingId.isEmpty
          ? null
          : await transaction.get(
              _firestore
                  .collection(FirestoreCollections.housings)
                  .doc(incident.housingId),
            );

      final access = ChatAccess.of(
        author,
        ChatContext(
          incident: incident,
          housingResidentId:
              housingDoc?.data()?['residenteActivoId'] as String?,
        ),
      );
      if (!access.canRead) throw ChatDeniedException(access.reason!);

      transaction.set(
        _messages(incidentId).doc(),
        ChatMessageModel.newMessage(
          authorId: authorId,
          authorName: author.name,
          authorRole: author.role,
          text: text,
        ),
      );
    });
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

/// El usuario ya no puede usar el chat, con el motivo.
class ChatDeniedException implements Exception {
  const ChatDeniedException(this.reason);

  final String reason;
}
