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
  Stream<ChatContext?> watchContext(String incidentId) => _remote
      .watchContext(incidentId)
      .handleError(
        (Object e) =>
            throw _failureFor(e as FirebaseException, ChatFailure.loadFailed),
        test: (e) => e is FirebaseException,
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String incidentId) => _remote
      .watchMessages(incidentId)
      .handleError(
        (Object e) =>
            throw _failureFor(e as FirebaseException, ChatFailure.loadFailed),
        test: (e) => e is FirebaseException,
      );

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
