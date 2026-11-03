import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../providers/incident_stats_view_model.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/history_incident_widgets.dart';
import '../widgets/stats_charts.dart';
import '../widgets/stats_entries.dart';
import '../widgets/stats_period_selector.dart';
import '../widgets/stats_widgets.dart';

/// HU-4.12 Consultar estadísticas de incidencias por periodo.
class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final IncidentStatsViewModel? viewModel;

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  late final IncidentStatsViewModel _viewModel =
      widget.viewModel ?? IncidentStatsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.start();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: const AdminDrawer(currentRoute: RouteNames.adminStatistics),
      appBar: FixoAppBar(
        title: 'Estadísticas',
        subtitle: 'Incidencias por periodo',
        leading: Builder(
          builder: (context) => FixoAppBarAction(
            icon: Icons.menu_rounded,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _content(context),
      ),
    );
  }

  /// El selector del periodo siempre está visible, para poder cambiarlo
  /// aunque el periodo actual esté cargando o haya fallado.
  Widget _content(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StatsPeriodSelector(viewModel: _viewModel),
        const SizedBox(height: 12),
        ..._body(),
      ],
    );
  }

  List<Widget> _body() {
    final vm = _viewModel;
    switch (vm.state) {
      case StatsState.loading:
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case StatsState.error:
        return [
          HistoryEmptyMessage(
            icon: Icons.cloud_off_outlined,
            text: vm.errorMessage!,
            action: OutlinedButton.icon(
              key: const Key('stats.retry'),
              onPressed: vm.retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ];
      case StatsState.loaded:
        break;
    }

    final stats = vm.stats;
    const empty = StatsEmpty(IncidentStatsViewModel.noIncidentsMessage);
    return [
      if (vm.updatedAt case final updatedAt?)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            key: const Key('stats.live'),
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'En tiempo real · Actualizado a las '
                  '${DateFormats.time(updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatsSummaryTile(
            key: const Key('stats.total'),
            label: 'Incidencias',
            value: stats.total,
            icon: Icons.assignment_outlined,
          ),
          for (final status in IncidentStatus.values)
            StatsSummaryTile(
              key: Key('stats.summary.${status.value}'),
              label: status.label,
              value: stats.countOf(status),
              icon: status.icon,
              color: status.color,
            ),
        ],
      ),
      const SizedBox(height: 12),
      StatsGrid(
        children: [
          StatsSection(
            key: const Key('stats.byType'),
            title: 'Incidencias por tipo',
            icon: Icons.category_outlined,
            child: stats.isEmpty
                ? empty
                : StatsBarChart(
                    entries: typeEntries(stats),
                    total: stats.total,
                  ),
          ),
          StatsSection(
            key: const Key('stats.byStatus'),
            title: 'Incidencias por estado',
            icon: Icons.donut_large_outlined,
            child: stats.isEmpty
                ? empty
                : StatsDonutChart(
                    entries: statusEntries(stats),
                    total: stats.total,
                  ),
          ),
          StatsSection(
            key: const Key('stats.byTechnician'),
            title: 'Asignadas por técnico',
            icon: Icons.engineering_outlined,
            child: stats.byTechnician.isEmpty
                ? StatsEmpty(
                    stats.isEmpty
                        ? IncidentStatsViewModel.noIncidentsMessage
                        : IncidentStatsViewModel.noAssignmentsMessage,
                  )
                : StatsBarChart(
                    entries: technicianEntries(stats),
                    total: stats.assignedCount,
                  ),
          ),
        ],
      ),
    ];
  }
}
