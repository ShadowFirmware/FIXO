import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/assigned_incident.dart';

/// Elemento del historial de incidencias atendidas (HU-3.8): número,
/// estado, nombre, tipo, lugar, fecha de resolución, resumen de la solución,
/// evidencias y cuánto tardó la atención.
class AttendedIncidentCard extends StatelessWidget {
  const AttendedIncidentCard({super.key, required this.item, this.onTap});

  final AssignedIncident item;

  /// Abre el detalle con la solución y las evidencias.
  final VoidCallback? onTap;

  static final _radius = BorderRadius.circular(20);

  /// Cuánto tardó la atención, desde que el técnico la comenzó hasta que la
  /// finalizó, por ejemplo "2 h 15 min". `null` si falta alguna fecha.
  static String? attentionTime(Incident incident) {
    final start = incident.startedAt;
    final end = incident.resolvedAt;
    if (start == null || end == null || end.isBefore(start)) return null;
    final minutes = end.difference(start).inMinutes;
    final days = minutes ~/ (24 * 60);
    final hours = minutes % (24 * 60) ~/ 60;
    final rest = minutes % 60;
    if (days > 0) return hours > 0 ? '$days d $hours h' : '$days d';
    if (hours > 0) return rest > 0 ? '$hours h $rest min' : '$hours h';
    return '$rest min';
  }

  /// Por ejemplo "1 evidencia" o "3 evidencias".
  static String evidenceCount(Incident incident) {
    final count = incident.evidenceAfter.length;
    return '$count ${count == 1 ? 'evidencia' : 'evidencias'}';
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
              if (incident.solution?.trim() case final solution?
                  when solution.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Solución: $solution',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Fact(
                    icon: Icons.perm_media_outlined,
                    text: evidenceCount(incident),
                    style: secondary,
                  ),
                  if (attentionTime(incident) case final time?)
                    _Fact(
                      icon: Icons.timer_outlined,
                      text: 'Atendida en $time',
                      style: secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}
