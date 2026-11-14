import 'package:flutter/material.dart';

import '../../../../core/services/app_permissions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../providers/notifications_view_model.dart';
import '../widgets/notification_permission.dart';
import '../widgets/notification_widgets.dart';

/// HU-6.1 Recibir notificaciones: pestaña Avisos del residente y del
/// técnico.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.viewModel,
    this.permissions = const DeviceAppPermissions(),
  });

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final NotificationsViewModel? viewModel;

  /// Permisos del teléfono, para el aviso de notificaciones desactivadas.
  final AppPermissions permissions;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final _viewModel = widget.viewModel ?? NotificationsViewModel();

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: FixoAppBar(
        title: 'Avisos',
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => _viewModel.unreadCount == 0
                ? const SizedBox.shrink()
                : FixoAppBarAction(
                    key: const Key('notifications.markAll'),
                    icon: Icons.done_all_rounded,
                    tooltip: 'Marcar todo como leído',
                    onPressed: () =>
                        markAllNotificationsRead(context, _viewModel),
                  ),
          ),
        ],
      ),
      // Dentro del cuerpo, el padding del MediaQuery ya incluye el alto de
      // la barra superior y de la barra flotante.
      body: Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return NotificationsList(
            viewModel: _viewModel,
            header: NotificationsPermissionBanner(
              permissions: widget.permissions,
            ),
            onOpen: (notification) =>
                openNotification(context, _viewModel, notification),
            padding: EdgeInsets.fromLTRB(
              20,
              padding.top + 16,
              20,
              padding.bottom + 24,
            ),
          );
        },
      ),
    );
  }
}
