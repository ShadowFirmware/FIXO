import 'package:flutter/material.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/pending_incident.dart';
import '../providers/pending_incidents_view_model.dart';
import 'estimated_time_field.dart';
import 'pending_incident_widgets.dart';

/// Técnico y hora elegidos en el formulario de asignación.
class AssignmentSelection {
  const AssignmentSelection({
    required this.technicianId,
    required this.estimatedTime,
  });

  final String technicianId;
  final DateTime estimatedTime;
}

/// Formulario para asignar un técnico y la hora estimada de llegada a una
/// incidencia pendiente (HU-4.9). Devuelve lo elegido, o `null` si se
/// canceló.
Future<AssignmentSelection?> showAssignIncidentDialog(
  BuildContext context, {
  required PendingIncident pending,
  required Future<List<AppUser>> Function() loadTechnicians,
}) {
  return showAdaptiveForm<AssignmentSelection>(
    context: context,
    title: 'Asignar ${pending.incident.reportNumber}',
    builder: (_) => AssignIncidentDialog(
      pending: pending,
      loadTechnicians: loadTechnicians,
    ),
  );
}

class AssignIncidentDialog extends StatefulWidget {
  const AssignIncidentDialog({
    super.key,
    required this.pending,
    required this.loadTechnicians,
  });

  final PendingIncident pending;
  final Future<List<AppUser>> Function() loadTechnicians;

  @override
  State<AssignIncidentDialog> createState() => _AssignIncidentDialogState();
}

class _AssignIncidentDialogState extends State<AssignIncidentDialog> {
  late Future<List<AppUser>> _technicians = widget.loadTechnicians();
  String? _technicianId;

  /// Vuelve a consultar los técnicos si la consulta anterior falló.
  void _retry() => setState(() {
    _technicianId = null;
    _technicians = widget.loadTechnicians();
  });
  DateTime? _estimatedTime;
  String? _error;

  void _confirm() {
    final invalid = PendingIncidentsViewModel.validateAssignment(
      technicianId: _technicianId,
      estimatedTime: _estimatedTime,
    );
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    Navigator.pop(
      context,
      AssignmentSelection(
        technicianId: _technicianId!,
        estimatedTime: _estimatedTime!,
      ),
    );
  }

  /// Error de la hora, que se muestra en cuanto se elige.
  String? _timeError;

  void _setTime(DateTime value) => setState(() {
    _estimatedTime = value;
    _timeError = PendingIncidentsViewModel.validateEstimatedTime(value);
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AdaptiveFormLayout(
      fields: [
        PendingIncidentSummary(pending: widget.pending),
        const SizedBox(height: 20),
        Text('Técnico', style: _sectionStyle(textTheme)),
        const SizedBox(height: 8),
        FutureBuilder<List<AppUser>>(
          future: _technicians,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      snapshot.error is IncidentFailure
                          ? snapshot.error.toString()
                          : IncidentFailure.actionFailed.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('assign.retry'),
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final list = snapshot.data ?? const [];
            if (list.isEmpty) {
              return const Text('No hay técnicos disponibles en este momento.');
            }
            return _TechnicianList(
              technicians: list,
              selectedId: _technicianId,
              onSelected: (id) => setState(() {
                _technicianId = id;
                _error = null;
              }),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Hora estimada de llegada', style: _sectionStyle(textTheme)),
        const SizedBox(height: 8),
        EstimatedTimeField(
          value: _estimatedTime,
          errorText: _timeError,
          onChanged: _setTime,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FormErrorBanner(message: _error!),
        ],
      ],
      footer: DialogButtons(
        key: const Key('assign.buttons'),
        onCancel: () => Navigator.pop(context),
        confirmLabel: 'Asignar',
        onConfirm: _confirm,
      ),
    );
  }

  static TextStyle? _sectionStyle(TextTheme textTheme) => textTheme.titleSmall
      ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold);
}

/// Datos de la incidencia que se va a asignar.
class PendingIncidentSummary extends StatelessWidget {
  const PendingIncidentSummary({super.key, required this.pending});

  final PendingIncident pending;

  @override
  Widget build(BuildContext context) {
    final incident = pending.incident;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(incident.type.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${incident.type.label} · ${pending.housingLabel}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Reportó: ${pending.reporterName} · '
                  '${formatCreatedAt(pending)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Técnicos disponibles como tarjetas seleccionables.
class _TechnicianList extends StatelessWidget {
  const _TechnicianList({
    required this.technicians,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AppUser> technicians;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: technicians.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final technician = technicians[index];
          return _TechnicianTile(
            technician: technician,
            selected: technician.uid == selectedId,
            onTap: () => onSelected(technician.uid),
          );
        },
      ),
    );
  }
}

class _TechnicianTile extends StatelessWidget {
  const _TechnicianTile({
    required this.technician,
    required this.selected,
    required this.onTap,
  });

  final AppUser technician;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final specialty = technician.specialty?.trim() ?? '';
    final details = [
      specialty.isEmpty
          ? 'Sin especialidad'
          : specialty[0].toUpperCase() + specialty.substring(1),
      if (technician.phone.trim().isNotEmpty) technician.phone.trim(),
    ].join(' · ');

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: Key('assign.technician.${technician.uid}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.engineering_outlined,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      details,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
