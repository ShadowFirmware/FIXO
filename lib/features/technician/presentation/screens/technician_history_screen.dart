import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../resident/presentation/screens/incident_history_screen.dart';
import '../providers/resolved_incidents_view_model.dart';
import '../widgets/assigned_incident_card.dart';

/// Historial de incidencias atendidas por el técnico (HU-3.7): las que
/// finalizó como resueltas, para consultar la solución registrada (HU-3.6).
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
    final textTheme = Theme.of(context).textTheme;

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
                sliver: SliverToBoxAdapter(
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
                        'Incidencias que finalizaste como resueltas, con '
                        'su solución y evidencias.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 24),
                sliver: switch (vm.state) {
                  ResolvedIncidentsState.loading => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  ResolvedIncidentsState.error => SliverFillRemaining(
                    hasScrollBody: false,
                    child: HistoryMessage(
                      icon: Icons.error_outline_rounded,
                      message: vm.errorMessage!,
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
                    itemCount: vm.incidents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = vm.incidents[index];
                      return AssignedIncidentCard(
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
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
