import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../domain/entities/history_incident.dart';
import 'history_incident_widgets.dart';

/// Detalle completo de una incidencia del historial (HU-4.11).
Future<void> showHistoryIncidentDetail(
  BuildContext context,
  HistoryIncident record,
) {
  final incident = record.incident;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${incident.reportNumber} · ${incident.title}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IncidentStatusChip(status: incident.status),
              ),
              const SizedBox(height: 12),
              for (final (label, value) in historyDetailRows(record))
                _DetailRow(label, value),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('historyDetail.close'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    ),
  );
}

/// Datos del detalle como pares (etiqueta, valor). Solo aparecen la hora
/// estimada, la solución y el rechazo cuando la incidencia los tiene.
List<(String, String)> historyDetailRows(HistoryIncident record) {
  final incident = record.incident;
  String orMissing(String? text) =>
      text == null || text.trim().isEmpty ? 'Sin registrar' : text.trim();

  return [
    ('Tipo', incident.type.label),
    ('Departamento', record.housingLabel),
    ('Reportada por', record.reporterName),
    ('Técnico asignado', technicianLabel(record)),
    ('Fecha de creación', formatHistoryDate(incident.createdAt)),
    if (incident.estimatedTime != null)
      ('Hora estimada de llegada', formatHistoryDate(incident.estimatedTime)),
    ('Fecha de resolución', formatHistoryDate(incident.resolvedAt)),
    ('Detalles', orMissing(incident.description)),
    if (incident.status == IncidentStatus.resolved || incident.solution != null)
      ('Solución', orMissing(incident.solution)),
    if (incident.status == IncidentStatus.rejected) ...[
      ('Motivo del rechazo', orMissing(incident.rejectionComment)),
      ('Fecha del rechazo', formatHistoryDate(incident.rejectedAt)),
    ],
  ];
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
