import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../resident/presentation/providers/incident_detail_view_model.dart';
import '../../domain/entities/conduct_report.dart';

/// Opción "Reportar técnico" en el detalle de una incidencia resuelta
/// (T 7.1.1). Si el residente ya lo reportó, muestra su reporte en lugar
/// del botón (T 7.1.6).
class TechnicianConductPanel extends StatelessWidget {
  const TechnicianConductPanel({super.key, required this.viewModel});

  final IncidentDetailViewModel viewModel;

  Future<void> _openForm(BuildContext context) async {
    final target = viewModel.reportTarget;
    if (target == null) return;
    final report = await Navigator.pushNamed<Object?>(
      context,
      RouteNames.reportTechnician,
      arguments: target,
    );
    if (report is ConductReport) viewModel.reportSent(report);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final report = viewModel.ownReport;

    if (report != null) return _SentReport(report: report);

    if (viewModel.isReportLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final blocked =
        viewModel.reportError ?? viewModel.reportBlockReason?.message;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Hubo algún comportamiento o situación inapropiada durante la '
            'atención? Puedes informarlo al administrador.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('detail.reportTechnician'),
            onPressed: viewModel.canReportTechnician
                ? () => _openForm(context)
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Reportar técnico'),
          ),
          if (blocked != null) ...[
            const SizedBox(height: 8),
            Text(
              blocked,
              key: const Key('detail.reportBlocked'),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reporte que el residente ya envió, con su folio y estado.
class _SentReport extends StatelessWidget {
  const _SentReport({required this.report});

  final ConductReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = report.createdAt;

    return Padding(
      key: const Key('detail.sentReport'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flag_outlined,
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
                  'Ya reportaste al técnico',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.reportNumber} · ${report.status.label}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    'Motivo: ${report.reason.label}',
                    if (date != null) DateFormats.dateTime(date),
                  ].join(' · '),
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
