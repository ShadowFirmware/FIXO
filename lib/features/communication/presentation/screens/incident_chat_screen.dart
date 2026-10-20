import 'package:flutter/material.dart';

import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/placeholder_view.dart';

/// HU-5.1 Chat dentro de una incidencia.
class IncidentChatScreen extends StatelessWidget {
  const IncidentChatScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixoAppBar(title: 'Chat $incidentId'),
      body: PlaceholderView(title: 'Chat de la incidencia $incidentId'),
    );
  }
}
