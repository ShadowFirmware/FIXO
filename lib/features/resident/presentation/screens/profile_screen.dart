import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// HU-2.1 Consultar perfil.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthSession.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Perfil'),
      body: PlaceholderView(
        title: 'Perfil del residente',
        actions: [
          PlaceholderAction(
            'Modificar perfil',
            () => Navigator.pushNamed(context, RouteNames.editProfile),
          ),
          PlaceholderAction('Cerrar sesión', () => _signOut(context)),
        ],
      ),
    );
  }
}
