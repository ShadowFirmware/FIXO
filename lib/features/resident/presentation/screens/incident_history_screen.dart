import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../providers/incident_history_view_model.dart';

/// HU-2.5 Consultar historial de incidencias.
class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final IncidentHistoryViewModel? viewModel;

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  late final _viewModel = widget.viewModel ?? IncidentHistoryViewModel();

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
                  child: _HistoryHeader(
                    title: 'Incidencias de tu departamento',
                    subtitle: vm.housing == null
                        ? 'Consulta los reportes y su estado.'
                        : 'Reportes de ${vm.housing}.',
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 24),
                sliver: switch (vm.state) {
                  IncidentHistoryState.loading => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  IncidentHistoryState.error => SliverFillRemaining(
                    hasScrollBody: false,
                    child: HistoryMessage(
                      icon: Icons.error_outline_rounded,
                      message: vm.errorMessage!,
                    ),
                  ),
                  IncidentHistoryState.loaded when vm.incidents.isEmpty =>
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: HistoryMessage(
                        icon: Icons.receipt_long_outlined,
                        message: 'Aún no hay incidencias registradas.',
                      ),
                    ),
                  IncidentHistoryState.loaded => SliverList.separated(
                    itemCount: vm.incidents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final incident = vm.incidents[index];
                      return ListTile(
                        tileColor: AppColors.white,
                        title: Text(incident.title),
                        subtitle: Text(incident.reportNumber),
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
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.title, required this.subtitle});

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

/// Mensaje centrado cuando no hay incidencias que mostrar.
class HistoryMessage extends StatelessWidget {
  const HistoryMessage({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;

  /// Botón opcional debajo del mensaje, por ejemplo "Limpiar filtros".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
