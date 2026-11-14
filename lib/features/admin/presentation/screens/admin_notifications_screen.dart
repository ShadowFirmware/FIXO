import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../notifications/presentation/providers/notifications_view_model.dart';
import '../../../notifications/presentation/widgets/notification_widgets.dart';
import '../widgets/admin_page.dart';

/// HU-6.1 Recibir notificaciones: avisos del administrador.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final NotificationsViewModel? viewModel;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final _viewModel = widget.viewModel ?? NotificationsViewModel();

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      currentRoute: RouteNames.adminNotifications,
      title: 'Avisos',
      subtitle: 'Incidencias nuevas, cambios y reportes de conducta',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: NotificationsList(viewModel: _viewModel),
        ),
      ),
    );
  }
}
