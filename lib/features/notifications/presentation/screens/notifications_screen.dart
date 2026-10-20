import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-6.1 Recibir notificaciones.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Avisos'),
      body: PlaceholderView(
        title: 'Notificaciones',
        actions: [
          PlaceholderAction(
            'Notificación: INC-0002 asignada',
            () => Navigator.pushNamed(
              context,
              RouteNames.incidentDetail,
              arguments: 'INC-0002',
            ),
          ),
        ],
      ),
    );
  }
}
