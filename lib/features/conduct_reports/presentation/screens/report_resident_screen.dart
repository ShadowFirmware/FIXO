import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../domain/entities/conduct_report.dart';
import '../providers/conduct_report_form_view_model.dart';
import '../providers/report_resident_view_model.dart';
import '../widgets/conduct_report_widgets.dart';

/// HU-7.2 Reportar la conducta de un residente.
///
/// Devuelve el [ConductReport] registrado al cerrarse, o `null` si el
/// técnico sale sin enviarlo.
class ReportResidentScreen extends StatefulWidget {
  const ReportResidentScreen({super.key, required this.target, this.viewModel});

  final ResidentReportTarget target;

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final ReportResidentViewModel? viewModel;

  @override
  State<ReportResidentScreen> createState() => _ReportResidentScreenState();
}

class _ReportResidentScreenState extends State<ReportResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final _viewModel =
      widget.viewModel ?? ReportResidentViewModel(target: widget.target);

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(
      () => _viewModel.description = _descriptionController.text,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_viewModel.isSaving) return;
    // Se validan todos para marcar cada error, no solo el primero.
    final fieldsValid = _formKey.currentState!.validate();
    final restValid = _viewModel.validate() == null;
    if (!fieldsValid || !restValid) {
      showIncompleteFormMessage(context);
      return;
    }

    final report = await _viewModel.submit();
    if (!mounted) return;
    if (report == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
      return;
    }
    await _showSent(report);
  }

  /// Confirma el envío con el folio y el estado del reporte.
  Future<void> _showSent(ConductReport report) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 48,
        ),
        title: const Text('Reporte enviado'),
        content: Text(
          'Tu reporte ${report.reportNumber} contra ${report.reportedName} '
          'quedó con estado "${report.status.label}". El administrador lo '
          'revisará antes de tomar cualquier medida.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            key: const Key('reportResident.done'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final target = widget.target;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Reportar residente'),
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
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_viewModel.choosesResident) ...[
                      ConductTargetBanner(
                        label: 'Incidencia',
                        name: target.incidentTitle,
                        incidentNumber: target.incidentNumber,
                        incidentTitle: 'Resuelta',
                        icon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 20),
                      ConductFormSection(
                        title: '¿A quién reportas?',
                        children: [
                          _ResidentSelector(viewModel: _viewModel),
                          if (_viewModel.residentError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _viewModel.residentError!,
                              key: const Key('reportResident.residentError'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ],
                        ],
                      ),
                    ] else
                      // Solo hay un residente: queda fijo.
                      ConductTargetBanner(
                        label: 'Residente reportado',
                        name: _viewModel.resident?.name ?? 'Residente',
                        incidentNumber: target.incidentNumber,
                        incidentTitle: target.incidentTitle,
                        icon: Icons.person_outline_rounded,
                        nameKey: const Key('reportResident.resident'),
                      ),
                    const SizedBox(height: 24),
                    ConductFormSection(
                      title: 'Motivo del reporte',
                      children: [
                        ConductReasonSelector(
                          reasons: _viewModel.reasons,
                          selected: _viewModel.reason,
                          keyPrefix: 'reportResident',
                          onSelected: _viewModel.isSaving
                              ? null
                              : _viewModel.selectReason,
                        ),
                        if (_viewModel.reasonError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _viewModel.reasonError!,
                            key: const Key('reportResident.reasonError'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConductFormSection(
                      title: '¿Qué ocurrió?',
                      children: [
                        TextFormField(
                          key: const Key('reportResident.description'),
                          controller: _descriptionController,
                          enabled: !_viewModel.isSaving,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 4,
                          maxLines: 8,
                          maxLength:
                              ConductReportFormViewModel.maxDescriptionLength,
                          validator: Validators.conductDescription,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText:
                                'Cuenta con detalle lo que pasó durante la '
                                'atención',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConductFormSection(
                      title: 'Evidencias (opcional)',
                      footnote:
                          'Puedes agregar fotografías, videos o capturas del '
                          'chat. Los videos pueden durar hasta 1 minuto.',
                      children: [ConductEvidencePicker(viewModel: _viewModel)],
                    ),
                    const SizedBox(height: 24),
                    const ConductReviewNotice(
                      reported: 'del residente',
                      limit:
                          'Solo puedes enviar un reporte por residente en '
                          'cada incidencia.',
                    ),
                    if (_viewModel.errorMessage case final message?) ...[
                      const SizedBox(height: 16),
                      FormErrorBanner(message: message),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('reportResident.submit'),
                      onPressed: _viewModel.isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: _viewModel.isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.flag_outlined),
                      label: Text(
                        _viewModel.isSaving ? 'Enviando…' : 'Enviar reporte',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Residentes que se pueden reportar, cuando hay más de uno: el que
/// registró la incidencia y quienes participaron en el chat.
class _ResidentSelector extends StatelessWidget {
  const _ResidentSelector({required this.viewModel});

  final ReportResidentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.resident?.id;
    final textTheme = Theme.of(context).textTheme;

    // La tarjeta es blanca: el Material deja ver el efecto al tocar.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (final resident in viewModel.target.residents)
            ListTile(
              key: Key('reportResident.resident.${resident.id}'),
              contentPadding: EdgeInsets.zero,
              enabled: !viewModel.isSaving,
              onTap: () => viewModel.selectResident(resident),
              leading: Icon(
                selected == resident.id
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected == resident.id
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              title: Text(
                resident.name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(resident.participation),
            ),
        ],
      ),
    );
  }
}
