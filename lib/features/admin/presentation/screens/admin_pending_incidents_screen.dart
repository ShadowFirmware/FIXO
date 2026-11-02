import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/pending_incident.dart';
import '../providers/pending_incidents_view_model.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/pending_incident_widgets.dart';

/// Reportes: incidencias pendientes de asignación (HU-4.8).
class AdminPendingIncidentsScreen extends StatefulWidget {
  const AdminPendingIncidentsScreen({super.key, this.viewModel});

  final PendingIncidentsViewModel? viewModel;

  @override
  State<AdminPendingIncidentsScreen> createState() =>
      _AdminPendingIncidentsScreenState();
}

class _AdminPendingIncidentsScreenState
    extends State<AdminPendingIncidentsScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: const AdminDrawer(
        currentRoute: RouteNames.adminPendingIncidents,
      ),
      appBar: FixoAppBar(
        title: 'Reportes pendientes',
        subtitle: 'Pendientes de asignación',
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
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TypeFilter(
              selected: _viewModel.typeFilter,
              onSelected: _viewModel.setTypeFilter,
            ),
            if (_viewModel.isSaving) const LinearProgressIndicator(),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.all.isEmpty && _viewModel.errorMessage != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: _viewModel.errorMessage!,
      );
    }
    final items = _viewModel.incidents;
    if (items.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: _viewModel.typeFilter == null
            ? 'No hay incidencias pendientes de asignación'
            : 'No hay incidencias pendientes de tipo '
                  '${_viewModel.typeFilter!.label}',
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < 900;
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final p = items[index];
          return PendingIncidentCard(
            pending: p,
            onTap: () =>
                showPendingIncidentDetail(context, p, actions: _actions),
            onAssign: _viewModel.isSaving ? null : () => _actions.assign(p),
            onReject: _viewModel.isSaving ? null : () => _actions.reject(p),
          );
        },
      );
    }
    return _Table(
      items: items,
      busy: _viewModel.isSaving,
      onView: (p) => showPendingIncidentDetail(context, p, actions: _actions),
      onAssign: _actions.assign,
      onReject: _actions.reject,
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({required this.selected, required this.onSelected});

  final IncidentType? selected;
  final ValueChanged<IncidentType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final type in IncidentType.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(type.label),
              selected: selected == type,
              onSelected: (_) => onSelected(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.items,
    required this.busy,
    required this.onView,
    required this.onAssign,
    required this.onReject,
  });

  final List<PendingIncident> items;
  final bool busy;
  final ValueChanged<PendingIncident> onView;
  final ValueChanged<PendingIncident> onAssign;
  final ValueChanged<PendingIncident> onReject;

  @override
  Widget build(BuildContext context) {
    Widget limited(String text, double width) => SizedBox(
      width: width,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: AppColors.white,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('No. reporte')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Detalles')),
              DataColumn(label: Text('Evidencias')),
              DataColumn(label: Text('Departamento')),
              DataColumn(label: Text('Reportó')),
              DataColumn(label: Text('Fecha de creación')),
              DataColumn(label: Text('Opciones')),
            ],
            rows: [
              for (final p in items)
                DataRow(
                  onSelectChanged: (_) => onView(p),
                  cells: [
                    DataCell(Text(p.incident.reportNumber)),
                    DataCell(limited(p.incident.title, 160)),
                    DataCell(Text(p.incident.type.label)),
                    DataCell(limited(p.incident.description, 220)),
                    DataCell(
                      Text(
                        p.incident.evidenceBefore.isEmpty
                            ? 'Sin evidencias'
                            : '${p.incident.evidenceBefore.length} (ver)',
                      ),
                    ),
                    DataCell(Text(p.housingLabel)),
                    DataCell(limited(p.reporterName, 160)),
                    DataCell(Text(formatCreatedAt(p))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: busy ? null : () => onAssign(p),
                            icon: const Icon(Icons.engineering_outlined),
                            label: const Text('Asignar'),
                          ),
                          TextButton.icon(
                            onPressed: busy ? null : () => onReject(p),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Rechazar'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
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
              icon,
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
