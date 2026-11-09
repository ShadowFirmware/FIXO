import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/assigned_incident.dart';

/// Elemento de la lista de incidencias asignadas: número, estado, nombre,
/// tipo, lugar, residente, hora estimada de llegada y, si está Asignada,
/// la opción Comenzar atención.
class AssignedIncidentCard extends StatelessWidget {
  const AssignedIncidentCard({
    super.key,
    required this.item,
    this.onTap,
    this.onStartAttention,
    this.starting = false,
  });

  final AssignedIncident item;

  /// Abre el detalle de la incidencia.
  final VoidCallback? onTap;

  /// Comienza la atención (HU-3.5), o `null` si la opción no está
  /// disponible.
  final VoidCallback? onStartAttention;

  /// Se está guardando el inicio de la atención.
  final bool starting;

  static final _radius = BorderRadius.circular(20);

  /// Ícono y texto bajo el reporte: cuándo se resolvió, desde cuándo se
  /// atiende si ya está En proceso, o la llegada estimada si sigue Asignada.
  static (IconData, String)? noteOf(Incident incident) {
    final resolvedAt = incident.resolvedAt;
    if (incident.status == IncidentStatus.resolved && resolvedAt != null) {
      return (
        Icons.task_alt_rounded,
        'Resuelta el ${DateFormats.dateTime(resolvedAt)}',
      );
    }
    final startedAt = incident.startedAt;
    if (incident.status == IncidentStatus.inProgress && startedAt != null) {
      return (
        Icons.build_circle_outlined,
        'En atención desde ${DateFormats.dateTime(startedAt)}',
      );
    }
    final arrival = incident.estimatedTime;
    if (arrival == null) return null;
    return (
      Icons.schedule_rounded,
      'Llegada estimada: ${DateFormats.dateTime(arrival)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _content(Theme.of(context).textTheme),
          ),
        ),
      ),
    );
  }

  Widget _content(TextTheme textTheme) {
    final incident = item.incident;
    final secondary = textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(incident.type.icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.reportNumber,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  IncidentStatusChip(status: incident.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                incident.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${incident.type.label} · ${item.housingLabel}',
                style: secondary,
              ),
              const SizedBox(height: 2),
              Text('Reportó: ${item.residentName}', style: secondary),
              if (noteOf(incident) case final note?) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: incident.status.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(note.$1, size: 16, color: incident.status.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note.$2,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onStartAttention != null || starting) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: Key('assigned.start.${item.id}'),
                  onPressed: starting ? null : onStartAttention,
                  icon: starting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(starting ? 'Comenzando…' : 'Comenzar atención'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
