import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../resident/presentation/screens/incident_detail_screen.dart';
import '../../domain/entities/assigned_incident.dart';
import '../providers/assigned_incident_detail_view_model.dart';
import '../widgets/assigned_detail_widgets.dart';
import '../widgets/attended_incident_card.dart';

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

  /// Pide confirmación y finaliza la incidencia como resuelta (HU-3.7).
  Future<void> _finalize() async {
    final reportNumber = _viewModel.incident!.reportNumber;
    final confirmed = await confirmFinalize(context, reportNumber);
    if (!confirmed || !mounted) return;

    final error = await _viewModel.finalize();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Finalizaste la incidencia $reportNumber. Ya está en tu '
                  'historial.',
        ),
      ),
    );
    // Ya no está entre las asignadas: se vuelve a la lista.
    if (error == null) Navigator.maybePop(context);
  }

  /// Pide confirmación y pasa la incidencia a En proceso.
  Future<void> _startAttention() async {
    final reportNumber = _viewModel.incident!.reportNumber;
    final confirmed = await confirmStartAttention(context, reportNumber);
    if (!confirmed || !mounted) return;

    final error = await _viewModel.startAttention();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Comenzaste la atención de $reportNumber.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: FixoAppBar(
        title: 'Detalle de la incidencia',
        actions: [
          // HU-5.1: chat con el residente o el técnico de la incidencia.
          FixoAppBarAction(
            key: const Key('detail.chat'),
            icon: Icons.forum_outlined,
            tooltip: 'Chat',
            onPressed: () => Navigator.pushNamed(
              context,
              RouteNames.incidentChat,
              arguments: widget.incidentId,
            ),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.canStartAttention) {
            return _ActionBar(
              buttonKey: const Key('detail.startAttention'),
              icon: Icons.play_arrow_rounded,
              label: 'Comenzar atención',
              busy: _viewModel.isStarting,
              busyLabel: 'Comenzando…',
              onPressed: _startAttention,
            );
          }
          if (_viewModel.canRegisterSolution) {
            return _ActionBar(
              buttonKey: const Key('detail.registerSolution'),
              icon: Icons.task_alt_rounded,
              label: 'Registrar solución',
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.technicianRegisterSolution,
                arguments: _viewModel.item,
              ),
            );
          }
          if (_viewModel.canFinalize) {
            return _ActionBar(
              buttonKey: const Key('detail.finalize'),
              icon: Icons.flag_rounded,
              label: 'Finalizar incidencia',
              busy: _viewModel.isFinalizing,
              busyLabel: 'Finalizando…',
              onPressed: _finalize,
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
            // Resuelta, se ve en el resumen de la atención.
            if (!vm.isResolved)
              if (vm.startedAt case final startedAt?)
                DetailRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Inicio de la atención',
                  value: startedAt,
                ),
            DetailRow(
              icon: Icons.notes_rounded,
              label: 'Descripción',
              value: vm.description,
            ),
          ],
        ),
        // La solución se muestra desde que se registra (HU-3.6), aunque la
        // incidencia siga En proceso hasta que se finaliza (HU-3.7).
        if (vm.hasSolution) ...[
          DetailSection(
            title: 'Solución',
            children: [
              DetailRow(
                icon: Icons.task_alt_rounded,
                label: 'Solución aplicada',
                value: vm.solution,
              ),
              // Resuelta, las fechas se ven en el resumen de la atención.
              if (!vm.isResolved)
                if (vm.solutionRegisteredAt case final registeredAt?)
                  DetailRow(
                    icon: Icons.edit_calendar_outlined,
                    label: 'Registrada el',
                    value: registeredAt,
                  ),
            ],
          ),
          AssignedEvidenceSection(
            title: 'Evidencias del trabajo',
            urls: incident.evidenceAfter,
          ),
        ],
        // En el historial (HU-3.8) se resume cómo fue la atención.
        if (vm.isResolved)
          DetailSection(
            title: 'Resumen de la atención',
            children: [
              if (vm.startedAt case final startedAt?)
                DetailRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Comenzó',
                  value: startedAt,
                ),
              if (vm.solutionRegisteredAt case final registeredAt?)
                DetailRow(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Solución registrada',
                  value: registeredAt,
                ),
              DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Resuelta',
                value: vm.resolvedAt,
              ),
              if (AttendedIncidentCard.attentionTime(incident) case final time?)
                DetailRow(
                  icon: Icons.timer_outlined,
                  label: 'Duración de la atención',
                  value: time,
                ),
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

/// Barra inferior con la acción disponible según el estado: Comenzar
/// atención (Asignada), Registrar solución o Finalizar incidencia (En
/// proceso, sin o con la solución registrada).
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.buttonKey,
    required this.icon,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;

  /// `null` deshabilita el botón.
  final VoidCallback? onPressed;

  /// Se está guardando: el botón se deshabilita y muestra el progreso.
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ElevatedButton.icon(
                key: buttonKey,
                onPressed: busy ? null : onPressed,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon),
                label: Text(busy ? busyLabel ?? label : label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
