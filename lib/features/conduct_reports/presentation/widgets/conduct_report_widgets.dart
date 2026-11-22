import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../technician/presentation/widgets/solution_form_widgets.dart';
import '../../domain/entities/conduct_report.dart';
import '../providers/report_technician_view_model.dart';

/// Incidencia y técnico que se reportan, de solo lectura: el residente solo
/// puede reportar al técnico que atendió la incidencia.
class ConductTargetBanner extends StatelessWidget {
  const ConductTargetBanner({super.key, required this.target});

  final ConductReportTarget target;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.engineering_outlined,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Técnico reportado',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  target.technicianName,
                  key: const Key('reportTechnician.technician'),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${target.incidentNumber} · ${target.incidentTitle}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

/// Motivos del reporte como fichas seleccionables, con su explicación.
class ConductReasonSelector extends StatelessWidget {
  const ConductReasonSelector({
    super.key,
    required this.reasons,
    required this.selected,
    required this.onSelected,
  });

  final List<ConductReason> reasons;
  final ConductReason? selected;

  /// `null` deshabilita las fichas, por ejemplo mientras se envía.
  final ValueChanged<ConductReason>? onSelected;

  @override
  Widget build(BuildContext context) {
    final hint = selected?.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in reasons)
              ChoiceChip(
                key: Key('reportTechnician.reason.${reason.value}'),
                label: Text(reason.label),
                selected: selected == reason,
                onSelected: onSelected == null
                    ? null
                    : (_) => onSelected!(reason),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 10),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Fotos, videos o capturas del chat, con el botón para agregar más.
class ConductEvidencePicker extends StatelessWidget {
  const ConductEvidencePicker({super.key, required this.viewModel});

  final ReportTechnicianViewModel viewModel;

  Future<void> _showSources(BuildContext context) async {
    final vm = viewModel;
    final action = await showModalBottomSheet<Future<void> Function()>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Tomar foto',
              action: () => vm.addPhotos(fromCamera: true),
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Elegir fotos o capturas de la galería',
              action: () => vm.addPhotos(fromCamera: false),
            ),
            _SourceTile(
              icon: Icons.videocam_outlined,
              label: 'Grabar video (máx. 1 min)',
              action: () => vm.addVideo(fromCamera: true),
            ),
            _SourceTile(
              icon: Icons.video_library_outlined,
              label: 'Elegir video de la galería',
              action: () => vm.addVideo(fromCamera: false),
            ),
          ],
        ),
      ),
    );
    await action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final evidence = viewModel.evidence;
    final message = viewModel.evidenceMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (evidence.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in evidence)
                LocalEvidenceThumbnail(
                  file: file,
                  onRemove: viewModel.isSaving
                      ? null
                      : () => viewModel.removeEvidence(file),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const Key('reportTechnician.addEvidence'),
          onPressed: viewModel.canAddEvidence
              ? () => _showSources(context)
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            'Agregar evidencia (${evidence.length}/'
            '${ReportTechnicianViewModel.maxEvidence})',
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.action,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      // Se cierra la hoja antes de abrir la cámara o la galería.
      onTap: () => Navigator.pop(context, action),
    );
  }
}

/// Explica que el reporte no tiene consecuencias hasta que el administrador
/// lo valida.
class ConductReviewNotice extends StatelessWidget {
  const ConductReviewNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu reporte quedará Pendiente de revisión. El administrador lo '
              'revisará y solo contará como antecedente si lo valida; '
              'mientras tanto no cambia nada en la cuenta del técnico. Solo '
              'puedes enviar un reporte por incidencia.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con título, como las secciones del registro de
/// incidencias.
class ConductFormSection extends StatelessWidget {
  const ConductFormSection({
    super.key,
    required this.title,
    required this.children,
    this.footnote,
  });

  final String title;
  final List<Widget> children;
  final String? footnote;

  @override
  Widget build(BuildContext context) =>
      SolutionFormSection(title: title, footnote: footnote, children: children);
}
