import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../providers/admin_incident_history_view_model.dart';

/// Filtros del historial: estado (con cuántas hay en cada uno), tipo,
/// técnico y departamento. Se aplican al momento.
class AdminHistoryFilters extends StatelessWidget {
  const AdminHistoryFilters({super.key, required this.viewModel});

  final AdminIncidentHistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final filter = vm.filter;
    final counts = vm.statusCounts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('history.status.all'),
                  label: Text('Todas (${vm.incidents.length})'),
                  selected: filter.status == null,
                  onSelected: (_) => vm.setStatus(null),
                ),
                for (final status in IncidentStatus.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: Key('history.status.${status.value}'),
                    avatar: Icon(status.icon, size: 18, color: status.color),
                    label: Text('${status.label} (${counts[status]})'),
                    selected: filter.status == status,
                    onSelected: (_) => vm.setStatus(status),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Dropdown<IncidentType>(
                key: const Key('history.type'),
                label: 'Tipo',
                value: filter.type,
                options: [
                  for (final type in IncidentType.values) (type, type.label),
                ],
                onChanged: vm.setType,
              ),
              _Dropdown<String>(
                key: const Key('history.technician'),
                label: 'Técnico',
                value: filter.technicianId,
                options: vm.technicianOptions,
                onChanged: vm.setTechnician,
              ),
              _Dropdown<String>(
                key: const Key('history.housing'),
                label: 'Departamento',
                value: filter.housingId,
                options: vm.housingOptions,
                onChanged: vm.setHousing,
              ),
              if (!filter.isEmpty)
                TextButton.icon(
                  key: const Key('history.clearFilters'),
                  onPressed: vm.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Limpiar filtros'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            countLabel(total: vm.incidents.length, shown: vm.results.length),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// "12 incidencias" o, con filtros, "3 de 12 incidencias".
  static String countLabel({required int total, required int shown}) {
    final plural = total == 1 ? '$total incidencia' : '$total incidencias';
    return shown == total ? plural : '$shown de $plural';
  }
}

/// Lista desplegable con la opción "Todos" para quitar el filtro.
class _Dropdown<T extends Object> extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T?>(
        // Se vuelve a crear cuando el filtro cambia desde fuera, por
        // ejemplo con "Limpiar filtros".
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          DropdownMenuItem<T?>(child: const Text('Todos')),
          for (final (option, text) in options)
            DropdownMenuItem<T?>(
              value: option,
              child: Text(text, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
