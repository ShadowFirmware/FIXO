import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/assigned_incident.dart';

/// Elemento del historial de incidencias atendidas (HU-3.8): número,
/// estado, nombre, tipo, lugar y fecha de resolución.
class AttendedIncidentCard extends StatelessWidget {
  const AttendedIncidentCard({super.key, required this.item, this.onTap});

  final AssignedIncident item;

  /// Abre el detalle con la solución y las evidencias.
  final VoidCallback? onTap;

  static final _radius = BorderRadius.circular(20);

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
    final resolvedAt = incident.resolvedAt;
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
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(incident.type.icon, color: AppColors.success),
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
              Text(
                resolvedAt == null
                    ? 'Fecha de resolución pendiente'
                    : 'Resuelta el ${DateFormats.dateTime(resolvedAt)}',
                style: secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
