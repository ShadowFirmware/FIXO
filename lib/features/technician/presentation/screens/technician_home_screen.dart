import 'package:flutter/material.dart';

import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// Pantalla de inicio del técnico.
class TechnicianHomeScreen extends StatelessWidget {
  const TechnicianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AuthSession.instance.currentUser?.name;

    return Scaffold(
      appBar: FixoAppBar(title: 'Técnico', subtitle: name),
      body: PlaceholderView(
        title: 'Inicio del técnico',
        actions: [
          PlaceholderAction(
            'Cerrar sesión',
            () => signOutAndGoToLogin(context),
          ),
        ],
      ),
    );
  }
}
