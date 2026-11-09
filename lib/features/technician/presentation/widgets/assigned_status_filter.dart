import 'package:flutter/material.dart';

import '../../../incidents/domain/entities/incident.dart';
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
          ),
          for (final status in WatchAssignedIncidents.activeStatuses)
            _chip(
              key: Key('assigned.status.${status.value}'),
              label: status.label,
              status: status,
            ),
        ],
      ),
    );
  }

  // Usa el estilo común de los filtros: fondo azul y texto blanco al
  // seleccionarse.
  Widget _chip({
    required Key key,
    required String label,
    required IncidentStatus? status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: key,
        label: Text('$label (${viewModel.countOf(status)})'),
        selected: viewModel.statusFilter == status,
        onSelected: (_) => viewModel.setStatusFilter(status),
      ),
    );
  }
}
