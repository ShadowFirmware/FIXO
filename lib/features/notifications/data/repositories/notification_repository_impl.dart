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

  static NotificationFailure _failureFor(
    FirebaseException e,
    NotificationFailure fallback,
  ) => switch (e.code) {
    'unavailable' || 'deadline-exceeded' => NotificationFailure.offline,
    _ => fallback,
  };
}
