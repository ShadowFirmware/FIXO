import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key, required this.onSeeHistory});

  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Inicio'),
      body: PlaceholderView(
        title: 'Inicio del residente',
        actions: [
          PlaceholderAction(
            'Registrar incidencia',
            () => Navigator.pushNamed(context, RouteNames.registerIncident),
          ),
          PlaceholderAction(
            'Ver incidencia de ejemplo',
            () => Navigator.pushNamed(
              context,
              RouteNames.incidentDetail,
              arguments: 'INC-0001',
            ),
          ),
          PlaceholderAction('Ver historial', onSeeHistory),
        ],
      ),
    );
  }
}
