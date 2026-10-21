import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../providers/register_incident_view_model.dart';

/// HU-2.3 Registrar incidencia.
class RegisterIncidentScreen extends StatefulWidget {
  const RegisterIncidentScreen({super.key});

  @override
  State<RegisterIncidentScreen> createState() => _RegisterIncidentScreenState();
}

class _RegisterIncidentScreenState extends State<RegisterIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _viewModel = RegisterIncidentViewModel();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(
      () => _viewModel.title = _titleController.text,
    );
    _descriptionController.addListener(
      () => _viewModel.description = _descriptionController.text,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Oculta el contador de caracteres que agrega `maxLength` en el título.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;

  void _submit() {
    FocusScope.of(context).unfocus();
    // Se validan todos para marcar cada error, no solo el primero.
    final fieldsValid = _formKey.currentState!.validate();
    final restValid = _viewModel.validate() == null;
    if (!fieldsValid || !restValid) return;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Nueva incidencia'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          padding.top + 16,
          20,
          padding.bottom + 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormSection(
                    title: 'Datos de la incidencia',
                    children: [
                      TextFormField(
                        key: const Key('registerIncident.title'),
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: RegisterIncidentViewModel.maxTitleLength,
                        buildCounter: _hideCounter,
                        validator: Validators.incidentTitle,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Fuga en el baño',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Tipo de incidencia'),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeSelector(
                              selected: _viewModel.type,
                              onSelected: _viewModel.selectType,
                            ),
                            if (_viewModel.typeError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _viewModel.typeError!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('registerIncident.description'),
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 4,
                        maxLines: 8,
                        maxLength:
                            RegisterIncidentViewModel.maxDescriptionLength,
                        validator: Validators.incidentDescription,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe el problema con detalle',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _FormSection(
                    title: 'Evidencias',
                    footnote:
                        'Agrega fotografías o videos del problema. Los videos '
                        'pueden durar hasta 1 minuto.',
                    children: [
                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) =>
                            _EvidenceSection(viewModel: _viewModel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Registrar incidencia'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tipos de incidencia como fichas seleccionables.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onSelected});

  final IncidentType? selected;
  final ValueChanged<IncidentType> onSelected;

  static IconData _iconFor(IncidentType type) => switch (type) {
    IncidentType.electricity => Icons.lightbulb_outline_rounded,
    IncidentType.water => Icons.water_drop_outlined,
    IncidentType.structure => Icons.foundation_rounded,
    IncidentType.other => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in IncidentType.values)
          ChoiceChip(
            key: Key('registerIncident.type.${type.value}'),
            avatar: Icon(_iconFor(type), size: 18),
            label: Text(type.label),
            selected: selected == type,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}

/// Miniaturas de las evidencias elegidas y botón para agregar más.
class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.viewModel});

  final RegisterIncidentViewModel viewModel;

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
                _EvidenceThumbnail(
                  file: file,
                  onRemove: () => viewModel.removeEvidence(file),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const Key('registerIncident.addEvidence'),
          onPressed: viewModel.canAddEvidence
              ? () => _showSources(context)
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            'Agregar evidencia (${evidence.length}/'
            '${RegisterIncidentViewModel.maxEvidence})',
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

/// Miniatura cuadrada de una foto o video, con botón para quitarla.
class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.file, required this.onRemove});

  final EvidenceFile file;
  final VoidCallback onRemove;

  static const _size = 88.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
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
                    cacheWidth: 200,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceAlt,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Tarjeta blanca con título, como las secciones del perfil.
class _FormSection extends StatelessWidget {
  const _FormSection({
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
