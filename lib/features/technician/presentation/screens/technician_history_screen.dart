import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../resident/presentation/screens/incident_history_screen.dart';
import '../providers/resolved_incidents_view_model.dart';
import '../widgets/attended_history_filters.dart';
import '../widgets/attended_incident_card.dart';

/// HU-3.8 Consultar historial de incidencias atendidas: las que el técnico
/// finalizó como resueltas (HU-3.7), con su solución y evidencias.
class TechnicianHistoryScreen extends StatefulWidget {
  const TechnicianHistoryScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final ResolvedIncidentsViewModel? viewModel;

  @override
  State<TechnicianHistoryScreen> createState() =>
      _TechnicianHistoryScreenState();
}

class _TechnicianHistoryScreenState extends State<TechnicianHistoryScreen> {
  late final _viewModel = widget.viewModel ?? ResolvedIncidentsViewModel();

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El padding del MediaQuery ya incluye el alto de ambas barras.
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Historial'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, padding.top + 16, 20, 0),
                sliver: SliverToBoxAdapter(child: _Header(viewModel: vm)),
              ),
              // Los filtros solo tienen sentido si hay incidencias.
              if (vm.state == ResolvedIncidentsState.loaded &&
                  vm.incidents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: AttendedHistoryFilters(viewModel: vm),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 24),
                sliver: _results(vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _results(ResolvedIncidentsViewModel vm) {
    return switch (vm.state) {
      ResolvedIncidentsState.loading => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      ResolvedIncidentsState.error => SliverFillRemaining(
        hasScrollBody: false,
        child: HistoryMessage(
          icon: Icons.error_outline_rounded,
          message: vm.errorMessage!,
          action: OutlinedButton.icon(
            key: const Key('history.retry'),
            onPressed: vm.retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ),
      ),
      ResolvedIncidentsState.loaded when vm.incidents.isEmpty =>
        const SliverFillRemaining(
          hasScrollBody: false,
          child: HistoryMessage(
            icon: Icons.task_alt_rounded,
            message: ResolvedIncidentsViewModel.noIncidentsMessage,
          ),
        ),
      ResolvedIncidentsState.loaded => SliverList.separated(
        itemCount: vm.results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = vm.results[index];
          return AttendedIncidentCard(
            key: ValueKey(item.id),
            item: item,
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.technicianIncidentDetail,
              arguments: item,
            ),
          );
        },
      ),
    };
  }
}

/// Título, explicación y cuántas incidencias ha atendido el técnico.
class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final ResolvedIncidentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = viewModel.incidents.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incidencias atendidas',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Revisa los trabajos que realizaste y las soluciones que '
                'registraste.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (viewModel.state == ResolvedIncidentsState.loaded) ...[
          const SizedBox(width: 12),
          Container(
            key: const Key('history.total'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '$total',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  total == 1 ? 'atendida' : 'atendidas',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
