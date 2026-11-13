import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
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

  Future<void> _send() async {
    final text = _input.text;
    final error = await _viewModel.send(text);
    if (!mounted) return;
    if (error == null) {
      _input.clear();
      return;
    }
    // Si falla, el texto se conserva para volver a intentarlo.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.surfaceAlt,
        appBar: FixoAppBar(
          title: 'Chat de la incidencia',
          subtitle: switch (_viewModel.incident) {
            final incident? => '${incident.reportNumber} · ${incident.title}',
            null => null,
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _body()),
            // Solo se escribe si se pudo abrir el chat.
            if (_viewModel.state == ChatState.ready)
              ChatComposer(
                controller: _input,
                onSend: _send,
                sending: _viewModel.isSending,
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final vm = _viewModel;
    switch (vm.state) {
      case ChatState.loading:
        return const Center(child: CircularProgressIndicator());
      case ChatState.error || ChatState.denied:
        return ChatMessageView(
          icon: vm.state == ChatState.denied
              ? Icons.lock_outline_rounded
              : Icons.error_outline_rounded,
          text: vm.errorMessage ?? '',
        );
      case ChatState.ready when vm.messages.isEmpty:
        return const ChatMessageView(
          icon: Icons.forum_outlined,
          text: ChatViewModel.noMessagesMessage,
        );
      case ChatState.ready:
        final messages = vm.messages;
        return ListView.builder(
          key: const Key('chat.messages'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final sentAt = message.sentAt;
            return ChatBubble(
              key: ValueKey(message.id),
              text: message.text,
              mine: vm.isMine(message),
              time: sentAt == null ? '' : DateFormats.time(sentAt),
              pending: message.isPending,
            );
          },
        );
    }
  }
}
