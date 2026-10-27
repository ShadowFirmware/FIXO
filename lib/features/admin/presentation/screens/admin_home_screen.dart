import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// Pantalla de inicio del administrador.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AuthSession.instance.currentUser?.name;

    return Scaffold(
      appBar: FixoAppBar(
        title: 'Administrador',
        subtitle: name,
        actions: [
          FixoAppBarAction(
            icon: Icons.person_outline_rounded,
            tooltip: 'Mi perfil',
            onPressed: () => Navigator.pushNamed(context, RouteNames.adminProfile),
          ),
        ],
      ),
      body: PlaceholderView(
        title: 'Inicio del administrador',
        actions: [
          PlaceholderAction(
            'Mi perfil',
            () => Navigator.pushNamed(context, RouteNames.adminProfile),
          ),
          PlaceholderAction(
            'Cerrar sesión',
            () => signOutAndGoToLogin(context),
          ),
        ],
      ),
    );
  }
}
