import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../providers/pending_incidents_view_model.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/pending_incident_widgets.dart';

/// Pantalla de inicio del administrador. Muestra las 3 incidencias
/// pendientes más antiguas y un acceso a Reportes (HU-4.8).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, this.viewModel});

  final PendingIncidentsViewModel? viewModel;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final PendingIncidentsViewModel _viewModel =
      widget.viewModel ?? PendingIncidentsViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  late final _actions = PendingIncidentActions(context, _viewModel);

  @override
  void initState() {
    super.initState();
    _viewModel.start();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthSession.instance.currentUser?.name;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: const AdminDrawer(currentRoute: RouteNames.adminHome),
      appBar: FixoAppBar(
        title: 'Administrador',
        subtitle: name,
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
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.all.isEmpty) {
            return _Empty(
              text:
                  _viewModel.errorMessage ?? 'No hay reportes por el momento',
            );
          }

          final preview = _viewModel.preview;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pendientes de asignación',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_viewModel.all.length}',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (_viewModel.isSaving) const LinearProgressIndicator(),
              for (final p in preview) ...[
                PendingIncidentCard(
                  pending: p,
                  onTap: () =>
                      showPendingIncidentDetail(context, p, actions: _actions),
                  onAssign: _viewModel.isSaving
                      ? null
                      : () => _actions.assign(p),
                  onReject: _viewModel.isSaving
                      ? null
                      : () => _actions.reject(p),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.adminPendingIncidents,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ver más'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
