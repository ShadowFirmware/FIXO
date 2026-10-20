import 'package:flutter/material.dart';

import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-2.2 Modificar perfil.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FixoAppBar(title: 'Modificar perfil'),
      body: PlaceholderView(
        title: 'Modificar perfil',
        actions: [
          PlaceholderAction('Guardar (simulado)', () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
