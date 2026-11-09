import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
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
                  const SolutionFormSection(
                    title: 'Solución aplicada',
                    footnote:
                        'Describe qué hiciste para resolver el problema. El '
                        'residente y el administrador podrán consultarlo.',
                    children: [],
                  ),
                  const SizedBox(height: 24),
                  const SolutionFormSection(
                    title: 'Evidencias del trabajo',
                    footnote:
                        'Agrega fotografías o videos del trabajo terminado.',
                    children: [],
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
