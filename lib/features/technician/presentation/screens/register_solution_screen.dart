import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../domain/entities/assigned_incident.dart';
import '../providers/solution_form_view_model.dart';
import '../widgets/solution_form_widgets.dart';

/// HU-3.6 Registrar la solución y evidencias de una incidencia.
class RegisterSolutionScreen extends StatefulWidget {
  const RegisterSolutionScreen({super.key, required this.item, this.viewModel});

  /// Incidencia En proceso a la que se le registra la solución.
  final AssignedIncident item;

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final SolutionFormViewModel? viewModel;

  @override
  State<RegisterSolutionScreen> createState() => _RegisterSolutionScreenState();
}

class _RegisterSolutionScreenState extends State<RegisterSolutionScreen> {
  late final _viewModel =
      widget.viewModel ?? SolutionFormViewModel(item: widget.item);
  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(text: _viewModel.description);

  @override
  void dispose() {
    _description.dispose();
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Registrar solución'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            padding.top + 16,
            20,
            padding.bottom + 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SolutionIncidentBanner(item: _viewModel.item),
                  const SizedBox(height: 20),
                  if (_viewModel.isReviewing)
                    _review()
                  else ...[
                    _form(),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      key: const Key('solution.review'),
                      onPressed: _viewModel.review,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Revisar solución'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SolutionFormSection(
            title: 'Solución aplicada',
            footnote:
                'Describe qué hiciste para resolver el problema. El residente '
                'y el administrador podrán consultarlo.',
            children: [
              TextFormField(
                key: const Key('solution.description'),
                controller: _description,
                onChanged: _viewModel.setDescription,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
                maxLength: SolutionFormViewModel.maxDescriptionLength,
                validator: Validators.solutionDescription,
                decoration: const InputDecoration(
                  labelText: 'Descripción de la solución',
                  hintText:
                      'Ej. Se cambió el empaque de la llave y se revisó que '
                      'no hubiera más fugas',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SolutionFormSection(
            title: 'Evidencias del trabajo',
            footnote:
                'Agrega fotografías o videos del trabajo terminado. Los videos '
                'pueden durar hasta 1 minuto.',
            children: [SolutionEvidencePicker(viewModel: _viewModel)],
          ),
        ],
      ),
    );
  }

  /// Vista previa de la información antes de guardarla.
  Widget _review() {
    final vm = _viewModel;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('solution.reviewView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Revisa la información antes de guardarla',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Al guardarla, la incidencia quedará como Resuelta y ya no podrás '
          'modificarla.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        SolutionFormSection(
          title: 'Solución aplicada',
          children: [
            Text(
              vm.description.trim(),
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SolutionFormSection(
          title: 'Evidencias del trabajo (${vm.evidence.length})',
          footnote: 'Toca una evidencia para verla completa.',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final file in vm.evidence)
                  LocalEvidenceThumbnail(file: file, size: 120),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          key: const Key('solution.edit'),
          onPressed: vm.edit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Corregir'),
        ),
      ],
    );
  }
}
