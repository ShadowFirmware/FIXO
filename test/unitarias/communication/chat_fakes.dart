import 'dart:async';

import 'package:fixo/core/errors/chat_failure.dart';
import 'package:fixo/features/auth/domain/entities/app_user.dart';
import 'package:fixo/features/communication/data/datasources/chat_remote_data_source.dart';
import 'package:fixo/features/communication/data/models/chat_message_model.dart';
import 'package:fixo/features/communication/domain/entities/chat_access.dart';
import 'package:fixo/features/communication/domain/entities/chat_message.dart';
import 'package:fixo/features/communication/domain/repositories/chat_repository.dart';
import 'package:fixo/features/incidents/data/models/incident_model.dart';
import 'package:fixo/features/incidents/domain/entities/incident.dart';

/// UID de `TestUsers.resident()` y `TestUsers.technician`.
const residentUid = 'uid-residente';
const technicianUid = 'uid-tecnico';

/// Incidencia del chat, En proceso y asignada al técnico de prueba.
IncidentModel chatIncident({
  IncidentStatus status = IncidentStatus.inProgress,
  String? technician = technicianUid,
  bool chatClosed = false,
  String housingId = 'vivienda-4b',
}) => IncidentModel(
  id: 'inc-1',
  folio: 1,
  title: 'Fuga en el baño',
  type: IncidentType.water,
  description: 'Gotea la tubería del baño.',
  housingId: housingId,
  createdBy: residentUid,
  status: status,
  technicianId: technician,
  chatClosed: chatClosed,
  createdAt: DateTime(2026, 11),
);

/// Contexto en el que [resident] es el residente activo de la vivienda.
ChatContext chatContext({
  IncidentModel? incident,
  String? resident = residentUid,
}) => ChatContext(
  incident: incident ?? chatIncident(),
  housingResidentId: resident,
);

/// Mensaje [id] de [authorId]. Sin [sentAt], se está enviando.
ChatMessage chatMessage(
  String id, {
  String authorId = residentUid,
  String authorName = 'María López Hernández',
  UserRole authorRole = UserRole.resident,
  String text = 'Hola',
  DateTime? sentAt,
}) => ChatMessageModel(
  id: id,
  incidentId: 'inc-1',
  authorId: authorId,
  authorName: authorName,
  authorRole: authorRole,
  text: text,
  sentAt: sentAt,
);

/// Simula el repositorio: las pruebas emiten el contexto y los mensajes a
/// mano, como lo haría Firestore.
class FakeChatRepository implements ChatRepository {
  final contextController = StreamController<ChatContext?>.broadcast();
  final messagesController = StreamController<List<ChatMessage>>.broadcast();

  /// Veces que se abrió cada stream.
  var contextListens = 0;
  var messageListens = 0;

  /// Mensajes enviados: (incidencia, autor, texto).
  final sent = <(String, String, String)>[];

  /// Error que lanza `send`, si hay.
  Object? sendError;

  /// Se completa para terminar el envío; si es `null`, termina de inmediato.
  Completer<void>? sendGate;

  @override
  Stream<ChatContext?> watchContext(String incidentId) {
    contextListens++;
    return contextController.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String incidentId) {
    messageListens++;
    return messagesController.stream;
  }

  /// `true` mientras el ViewModel escucha los mensajes.
  bool get listeningMessages => messagesController.hasListener;

  @override
  Future<void> send({
    required String incidentId,
    required String authorId,
    required String text,
  }) async {
    await sendGate?.future;
    if (sendError case final error?) throw error;
    sent.add((incidentId, authorId, text));
  }

  Future<void> close() async {
    await contextController.close();
    await messagesController.close();
  }
}

/// Simula Firestore para probar cómo el repositorio traduce los errores.
class FakeChatRemoteDataSource extends ChatRemoteDataSource {
  final contextController = StreamController<ChatContext?>.broadcast();
  final messagesController =
      StreamController<List<ChatMessageModel>>.broadcast();

  /// Error que lanza `sendMessage`, si hay.
  Object? sendError;

  @override
  Stream<ChatContext?> watchContext(String incidentId) =>
      contextController.stream;

  @override
  Stream<List<ChatMessageModel>> watchMessages(String incidentId) =>
      messagesController.stream;

  @override
  Future<void> sendMessage({
    required String incidentId,
    required String authorId,
    required String text,
  }) async {
    if (sendError case final error?) throw error;
  }
}

/// Mensaje del [ChatFailure] que emite [stream], o `null` si emite otra
/// cosa.
Future<String?> failureOf(Stream<Object?> stream) async {
  try {
    await stream.first;
    return null;
  } on ChatFailure catch (failure) {
    return failure.message;
  }
}
