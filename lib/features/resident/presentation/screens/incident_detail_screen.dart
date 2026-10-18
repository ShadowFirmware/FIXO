import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-2.4 Consultar detalles de la incidencia.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixoAppBar(title: 'Incidencia $incidentId'),
      body: PlaceholderView(
        title: 'Detalle de la incidencia $incidentId',
        actions: [
          PlaceholderAction(
            'Abrir chat',
            () => Navigator.pushNamed(
              context,
              RouteNames.incidentChat,
              arguments: incidentId,
            ),
          ),
        ],
      ),
    );
  }
}
