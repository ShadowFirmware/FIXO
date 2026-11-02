import 'package:flutter/material.dart';

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
  return showDialog<String>(
    context: context,
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
    return AlertDialog(
      title: Text('Rechazar ${widget.pending.incident.reportNumber}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  helperText:
                      'El residente recibirá este motivo en su notificación.',
                  helperMaxLines: 2,
                  errorText: _error,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        DialogButtons(
          onCancel: () => Navigator.pop(context),
          confirmLabel: 'Rechazar',
          destructive: true,
          onConfirm: _confirm,
        ),
      ],
    );
  }
}
