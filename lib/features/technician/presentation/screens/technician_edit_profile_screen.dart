import 'package:flutter/material.dart';

import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-3.2 Modificar perfil del técnico (pendiente de implementar).
class TechnicianEditProfileScreen extends StatelessWidget {
  const TechnicianEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: FixoAppBar(title: 'Modificar perfil'),
      body: PlaceholderView(title: 'Modificar perfil'),
    );
  }
}
