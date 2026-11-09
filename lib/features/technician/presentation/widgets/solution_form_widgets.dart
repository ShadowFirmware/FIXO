import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../domain/entities/assigned_incident.dart';
import '../providers/solution_form_view_model.dart';
import 'local_evidence_viewer.dart';

/// Tarjeta blanca con título, como las secciones del registro de
/// incidencias del residente.
class SolutionFormSection extends StatelessWidget {
  const SolutionFormSection({
    super.key,
    required this.title,
    required this.children,
    this.footnote,
  });

  final String title;
  final List<Widget> children;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              if (footnote != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        footnote!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Incidencia a la que se le registra la solución, de solo lectura.
class SolutionIncidentBanner extends StatelessWidget {
  const SolutionIncidentBanner({super.key, required this.item});

  final AssignedIncident item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final incident = item.incident;

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
            child: const Icon(Icons.task_alt_rounded, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.reportNumber,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  incident.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${incident.type.label} · ${item.housingLabel}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
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

/// Fotos y videos del trabajo realizado, con el botón para agregar más.
class SolutionEvidencePicker extends StatelessWidget {
  const SolutionEvidencePicker({super.key, required this.viewModel});

  final SolutionFormViewModel viewModel;

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
              label: 'Elegir fotos de la galería',
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
                  onRemove: () => viewModel.removeEvidence(file),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const Key('solution.addEvidence'),
          onPressed: viewModel.canAddEvidence
              ? () => _showSources(context)
              : null,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            'Agregar evidencia (${evidence.length}/'
            '${SolutionFormViewModel.maxEvidence})',
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

/// Miniatura cuadrada de una foto o video del dispositivo; al tocarla se
/// abre en pantalla completa. Tiene un botón para quitarla si se indica
/// [onRemove].
class LocalEvidenceThumbnail extends StatelessWidget {
  const LocalEvidenceThumbnail({
    super.key,
    required this.file,
    this.onRemove,
    this.size = 88,
  });

  final EvidenceFile file;
  final VoidCallback? onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: file.isVideo
                ? const ColoredBox(
                    color: AppColors.navy,
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppColors.white,
                      size: 36,
                    ),
                  )
                : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceAlt,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          // Al tocarla se abre en pantalla completa.
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => LocalEvidenceViewer.open(context, file),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: AppColors.darkGray.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
