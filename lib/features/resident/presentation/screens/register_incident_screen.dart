import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
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
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Fuga en el baño',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Tipo de incidencia'),
                      const SizedBox(height: 8),
                      const _TypeSelector(),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('registerIncident.description'),
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe el problema con detalle',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FormSection(
                    title: 'Evidencias',
                    footnote: 'Agrega fotografías o videos del problema.',
                    children: [_EvidencePlaceholder()],
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
  const _TypeSelector();

  static const _types = [
    (Icons.lightbulb_outline_rounded, 'Luz'),
    (Icons.water_drop_outlined, 'Agua'),
    (Icons.foundation_rounded, 'Estructura'),
    (Icons.more_horiz_rounded, 'Otros'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, label) in _types)
          ChoiceChip(
            avatar: Icon(icon, size: 18),
            label: Text(label),
            selected: false,
            onSelected: (_) {},
          ),
      ],
    );
  }
}

/// Botón para agregar evidencias.
class _EvidencePlaceholder extends StatelessWidget {
  const _EvidencePlaceholder();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('Agregar evidencia'),
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
