import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';
import '../../../auth/presentation/providers/auth_session.dart';

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key, required this.onSeeHistory});

  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    final name = AuthSession.instance.currentUser?.name;

    return Scaffold(
      appBar: FixoAppBar(
        title: 'Inicio',
        subtitle: name == null ? null : 'Hola, $name',
      ),
      body: PlaceholderView(
        title: 'Inicio del residente',
        actions: [
          PlaceholderAction(
            'Registrar incidencia',
            () => Navigator.pushNamed(context, RouteNames.registerIncident),
          ),
          PlaceholderAction('Ver historial', onSeeHistory),
        ],
      ),
    );
  }
}
