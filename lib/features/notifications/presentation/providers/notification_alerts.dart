import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/datasources/system_notifier.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notifications_view_model.dart';

/// Muestra en el teléfono los avisos nuevos del usuario en sesión (HU-6.1).
///
/// Mientras hay sesión escucha sus avisos; los que ya existían al entrar no
/// se vuelven a notificar, solo los que llegan después. Al tocar una
/// notificación se marca como leída y se abre la pantalla del aviso.
class NotificationAlerts {
  NotificationAlerts({
    required this.navigatorKey,
    AuthSession? session,
    NotificationRepository? repository,
    SystemNotifier? notifier,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? NotificationRepositoryImpl(),
       _notifier = notifier ?? LocalSystemNotifier();

  /// Navegador de la app, para abrir el aviso al tocar su notificación.
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthSession _session;
  final NotificationRepository _repository;
  final SystemNotifier _notifier;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _uid;

  /// Avisos ya conocidos: no se notifican otra vez.
  Set<String>? _known;

  /// Empieza a seguir la sesión.
  Future<void> attach() async {
    _session.addListener(_onSession);
    try {
      await _notifier.init(onOpen: _open);
    } catch (_) {
      // Sin notificaciones del sistema la app funciona igual.
    }
    _onSession();
  }

  void _onSession() {
    final user = _session.currentUser;
    if (user?.uid == _uid) return;
    _stop();
    if (user == null) return;
    _uid = user.uid;
    try {
      _subscription = _repository
          .watchFor(user.uid)
          .listen(_onNotifications, onError: (Object _) {});
    } catch (_) {
      // Si no se pueden consultar, los avisos se verán en la app.
    }
  }

  void _onNotifications(List<AppNotification> notifications) {
    final ids = {for (final n in notifications) n.id};
    final known = _known;
    _known = {...?known, ...ids};
    // La primera lista son los avisos que ya tenía: no se notifican.
    if (known == null) return;
    for (final notification in notifications) {
      if (known.contains(notification.id) ||
          notification.read ||
          notification.userId != _uid) {
        continue;
      }
      _notifier.show(notification).catchError((Object _) {});
    }
  }

  void _open(AppNotification notification) {
    final role = _session.currentUser?.role;
    // Solo se abre si el aviso es del usuario que tiene la sesión.
    if (role == null || notification.userId != _session.currentUser?.uid) {
      return;
    }
    _repository.markRead(notification.id).catchError((Object _) {});
    final destination = NotificationsViewModel.destinationOf(
      role,
      notification,
    );
    if (destination case (final route, final arguments)) {
      navigatorKey.currentState?.pushNamed(route, arguments: arguments);
    }
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _known = null;
  }

  void dispose() {
    _session.removeListener(_onSession);
    _stop();
  }
}
