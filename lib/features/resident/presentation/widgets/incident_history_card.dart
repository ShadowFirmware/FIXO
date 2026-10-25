import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';

/// Elemento del historial con los datos que identifican el reporte:
/// número, nombre, tipo, fecha de creación y estado.
class IncidentHistoryCard extends StatelessWidget {
  const IncidentHistoryCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  final Incident incident;

  /// Abre el detalle de la incidencia.
  final VoidCallback onTap;

  static final _radius = BorderRadius.circular(20);

  /// Dato adicional según el estado: la llegada del técnico, la solución o
  /// el motivo del rechazo. `null` si no hay nada que agregar.
  static String? noteFor(Incident incident) {
    String? text(String? value) =>
        (value?.trim().isEmpty ?? true) ? null : value!.trim();

    switch (incident.status) {
      case IncidentStatus.assigned:
        final arrival = incident.estimatedTime;
        return arrival == null
            ? null
            : 'Llegada estimada: ${DateFormats.dateTime(arrival)}';
      case IncidentStatus.resolved:
        if (text(incident.solution) case final solution?) {
          return 'Solución: $solution';
        }
        final resolvedAt = incident.resolvedAt;
        return resolvedAt == null
            ? null
            : 'Resuelta el ${DateFormats.longDate(resolvedAt)}';
      case IncidentStatus.rejected:
        if (text(incident.rejectionComment) case final comment?) {
          return 'Motivo del rechazo: $comment';
        }
        final rejectedAt = incident.rejectedAt;
        return rejectedAt == null
            ? null
            : 'Rechazada el ${DateFormats.longDate(rejectedAt)}';
      case IncidentStatus.pending || IncidentStatus.inProgress:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final createdAt = incident.createdAt;

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
            child: _content(textTheme, createdAt),
          ),
        ),
      ),
    );
  }

  Widget _content(TextTheme textTheme, DateTime? createdAt) {
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
                '${incident.type.label} · '
                '${createdAt == null ? 'Fecha pendiente' : DateFormats.longDate(createdAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (noteFor(incident) case final note?) ...[
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
                  child: Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
