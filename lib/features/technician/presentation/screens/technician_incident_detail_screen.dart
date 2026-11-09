import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../resident/presentation/screens/incident_detail_screen.dart';
import '../providers/assigned_incident_detail_view_model.dart';

/// HU-3.3: información general de una incidencia asignada al técnico.
class TechnicianIncidentDetailScreen extends StatefulWidget {
  const TechnicianIncidentDetailScreen({
    super.key,
    required this.incidentId,
    this.viewModel,
  });

  final String incidentId;

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final AssignedIncidentDetailViewModel? viewModel;

  @override
  State<TechnicianIncidentDetailScreen> createState() =>
      _TechnicianIncidentDetailScreenState();
}

class _TechnicianIncidentDetailScreenState
    extends State<TechnicianIncidentDetailScreen> {
  late final _viewModel =
      widget.viewModel ??
      AssignedIncidentDetailViewModel(incidentId: widget.incidentId);

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Detalle de la incidencia'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.state) {
          AssignedIncidentDetailState.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          AssignedIncidentDetailState.notFound => const _MessageView(
            icon: Icons.search_off_rounded,
            message: 'No se encontró la incidencia.',
          ),
          AssignedIncidentDetailState.error => _MessageView(
            icon: _viewModel.isAccessDenied
                ? Icons.lock_outline_rounded
                : Icons.error_outline_rounded,
            message: _viewModel.errorMessage!,
          ),
          AssignedIncidentDetailState.loaded => _DetailBody(
            viewModel: _viewModel,
          ),
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.viewModel});

  final AssignedIncidentDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final incident = vm.incident!;
    final padding = MediaQuery.paddingOf(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        padding.top + 16,
        20,
        padding.bottom + 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryCard(incident: incident),
              const SizedBox(height: 24),
              DetailSection(
                title: 'Información general',
                children: [
                  DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: vm.type,
                  ),
                  DetailRow(
                    icon: Icons.apartment_rounded,
                    label: 'Departamento',
                    value: vm.housing,
                  ),
                  DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha de creación',
                    value: vm.createdAt,
                  ),
                  DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Hora estimada de llegada',
                    value: vm.estimatedArrival,
                  ),
                  DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Descripción',
                    value: vm.description,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DetailSection(
                title: 'Residente',
                children: [
                  DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Reportó',
                    value: vm.residentName,
                  ),
                  DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: vm.residentPhone,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DetailSection(
                title: 'Evidencias del residente',
                children: [EvidenceGallery(urls: incident.evidenceBefore)],
              ),
              if (vm.isResolved) ...[
                const SizedBox(height: 24),
                DetailSection(
                  title: 'Solución',
                  children: [
                    DetailRow(
                      icon: Icons.task_alt_rounded,
                      label: 'Solución aplicada',
                      value: vm.solution,
                    ),
                    DetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Fecha de resolución',
                      value: vm.resolvedAt,
                    ),
                    EvidenceGallery(urls: incident.evidenceAfter),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta superior con el número de reporte, el título y el estado.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.incident});

  final Incident incident;

  /// Qué significa el estado para el técnico.
  static String descriptionOf(IncidentStatus status) => switch (status) {
    IncidentStatus.assigned =>
      'Acude a la hora estimada para atender el problema.',
    IncidentStatus.inProgress => 'Estás atendiendo el problema.',
    IncidentStatus.resolved =>
      'Resolviste esta incidencia; ya está en tu historial.',
    IncidentStatus.pending => 'La incidencia está en espera de asignación.',
    IncidentStatus.rejected => 'El administrador rechazó el reporte.',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = incident.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.reportNumber,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IncidentStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            incident.title,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descriptionOf(status),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          IncidentStatusProgress(status: status),
        ],
      ),
    );
  }
}

/// Mensaje centrado cuando no se puede mostrar la incidencia.
class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
