import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Burbuja de un mensaje. Los propios van a la derecha en azul; los de la
/// otra persona, a la izquierda en blanco con su nombre.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.mine,
    required this.time,
    this.author,
    this.pending = false,
  });

  final String text;

  /// `true` si lo envió el usuario en sesión.
  final bool mine;

  /// Hora del mensaje, por ejemplo "4:05 p. m.".
  final String time;

  /// Quién lo envió, por ejemplo "Juan Pérez · Técnico". Solo se muestra en
  /// los mensajes de la otra persona.
  final String? author;

  /// Todavía no llega al servidor.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = mine ? AppColors.white : AppColors.textPrimary;
    final secondary = mine
        ? AppColors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine
                ? null
                : Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine && author != null) ...[
                Text(
                  author!,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                text,
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pending ? 'Enviando…' : time,
                      style: textTheme.labelSmall?.copyWith(color: secondary),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        pending ? Icons.schedule_rounded : Icons.done_rounded,
                        size: 14,
                        color: secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fecha entre los mensajes de días distintos, por ejemplo "Hoy".
class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo para escribir y botón para enviar.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.sending = false,
    this.maxLength = 1000,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chat.input'),
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  // El contador solo estorba; el límite se respeta igual.
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => IconButton.filled(
                  key: const Key('chat.send'),
                  tooltip: 'Enviar',
                  onPressed: sending || value.text.trim().isEmpty
                      ? null
                      : onSend,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso en lugar del campo para escribir cuando no se pueden enviar
/// mensajes, por ejemplo porque la incidencia ya se resolvió.
class ChatNotice extends StatelessWidget {
  const ChatNotice({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('chat.notice'),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon ?? Icons.lock_outline_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado cuando el chat no tiene mensajes o no se puede abrir.
class ChatMessageView extends StatelessWidget {
  const ChatMessageView({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
