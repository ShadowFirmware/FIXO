import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../providers/incident_detail_view_model.dart';

/// HU-2.4 Consultar detalles de la incidencia.
class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late final _viewModel = IncidentDetailViewModel(
    incidentId: widget.incidentId,
  );

  @override
  void dispose() {
    _viewModel.dispose();
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
          IncidentDetailState.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          IncidentDetailState.notFound => const _MessageView(
            icon: Icons.search_off_rounded,
            message: 'No se encontró la incidencia.',
          ),
          IncidentDetailState.error => _MessageView(
            icon: Icons.error_outline_rounded,
            message: _viewModel.errorMessage!,
          ),
          IncidentDetailState.loaded => _IncidentDetailBody(
            viewModel: _viewModel,
          ),
        },
      ),
    );
  }
}

class _IncidentDetailBody extends StatelessWidget {
  const _IncidentDetailBody({required this.viewModel});

  final IncidentDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final incident = viewModel.incident!;
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
              _SummaryCard(
                reportNumber: incident.reportNumber,
                title: incident.title,
                status: incident.status,
              ),
              const SizedBox(height: 24),
              DetailSection(
                title: 'Información general',
                children: [
                  DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: viewModel.type,
                  ),
                  DetailRow(
                    icon: Icons.apartment_rounded,
                    label: 'Departamento',
                    value: viewModel.housing,
                  ),
                  DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha de creación',
                    value: viewModel.createdAt,
                  ),
                  DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Descripción',
                    value: viewModel.description,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DetailSection(
                title: 'Evidencias',
                children: [EvidenceGallery(urls: incident.evidenceBefore)],
              ),
              if (viewModel.showTechnician) ...[
                const SizedBox(height: 24),
                DetailSection(
                  title: 'Técnico asignado',
                  children: [
                    DetailRow(
                      icon: Icons.engineering_outlined,
                      label: 'Técnico',
                      value: viewModel.technicianName,
                    ),
                    DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: viewModel.technicianPhone,
                    ),
                    DetailRow(
                      icon: Icons.handyman_outlined,
                      label: 'Especialidad',
                      value: viewModel.technicianSpecialty,
                    ),
                    if (viewModel.estimatedArrival case final arrival?)
                      DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Hora estimada de llegada',
                        value: arrival,
                      ),
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

/// Tarjeta superior con el número de reporte, el título y el estado.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.reportNumber,
    required this.title,
    required this.status,
  });

  final String reportNumber;
  final String title;
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  reportNumber,
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
            title,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.description,
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

/// Tarjeta blanca con título, como las secciones del perfil.
class DetailSection extends StatelessWidget {
  const DetailSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Fila con ícono, etiqueta y valor.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
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
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
