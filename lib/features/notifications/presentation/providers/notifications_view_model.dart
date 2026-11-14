import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/errors/notification_failure.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

enum NotificationsState { loading, ready, error }

/// ViewModel de los avisos del usuario en sesión (HU-6.1).
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    AuthSession? session,
    NotificationRepository? repository,
    DateTime Function()? clock,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? NotificationRepositoryImpl(),
       _clock = clock ?? DateTime.now {
    load();
  }

  final AuthSession _session;
  final NotificationRepository _repository;
  final DateTime Function() _clock;
  StreamSubscription<List<AppNotification>>? _subscription;
  bool _disposed = false;

  NotificationsState _state = NotificationsState.loading;
  NotificationsState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AppNotification> _notifications = const [];

  /// Del más reciente al más antiguo.
  List<AppNotification> get notifications => _notifications;

  /// Cuántos avisos no se han leído.
  int get unreadCount => _notifications.where((n) => !n.read).length;

  static const emptyMessage =
      'No tienes avisos. Aquí verás los cambios de tus incidencias y de tu '
      'cuenta.';

  /// Escucha los avisos del usuario en sesión.
  void load() {
    _subscription?.cancel();
    _subscription = null;
    _state = NotificationsState.loading;
    _errorMessage = null;
    _notify();

    final user = _session.currentUser;
    if (user == null) {
      _notifications = const [];
      _state = NotificationsState.ready;
      _notify();
      return;
    }
    final Stream<List<AppNotification>> stream;
    try {
      stream = _repository.watchFor(user.uid);
    } catch (_) {
      _errorMessage = NotificationFailure.loadFailed.message;
      _state = NotificationsState.error;
      _notify();
      return;
    }
    _subscription = stream.listen(
      (notifications) {
        _notifications = List.unmodifiable(notifications);
        _state = NotificationsState.ready;
        _errorMessage = null;
        _notify();
      },
      onError: (Object error) {
        _errorMessage = error is NotificationFailure
            ? error.message
            : NotificationFailure.loadFailed.message;
        _state = NotificationsState.error;
        _notify();
      },
    );
  }

  /// Marca [notification] como leído al abrirlo. Devuelve el mensaje de
  /// error, o `null` si se marcó (o ya estaba leído).
  Future<String?> open(AppNotification notification) async {
    if (notification.read) return null;
    // Se marca de inmediato en la lista; Firestore lo confirma después.
    _replaceRead({notification.id});
    try {
      await _repository.markRead(notification.id);
      return null;
    } on NotificationFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return NotificationFailure.updateFailed.message;
    }
  }

  bool _markingAll = false;
  bool get isMarkingAll => _markingAll;

  /// Marca como leídos todos los avisos. Devuelve el mensaje de error, o
  /// `null` si se marcaron.
  Future<String?> markAllRead() async {
    final ids = [
      for (final notification in _notifications)
        if (!notification.read) notification.id,
    ];
    if (ids.isEmpty || _markingAll) return null;
    _markingAll = true;
    _notify();
    try {
      await _repository.markAllRead(ids);
      _replaceRead(ids.toSet());
      return null;
    } on NotificationFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return NotificationFailure.updateFailed.message;
    } finally {
      _markingAll = false;
      _notify();
    }
  }

  void _replaceRead(Set<String> ids) {
    _notifications = List.unmodifiable([
      for (final notification in _notifications)
        ids.contains(notification.id)
            ? notification.copyWith(read: true)
            : notification,
    ]);
    _notify();
  }

  /// Pantalla que abre [notification] según el rol del usuario, con sus
  /// argumentos, o `null` si el aviso no lleva a otra pantalla (por
  /// ejemplo, los de la cuenta).
  (String, Object?)? destinationFor(AppNotification notification) {
    final incidentId = notification.incidentId;
    if (incidentId == null) return null;
    return switch (_session.currentUser?.role) {
      UserRole.resident => (RouteNames.incidentDetail, incidentId),
      UserRole.technician => (RouteNames.technicianIncidentDetail, incidentId),
      // El administrador no tiene un detalle por incidencia: las nuevas se
      // asignan desde los reportes pendientes y las demás se consultan en
      // el historial.
      UserRole.admin =>
        notification.type == NotificationType.newIncident
            ? (RouteNames.adminPendingIncidents, null)
            : (RouteNames.adminIncidentHistory, null),
      null => null,
    };
  }

  /// Cuándo llegó [notification], por ejemplo "Hace 5 min" o
  /// "Ayer, 4:05 p. m.".
  String dateLabel(AppNotification notification) =>
      relativeDate(notification.date, _clock());

  static String relativeDate(DateTime? date, DateTime now) {
    if (date == null) return 'Ahora';
    final local = date.toLocal();
    final elapsed = now.difference(local);
    if (elapsed.inMinutes < 1) return 'Hace un momento';
    if (elapsed.inMinutes < 60) return 'Hace ${elapsed.inMinutes} min';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    // En horas redondeadas, por los cambios de horario.
    return switch ((today.difference(day).inHours / 24).round()) {
      0 => 'Hoy, ${DateFormats.time(local)}',
      1 => 'Ayer, ${DateFormats.time(local)}',
      _ => DateFormats.shortDate(local),
    };
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
