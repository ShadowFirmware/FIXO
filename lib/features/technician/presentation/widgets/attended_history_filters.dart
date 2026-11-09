import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../providers/resolved_incidents_view_model.dart';

/// Filtros del historial de incidencias atendidas (HU-3.8): por tipo y por
/// rango de fechas de resolución. Los cambios se aplican al momento.
class AttendedHistoryFilters extends StatelessWidget {
  const AttendedHistoryFilters({super.key, required this.viewModel});

  final ResolvedIncidentsViewModel viewModel;

  /// "Todas las fechas", "Desde 1 nov 2026", "Hasta 9 nov 2026" o
  /// "1 nov 2026 – 9 nov 2026".
  static String dateRangeLabel({DateTime? from, DateTime? to}) {
    if (from == null && to == null) return 'Todas las fechas';
    if (to == null) return 'Desde ${DateFormats.shortDate(from!)}';
    if (from == null) return 'Hasta ${DateFormats.shortDate(to)}';
    return '${DateFormats.shortDate(from)} – ${DateFormats.shortDate(to)}';
  }

  Future<void> _pickDates(BuildContext context) async {
    final vm = viewModel;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: vm.hasDateRange
          ? DateTimeRange(start: vm.from ?? now, end: vm.to ?? now)
          : null,
      helpText: 'Fecha de resolución',
      saveText: 'Aplicar',
    );
    if (range != null) vm.setDateRange(from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TypeChip(
                key: const Key('history.type.all'),
                label: 'Todos',
                selected: vm.type == null,
                onSelected: () => vm.setType(null),
              ),
              for (final type in IncidentType.values)
                _TypeChip(
                  key: Key('history.type.${type.value}'),
                  label: type.label,
                  icon: type.icon,
                  selected: vm.type == type,
                  onSelected: () => vm.setType(type),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('history.dateRange'),
                onPressed: () => _pickDates(context),
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  dateRangeLabel(from: vm.from, to: vm.to),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (vm.hasDateRange) ...[
              const SizedBox(width: 8),
              IconButton(
                key: const Key('history.clearDates'),
                tooltip: 'Quitar fechas',
                onPressed: () => vm.setDateRange(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          vm.hasFilters
              ? 'Mostrando ${vm.results.length} de ${vm.incidents.length}'
              : '${vm.incidents.length} '
                    '${vm.incidents.length == 1 ? 'incidencia' : 'incidencias'}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
