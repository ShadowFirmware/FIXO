import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/chat_failure.dart';
import '../../domain/entities/chat_access.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatRemoteDataSource? remote})
    : _remote = remote ?? ChatRemoteDataSource();

  final ChatRemoteDataSource _remote;

  @override
  Future<ChatContext?> context(String incidentId) async {
    try {
      final incident = await _remote.fetchIncident(incidentId);
      if (incident == null) return null;
      final housingId = incident.housingId;
      return ChatContext(
        incident: incident,
        housingResidentId: housingId.isEmpty
            ? null
            : await _remote.fetchHousingResident(housingId),
      );
    } on FirebaseException catch (e) {
      throw _failureFor(e, ChatFailure.loadFailed);
    }
  }

  @override
  Future<List<ChatMessage>> messages(String incidentId) async {
    try {
      return await _remote.fetchMessages(incidentId);
    } on FirebaseException catch (e) {
      throw _failureFor(e, ChatFailure.loadFailed);
    }
  }

  @override
  Future<void> send({
    required String incidentId,
    required String authorId,
    required String text,
  }) async {
    try {
      await _remote.sendMessage(
        incidentId: incidentId,
        authorId: authorId,
        text: text,
      );
    } on ChatDeniedException catch (e) {
      throw ChatFailure(e.reason);
    } on FirebaseException catch (e) {
      throw _failureFor(e, ChatFailure.sendFailed);
    }
  }

  static ChatFailure _failureFor(FirebaseException e, ChatFailure fallback) =>
      switch (e.code) {
        'unavailable' || 'deadline-exceeded' => ChatFailure.offline,
        _ => fallback,
      };
}
