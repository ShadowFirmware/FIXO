import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../domain/entities/incident_stats.dart';
import 'stats_widgets.dart';

/// Color de cada tipo de incidencia en las gráficas.
Color typeColor(IncidentType type) => switch (type) {
  IncidentType.electricity => const Color(0xFFF9A825),
  IncidentType.water => const Color(0xFF0288D1),
  IncidentType.structure => const Color(0xFF6D4C41),
  IncidentType.other => const Color(0xFF78909C),
};

/// Incidencias por tipo, en el orden de [IncidentType].
List<StatsEntry> typeEntries(IncidentStats stats) => [
  for (final type in IncidentType.values)
    StatsEntry(
      label: type.label,
      count: stats.byType[type] ?? 0,
      color: typeColor(type),
      icon: type.icon,
    ),
];

/// Incidencias por estado, en el orden en que avanza una incidencia.
List<StatsEntry> statusEntries(IncidentStats stats) => [
  for (final status in IncidentStatus.values)
    StatsEntry(
      label: status.label,
      count: stats.countOf(status),
      color: status.color,
      icon: status.icon,
    ),
];

/// Incidencias asignadas a cada técnico, de más a menos.
List<StatsEntry> technicianEntries(IncidentStats stats) => [
  for (final load in stats.byTechnician)
    StatsEntry(
      label:
          '${load.name} · ${load.resolved} '
          '${load.resolved == 1 ? 'resuelta' : 'resueltas'}',
      count: load.assigned,
      color: AppColors.primary,
      icon: Icons.engineering_outlined,
    ),
];
