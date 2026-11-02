import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/pending_incident.dart';
import '../providers/pending_incidents_view_model.dart';
import 'assign_incident_dialog.dart';

String formatCreatedAt(PendingIncident pending) {
  final date = pending.incident.createdAt;
  return date == null ? 'Sin registrar' : DateFormats.dateTime(date);
}

/// Tarjeta de una incidencia pendiente, para el inicio y la vista móvil.
class PendingIncidentCard extends StatelessWidget {
  const PendingIncidentCard({
    super.key,
    required this.pending,
    required this.onTap,
    this.onAssign,
    this.onReject,
  });

  final PendingIncident pending;
  final VoidCallback onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final incident = pending.incident;
    final textTheme = Theme.of(context).textTheme;
    final evidences = incident.evidenceBefore.length;

    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      incident.type.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${incident.reportNumber} · ${incident.type.label}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              _InfoLine(Icons.apartment_outlined, pending.housingLabel),
              _InfoLine(Icons.person_outline, pending.reporterName),
              _InfoLine(Icons.schedule_outlined, formatCreatedAt(pending)),
              _InfoLine(
                Icons.photo_library_outlined,
                evidences == 0
                    ? 'Sin evidencias'
                    : '$evidences evidencia${evidences == 1 ? '' : 's'}',
              ),
              if (onAssign != null || onReject != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.engineering_outlined),
                        label: const Text('Asignar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle completo de una incidencia pendiente, con sus evidencias.
Future<void> showPendingIncidentDetail(
  BuildContext context,
  PendingIncident pending,
) {
  final incident = pending.incident;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${incident.reportNumber} · ${incident.title}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Tipo', incident.type.label),
              _DetailRow('Estado', incident.status.label),
              _DetailRow('Departamento', pending.housingLabel),
              _DetailRow('Reportada por', pending.reporterName),
              _DetailRow('Fecha de creación', formatCreatedAt(pending)),
              _DetailRow(
                'Detalles',
                incident.description.trim().isEmpty
                    ? 'Sin registrar'
                    : incident.description,
              ),
              const SizedBox(height: 8),
              Text(
                'Evidencias',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              EvidenceGallery(urls: incident.evidenceBefore),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Diálogos de las opciones Asignar y Rechazar. Devuelven el mensaje para
/// mostrar en un SnackBar, o `null` si se canceló.
class PendingIncidentActions {
  PendingIncidentActions(this.context, this.viewModel);

  final BuildContext context;
  final PendingIncidentsViewModel viewModel;

  Future<void> reject(PendingIncident pending) async {
    final controller = TextEditingController();
    String? error;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rechazar ${pending.incident.reportNumber}'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Motivo del rechazo',
                hintText: 'Explica al residente por qué no procede',
                errorText: error,
              ),
            ),
          ),
          actions: [
            DialogButtons(
              onCancel: () => Navigator.pop(context),
              confirmLabel: 'Rechazar',
              destructive: true,
              onConfirm: () {
                final invalid = PendingIncidentsViewModel.validateRejection(
                  controller.text,
                );
                if (invalid != null) {
                  setState(() => error = invalid);
                  return;
                }
                Navigator.pop(context, controller.text.trim());
              },
            ),
          ],
        ),
      ),
    );
    if (comment == null || !context.mounted) return;

    final confirmed = await _confirm(
      title: 'Confirmar rechazo',
      message:
          '¿Rechazar la incidencia ${pending.incident.reportNumber}? '
          'Esta acción es definitiva y se notificará al residente.',
      confirmLabel: 'Rechazar',
    );
    if (!confirmed) return;

    await viewModel.reject(pending, comment: comment);
    _showResult();
  }

  Future<void> assign(PendingIncident pending) async {
    final selection = await showAssignIncidentDialog(
      context,
      pending: pending,
      loadTechnicians: viewModel.availableTechnicians,
    );
    if (selection == null) return;

    await viewModel.assign(
      pending,
      technicianId: selection.technicianId,
      estimatedTime: selection.estimatedTime,
    );
    _showResult();
  }

  void _showResult() {
    if (!context.mounted) return;
    final message = viewModel.successMessage ?? viewModel.errorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          DialogButtons(
            onCancel: () => Navigator.pop(context, false),
            confirmLabel: confirmLabel,
            onConfirm: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

/// Botones Cancelar / Confirmar de los modales, del mismo ancho.
class DialogButtons extends StatelessWidget {
  const DialogButtons({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.destructive = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    )
                  : null,
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
