import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../resident/presentation/screens/incident_history_screen.dart';
import '../providers/assigned_incidents_view_model.dart';
import '../widgets/assigned_incident_card.dart';
import '../widgets/assigned_status_filter.dart';

/// Pantalla de inicio del técnico: HU-3.3 Consultar incidencias asignadas.
class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final AssignedIncidentsViewModel? viewModel;

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  late final _viewModel = widget.viewModel ?? AssignedIncidentsViewModel();

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
      // El contenido pasa por detrás de la barra superior para aprovechar
      // toda la pantalla cuando las barras se ocultan al hacer scroll.
      extendBodyBehindAppBar: true,
      appBar: FixoAppBar(
        title: 'Incidencias asignadas',
        subtitle: AuthSession.instance.currentUser?.name,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, padding.top + 16, 20, 0),
                sliver: const SliverToBoxAdapter(
                  child: _Header(
                    title: 'Tus incidencias por atender',
                    subtitle: 'Reportes asignados por el administrador.',
                  ),
                ),
              ),
              // El filtro solo tiene sentido si hay incidencias.
              if (vm.state == AssignedIncidentsState.loaded &&
                  vm.incidents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: AssignedStatusFilter(viewModel: vm),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 24),
                sliver: switch (vm.state) {
                  AssignedIncidentsState.loading => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  AssignedIncidentsState.error => SliverFillRemaining(
                    hasScrollBody: false,
                    child: HistoryMessage(
                      icon: Icons.error_outline_rounded,
                      message: vm.errorMessage!,
                    ),
                  ),
                  AssignedIncidentsState.loaded when vm.emptyMessage != null =>
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: vm.incidents.isEmpty
                          ? HistoryMessage(
                              icon: Icons.assignment_turned_in_outlined,
                              message: vm.emptyMessage!,
                            )
                          : HistoryMessage(
                              icon: Icons.filter_alt_off_outlined,
                              message: vm.emptyMessage!,
                              action: OutlinedButton(
                                key: const Key('assigned.showAll'),
                                onPressed: () => vm.setStatusFilter(null),
                                child: const Text('Ver todas'),
                              ),
                            ),
                    ),
                  AssignedIncidentsState.loaded => SliverList.separated(
                    itemCount: vm.results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = vm.results[index];
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

/// Título de la sección con una breve explicación.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
