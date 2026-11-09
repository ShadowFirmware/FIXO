import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../domain/usecases/watch_assigned_incidents.dart';
import '../providers/assigned_incidents_view_model.dart';

/// Filtro por estado de las incidencias asignadas: todas, asignadas o en
/// proceso, con cuántas hay de cada una.
class AssignedStatusFilter extends StatelessWidget {
  const AssignedStatusFilter({super.key, required this.viewModel});

  final AssignedIncidentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            key: const Key('assigned.status.all'),
            label: 'Todas',
            status: null,
            color: AppColors.primary,
          ),
          for (final status in WatchAssignedIncidents.activeStatuses)
            _chip(
              key: Key('assigned.status.${status.value}'),
              label: status.label,
              status: status,
              color: status.color,
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required IncidentStatus? status,
    required Color color,
  }) {
    final selected = viewModel.statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: key,
        label: Text('$label (${viewModel.countOf(status)})'),
        selected: selected,
        showCheckmark: false,
        selectedColor: color.withValues(alpha: 0.14),
        backgroundColor: AppColors.white,
        side: BorderSide(color: selected ? color : AppColors.border),
        labelStyle: TextStyle(
          color: selected ? color : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: (_) => viewModel.setStatusFilter(status),
      ),
    );
  }
}
