import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_view_model.dart';

/// Ícono y color de cada tipo de aviso.
(IconData, Color) notificationStyle(NotificationType? type) => switch (type) {
  NotificationType.newIncident => (
    Icons.assignment_late_outlined,
    AppColors.orange,
  ),
  NotificationType.incidentAssigned => (
    Icons.engineering_outlined,
    AppColors.primary,
  ),
  NotificationType.incidentInProgress => (
    Icons.play_circle_outline_rounded,
    AppColors.primary,
  ),
  NotificationType.incidentResolved => (
    Icons.task_alt_rounded,
    AppColors.success,
  ),
  NotificationType.incidentRejected => (Icons.cancel_outlined, AppColors.error),
  NotificationType.conductReport => (Icons.flag_outlined, AppColors.orange),
  NotificationType.conductWarning => (
    Icons.warning_amber_rounded,
    AppColors.orange,
  ),
  NotificationType.accountSuspended => (
    Icons.pause_circle_outline_rounded,
    AppColors.error,
  ),
  NotificationType.accountReactivated => (
    Icons.verified_user_outlined,
    AppColors.success,
  ),
  NotificationType.accountDisabled => (Icons.block_rounded, AppColors.error),
  null => (Icons.notifications_none_rounded, AppColors.primary),
};

/// Un aviso de la lista. Los que no se han leído se resaltan con un punto
/// y el título en negritas.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.dateLabel,
    this.onTap,
  });

  final AppNotification notification;

  /// Cuándo llegó, por ejemplo "Hace 5 min".
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.read;
    final (icon, color) = notificationStyle(notification.type);
    final radius = BorderRadius.circular(16);

    return Material(
      color: unread
          ? Color.alphaBlend(
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.white,
            )
          : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: unread
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            key: const Key('notification.unread'),
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado cuando no hay avisos o no se pudieron cargar.
class NotificationsMessage extends StatelessWidget {
  const NotificationsMessage({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// Avisos con sus estados (cargando, error y vacío). La usan la pestaña
/// Avisos del residente y del técnico, y la sección del administrador.
class NotificationsList extends StatelessWidget {
  const NotificationsList({
    super.key,
    required this.viewModel,
    this.onOpen,
    this.padding = const EdgeInsets.all(20),
    this.header,
  });

  final NotificationsViewModel viewModel;

  /// Arriba de la lista, en todos los estados; por ejemplo, el aviso de
  /// que las notificaciones del teléfono están desactivadas.
  final Widget? header;

  /// Al tocar un aviso.
  final void Function(AppNotification notification)? onOpen;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    if (header == null) return _content(padding);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          child: header,
        ),
        Expanded(child: _content(padding.copyWith(top: 12))),
      ],
    );
  }

  Widget _content(EdgeInsets padding) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        switch (vm.state) {
          case NotificationsState.loading:
            return const Center(child: CircularProgressIndicator());
          case NotificationsState.error:
            return NotificationsMessage(
              icon: Icons.error_outline_rounded,
              message: vm.errorMessage ?? '',
              action: OutlinedButton.icon(
                key: const Key('notifications.retry'),
                onPressed: vm.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            );
          case NotificationsState.ready when vm.notifications.isEmpty:
            return const NotificationsMessage(
              icon: Icons.notifications_none_rounded,
              message: NotificationsViewModel.emptyMessage,
            );
          case NotificationsState.ready:
            final notifications = vm.notifications;
            return ListView.separated(
              key: const Key('notifications.list'),
              padding: padding,
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  key: ValueKey(notification.id),
                  notification: notification,
                  dateLabel: vm.dateLabel(notification),
                  onTap: onOpen == null ? null : () => onOpen!(notification),
                );
              },
            );
        }
      },
    );
  }
}

/// Marca [notification] como leído y abre la pantalla a la que lleva, si
/// lleva a una.
Future<void> openNotification(
  BuildContext context,
  NotificationsViewModel viewModel,
  AppNotification notification,
) async {
  final destination = viewModel.destinationFor(notification);
  if (destination case (final route, final arguments)) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
  final error = await viewModel.open(notification);
  if (error != null && context.mounted) {
    showNotificationsMessage(context, error);
  }
}

/// Marca como leídos todos los avisos y avisa si falla.
Future<void> markAllNotificationsRead(
  BuildContext context,
  NotificationsViewModel viewModel,
) async {
  final error = await viewModel.markAllRead();
  if (!context.mounted) return;
  showNotificationsMessage(
    context,
    error ?? 'Marcaste todos los avisos como leídos.',
  );
}

void showNotificationsMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
