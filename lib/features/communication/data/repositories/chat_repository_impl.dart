import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/chat_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatRemoteDataSource? remote})
    : _remote = remote ?? ChatRemoteDataSource();

  final ChatRemoteDataSource _remote;

  @override
  Future<List<ChatMessage>> messages(String incidentId) async {
    try {
      return await _remote.fetchMessages(incidentId);
    } on FirebaseException catch (e) {
      throw _failureFor(e, ChatFailure.loadFailed);
    }
  }

  static ChatFailure _failureFor(FirebaseException e, ChatFailure fallback) =>
      switch (e.code) {
        'unavailable' || 'deadline-exceeded' => ChatFailure.offline,
        _ => fallback,
      };
}
