import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-2.5 Consultar historial de incidencias.
class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Historial'),
      body: PlaceholderView(
        title: 'Historial de incidencias',
        actions: [
          for (final id in const ['INC-0001', 'INC-0002', 'INC-0003'])
            PlaceholderAction(
              'Ver $id',
              () => Navigator.pushNamed(
                context,
                RouteNames.incidentDetail,
                arguments: id,
              ),
            ),
        ],
      ),
    );
  }
}
