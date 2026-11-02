import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/history_incident.dart';

/// Fecha y hora para el historial, o "Sin registrar".
String formatHistoryDate(DateTime? date) =>
    date == null ? 'Sin registrar' : DateFormats.dateTime(date);

/// Técnico asignado, o "Sin asignar".
String technicianLabel(HistoryIncident record) =>
    record.technicianName ?? 'Sin asignar';

/// Cuántas evidencias tiene: las del residente (antes) y las del técnico
/// (después).
String evidenceLabel(HistoryIncident record) {
  final before = record.incident.evidenceBefore.length;
  final after = record.incident.evidenceAfter.length;
  if (before + after == 0) return 'Sin evidencias';
  return 'Antes: $before · Después: $after';
}

/// Tarjeta de una incidencia del historial, para la vista móvil.
class HistoryIncidentCard extends StatelessWidget {
  const HistoryIncidentCard({super.key, required this.record, this.onTap});

  final HistoryIncident record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final incident = record.incident;
    final textTheme = Theme.of(context).textTheme;

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
                  const SizedBox(width: 8),
                  IncidentStatusChip(status: incident.status),
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
              HistoryInfoLine(Icons.apartment_outlined, record.housingLabel),
              HistoryInfoLine(Icons.person_outline, record.reporterName),
              HistoryInfoLine(
                Icons.engineering_outlined,
                technicianLabel(record),
              ),
              HistoryInfoLine(
                Icons.schedule_outlined,
                'Creada: ${formatHistoryDate(incident.createdAt)}',
              ),
              if (incident.resolvedAt != null)
                HistoryInfoLine(
                  Icons.check_circle_outline_rounded,
                  'Resuelta: ${formatHistoryDate(incident.resolvedAt)}',
                ),
              HistoryInfoLine(
                Icons.photo_library_outlined,
                evidenceLabel(record),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renglón con ícono y texto secundario.
class HistoryInfoLine extends StatelessWidget {
  const HistoryInfoLine(this.icon, this.text, {super.key});

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
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabla del historial para pantallas anchas.
class HistoryIncidentTable extends StatelessWidget {
  const HistoryIncidentTable({super.key, required this.items, this.onView});

  final List<HistoryIncident> items;
  final ValueChanged<HistoryIncident>? onView;

  @override
  Widget build(BuildContext context) {
    Widget limited(String text, double width) => SizedBox(
      width: width,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );

    return Card(
      color: AppColors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('No. reporte')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Detalles')),
            DataColumn(label: Text('Evidencias')),
            DataColumn(label: Text('Departamento')),
            DataColumn(label: Text('Reportó')),
            DataColumn(label: Text('Técnico')),
            DataColumn(label: Text('Fecha de creación')),
            DataColumn(label: Text('Fecha de resolución')),
          ],
          rows: [
            for (final record in items)
              DataRow(
                onSelectChanged: onView == null ? null : (_) => onView!(record),
                cells: [
                  DataCell(Text(record.incident.reportNumber)),
                  DataCell(limited(record.incident.title, 160)),
                  DataCell(Text(record.incident.type.label)),
                  DataCell(IncidentStatusChip(status: record.incident.status)),
                  DataCell(limited(record.incident.description, 220)),
                  DataCell(Text(evidenceLabel(record))),
                  DataCell(Text(record.housingLabel)),
                  DataCell(limited(record.reporterName, 160)),
                  DataCell(limited(technicianLabel(record), 160)),
                  DataCell(Text(formatHistoryDate(record.incident.createdAt))),
                  DataCell(Text(formatHistoryDate(record.incident.resolvedAt))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado cuando no hay incidencias que mostrar.
class HistoryEmptyMessage extends StatelessWidget {
  const HistoryEmptyMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;

  /// Botón opcional debajo del mensaje, por ejemplo "Limpiar filtros".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Total de incidencias y cuántas hay en cada estado.
class HistoryStatusSummary extends StatelessWidget {
  const HistoryStatusSummary({
    super.key,
    required this.total,
    required this.counts,
  });

  final int total;
  final Map<IncidentStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Chip(label: Text('Total: $total')),
          for (final status in IncidentStatus.values) ...[
            const SizedBox(width: 8),
            Chip(
              key: Key('history.count.${status.value}'),
              avatar: Icon(status.icon, size: 18, color: status.color),
              label: Text('${status.label}: ${counts[status] ?? 0}'),
            ),
          ],
        ],
      ),
    );
  }
}
