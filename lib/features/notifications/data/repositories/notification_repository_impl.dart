import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/notification_failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({NotificationRemoteDataSource? remote})
    : _remote = remote ?? NotificationRemoteDataSource();

  final NotificationRemoteDataSource _remote;

  @override
  Stream<List<AppNotification>> watchFor(String userId) => _remote
      .watchFor(userId)
      .handleError(
        (Object e) => throw _failureFor(
          e as FirebaseException,
          NotificationFailure.loadFailed,
        ),
        test: (e) => e is FirebaseException,
      );

  @override
  Future<void> markRead(String id) async {
    try {
      await _remote.markRead(id);
    } on FirebaseException catch (e) {
      throw _failureFor(e, NotificationFailure.updateFailed);
    }
  }

  @override
  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _remote.markAllRead(ids);
    } on FirebaseException catch (e) {
      throw _failureFor(e, NotificationFailure.updateFailed);
    }
  }

  static NotificationFailure _failureFor(
    FirebaseException e,
    NotificationFailure fallback,
  ) => switch (e.code) {
    'unavailable' || 'deadline-exceeded' => NotificationFailure.offline,
    _ => fallback,
  };
}
