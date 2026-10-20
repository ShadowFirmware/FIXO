import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-2.3 Registrar incidencia.
class RegisterIncidentScreen extends StatelessWidget {
  const RegisterIncidentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Nueva incidencia'),
      body: PlaceholderView(
        title: 'Registrar incidencia',
        actions: [
          // Tras registrar, se reemplaza esta pantalla por el detalle.
          PlaceholderAction(
            'Registrar (simulado)',
            () => Navigator.pushReplacementNamed(
              context,
              RouteNames.incidentDetail,
              arguments: 'INC-0004',
            ),
          ),
        ],
      ),
    );
  }
}
