import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../domain/entities/pending_incident.dart';
import '../../domain/entities/rejection_rules.dart';
import '../providers/pending_incidents_view_model.dart';
import 'assign_incident_dialog.dart';
import 'pending_incident_widgets.dart';

/// Formulario para rechazar una incidencia pendiente con el motivo
/// obligatorio (HU-4.10). Devuelve el motivo, o `null` si se canceló.
Future<String?> showRejectIncidentDialog(
  BuildContext context, {
  required PendingIncident pending,
}) {
  return showAdaptiveForm<String>(
    context: context,
    title: 'Rechazar ${pending.incident.reportNumber}',
    builder: (_) => RejectIncidentDialog(pending: pending),
  );
}

class RejectIncidentDialog extends StatefulWidget {
  const RejectIncidentDialog({super.key, required this.pending});

  final PendingIncident pending;

  @override
  State<RejectIncidentDialog> createState() => _RejectIncidentDialogState();
}

class _RejectIncidentDialogState extends State<RejectIncidentDialog> {
  final _comment = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _confirm() {
    final invalid = PendingIncidentsViewModel.validateRejection(_comment.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    Navigator.pop(context, _comment.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveFormLayout(
      fields: [
        PendingIncidentSummary(pending: widget.pending),
        const SizedBox(height: 20),
        TextField(
          key: const Key('reject.comment'),
          controller: _comment,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: RejectionRules.maxLength,
          // Tras el primer error se vuelve a validar mientras escribe.
          onChanged: (_) {
            if (_error == null) return;
            setState(
              () => _error = PendingIncidentsViewModel.validateRejection(
                _comment.text,
              ),
            );
          },
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Explica al residente por qué no procede',
            helperText: 'El residente recibirá este motivo en su notificación.',
            helperMaxLines: 2,
            errorText: _error,
          ),
        ),
      ],
      footer: DialogButtons(
        onCancel: () => Navigator.pop(context),
        confirmLabel: 'Rechazar',
        destructive: true,
        onConfirm: _confirm,
      ),
    );
  }
}

/// Pide confirmar el rechazo mostrando el motivo y sus consecuencias.
/// Devuelve `true` solo si el administrador confirma.
Future<bool> showRejectConfirmation(
  BuildContext context, {
  required PendingIncident pending,
  required String comment,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return AlertDialog(
        title: const Text('Confirmar rechazo'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Rechazar la incidencia ${pending.incident.reportNumber} '
                '"${pending.incident.title}"?',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text('Motivo: $comment', style: textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
              for (final consequence in const [
                'Pasará a Rechazada y no se podrá asignar a un técnico.',
                'El residente recibirá una notificación con este motivo.',
                'Esta acción no se puede deshacer.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          consequence,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          DialogButtons(
            onCancel: () => Navigator.pop(context, false),
            confirmLabel: 'Rechazar',
            destructive: true,
            onConfirm: () => Navigator.pop(context, true),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
