import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../resident/presentation/screens/incident_detail_screen.dart';
import '../../domain/entities/assigned_incident.dart';
import '../providers/assigned_incident_detail_view_model.dart';
import '../widgets/assigned_detail_widgets.dart';

/// HU-3.4 Consultar detalles y evidencias de una incidencia asignada.
class TechnicianIncidentDetailScreen extends StatefulWidget {
  const TechnicianIncidentDetailScreen({
    super.key,
    required this.incidentId,
    this.initial,
    this.viewModel,
  });

  final String incidentId;

  /// Datos que ya se tenían en la lista, para mostrarlos de inmediato.
  final AssignedIncident? initial;

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
      AssignedIncidentDetailViewModel(
        incidentId: widget.incidentId,
        initial: widget.initial,
      );

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
          AssignedIncidentDetailState.notFound => const AssignedDetailMessage(
            icon: Icons.search_off_rounded,
            message: 'No se encontró la incidencia.',
          ),
          AssignedIncidentDetailState.error => AssignedDetailMessage(
            icon: _viewModel.isAccessDenied
                ? Icons.lock_outline_rounded
                : Icons.error_outline_rounded,
            message: _viewModel.errorMessage!,
            action: _viewModel.canRetry
                ? FilledButton.icon(
                    key: const Key('detail.retry'),
                    onPressed: _viewModel.retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  )
                : null,
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

    return AssignedDetailLayout(
      header: AssignedDetailSummary(
        incident: incident,
        arrival: incident.estimatedTime == null ? null : vm.estimatedArrival,
        countdown: vm.arrivalCountdown,
      ),
      primary: [
        DetailSection(
          title: 'Información general',
          children: [
            DetailRow(
              icon: Icons.category_outlined,
              label: 'Tipo',
              value: vm.type,
            ),
            DetailRow(
              icon: Icons.flag_outlined,
              label: 'Estado',
              value: vm.status,
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
        if (vm.isResolved)
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
      secondary: [
        AssignedEvidenceSection(
          title: 'Evidencias del residente',
          urls: incident.evidenceBefore,
        ),
        DetailSection(
          title: 'Ubicación',
          children: [
            DetailRow(
              icon: Icons.place_outlined,
              label: 'Lugar',
              value: vm.housing,
            ),
            DetailRow(
              icon: Icons.home_work_outlined,
              label: 'Tipo de vivienda',
              value: vm.housingType,
            ),
            if (vm.building case final building?)
              DetailRow(
                icon: Icons.apartment_rounded,
                label: 'Edificio o torre',
                value: building,
              ),
            DetailRow(
              icon: Icons.tag_rounded,
              label: 'Número',
              value: vm.housingNumber,
            ),
          ],
        ),
        DetailSection(
          title: 'Residente',
          children: [
            DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Reportó',
              value: vm.residentName,
            ),
            CopyableDetailRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: vm.residentPhone,
              copyValue: vm.phoneToCopy,
              copiedMessage: 'Teléfono copiado',
            ),
            DetailRow(
              icon: Icons.email_outlined,
              label: 'Correo electrónico',
              value: vm.residentEmail,
            ),
          ],
        ),
      ],
    );
  }
}
