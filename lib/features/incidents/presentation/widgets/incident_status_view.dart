import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/incident.dart';

/// Color e ícono de cada estado de una incidencia.
extension IncidentStatusStyle on IncidentStatus {
  Color get color => switch (this) {
    IncidentStatus.pending => AppColors.orange,
    IncidentStatus.assigned => AppColors.primary,
    IncidentStatus.inProgress => const Color(0xFF7B1FA2),
    IncidentStatus.resolved => AppColors.success,
    IncidentStatus.rejected => AppColors.error,
  };

  IconData get icon => switch (this) {
    IncidentStatus.pending => Icons.hourglass_empty_rounded,
    IncidentStatus.assigned => Icons.assignment_ind_outlined,
    IncidentStatus.inProgress => Icons.build_circle_outlined,
    IncidentStatus.resolved => Icons.check_circle_outline_rounded,
    IncidentStatus.rejected => Icons.cancel_outlined,
  };

  /// Qué significa el estado para el residente.
  String get description => switch (this) {
    IncidentStatus.pending =>
      'Tu reporte está en espera de que el administrador asigne un técnico.',
    IncidentStatus.assigned =>
      'Un técnico fue asignado y acudirá a la hora estimada.',
    IncidentStatus.inProgress => 'El técnico está atendiendo el problema.',
    IncidentStatus.resolved => 'El problema fue solucionado.',
    IncidentStatus.rejected => 'El administrador rechazó el reporte.',
  };
}

/// Etiqueta con el color del estado.
class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: status.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Avance de la incidencia: Pendiente → Asignada → En proceso → Resuelta.
/// Una incidencia rechazada se queda en el primer paso.
class IncidentStatusProgress extends StatelessWidget {
  const IncidentStatusProgress({super.key, required this.status});

  final IncidentStatus status;

  static const _steps = [
    IncidentStatus.pending,
    IncidentStatus.assigned,
    IncidentStatus.inProgress,
    IncidentStatus.resolved,
  ];

  @override
  Widget build(BuildContext context) {
    final reached = status == IncidentStatus.rejected
        ? 0
        : _steps.indexOf(status);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i <= reached
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.white.withValues(
                      alpha: i <= reached ? 0.95 : 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
