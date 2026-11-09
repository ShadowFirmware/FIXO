import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../domain/entities/history_incident.dart';
import 'history_incident_widgets.dart';

/// Detalle completo de una incidencia del historial (HU-4.11).
Future<void> showHistoryIncidentDetail(
  BuildContext context,
  HistoryIncident record,
) {
  final incident = record.incident;
  return showAdaptiveForm<void>(
    context: context,
    title: '${incident.reportNumber} · ${incident.title}',
    maxWidth: 560,
    builder: (context) => AdaptiveFormLayout(
      fields: [
        Align(
          alignment: Alignment.centerLeft,
          child: IncidentStatusChip(status: incident.status),
        ),
        const SizedBox(height: 12),
        for (final (label, value) in historyDetailRows(record))
          _DetailRow(label, value),
        const Divider(height: 24),
        _EvidenceSection(
          key: const Key('historyDetail.before'),
          title: 'Evidencias del residente (antes)',
          urls: incident.evidenceBefore,
          emptyText: 'El residente no adjuntó evidencias.',
        ),
        _EvidenceSection(
          key: const Key('historyDetail.after'),
          title: 'Evidencias del técnico (después)',
          urls: incident.evidenceAfter,
          emptyText: afterEvidenceEmptyText(incident.status),
        ),
      ],
      footer: OutlinedButton(
        key: const Key('historyDetail.close'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ),
  );
}

/// Datos del detalle como pares (etiqueta, valor). Solo aparecen la hora
/// estimada, el inicio de la atención, la solución y el rechazo cuando la
/// incidencia los tiene.
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
    if (incident.startedAt != null)
      ('Inicio de la atención', formatHistoryDate(incident.startedAt)),
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

/// Por qué no hay evidencias del técnico: el técnico las registra al
/// resolver la incidencia.
String afterEvidenceEmptyText(IncidentStatus status) => switch (status) {
  IncidentStatus.resolved => 'El técnico no adjuntó evidencias.',
  IncidentStatus.rejected => 'La incidencia fue rechazada; no hay solución.',
  _ => 'El técnico las agregará al resolver la incidencia.',
};

/// Título y miniaturas de un grupo de evidencias.
class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    super.key,
    required this.title,
    required this.urls,
    required this.emptyText,
  });

  final String title;
  final List<String> urls;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          urls.isEmpty ? title : '$title · ${urls.length}',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (urls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              emptyText,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          EvidenceGallery(urls: urls),
      ],
    );
  }
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
