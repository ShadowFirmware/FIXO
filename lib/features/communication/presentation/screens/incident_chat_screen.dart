import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../providers/chat_view_model.dart';
import '../widgets/chat_widgets.dart';

/// HU-5.1 Comunicarse mediante chat dentro de una incidencia.
class IncidentChatScreen extends StatefulWidget {
  const IncidentChatScreen({
    super.key,
    required this.incidentId,
    this.viewModel,
  });

  final String incidentId;

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final ChatViewModel? viewModel;

  @override
  State<IncidentChatScreen> createState() => _IncidentChatScreenState();
}

class _IncidentChatScreenState extends State<IncidentChatScreen> {
  late final _viewModel =
      widget.viewModel ?? ChatViewModel(incidentId: widget.incidentId);
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  void _send() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: const FixoAppBar(title: 'Chat de la incidencia'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: ChatMessageView(
                icon: Icons.forum_outlined,
                text: ChatViewModel.noMessagesMessage,
              ),
            ),
            ChatComposer(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}
