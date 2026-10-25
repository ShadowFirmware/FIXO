import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_type_style.dart';
import '../providers/incident_history_view_model.dart';

/// Búsqueda por número o nombre, filtro por estado y botón con los filtros
/// de tipo y fecha.
class IncidentHistoryFilters extends StatefulWidget {
  const IncidentHistoryFilters({super.key, required this.viewModel});

  final IncidentHistoryViewModel viewModel;

  @override
  State<IncidentHistoryFilters> createState() => _IncidentHistoryFiltersState();
}

class _IncidentHistoryFiltersState extends State<IncidentHistoryFilters> {
  late final _search = TextEditingController(
    text: widget.viewModel.filter.query,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_syncSearch);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  /// Vacía el campo cuando los filtros se limpian desde otro lugar.
  void _syncSearch() {
    final query = widget.viewModel.filter.query;
    if (_search.text != query) _search.text = query;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final filter = vm.filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('history.search'),
                controller: _search,
                onChanged: vm.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por número o nombre',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => vm.setQuery(''),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Badge(
              isLabelVisible: filter.panelCount > 0,
              label: Text('${filter.panelCount}'),
              child: IconButton.filledTonal(
                key: const Key('history.moreFilters'),
                tooltip: 'Filtrar por tipo y fecha',
                iconSize: 22,
                style: IconButton.styleFrom(
                  fixedSize: const Size(52, 52),
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showFilterSheet(context, vm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: 'Todos',
                selected: filter.status == null,
                onSelected: () => vm.setStatus(null),
              ),
              for (final status in IncidentStatus.values)
                _StatusChip(
                  key: Key('history.status.${status.value}'),
                  label: status.label,
                  selected: filter.status == status,
                  onSelected: () => vm.setStatus(status),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _countLabel(vm),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static String _countLabel(IncidentHistoryViewModel vm) {
    final total = vm.incidents.length;
    String plural(int n) => n == 1 ? '$n incidencia' : '$n incidencias';
    if (vm.filter.isEmpty) return plural(total);
    return '${vm.results.length} de ${plural(total)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

Future<void> _showFilterSheet(
  BuildContext context,
  IncidentHistoryViewModel vm,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => _FilterSheet(viewModel: vm),
      ),
    ),
  );
}

/// Panel con los filtros de tipo y rango de fechas. Los cambios se aplican
/// al momento.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.viewModel});

  final IncidentHistoryViewModel viewModel;

  Future<void> _pickDates(BuildContext context) async {
    final filter = viewModel.filter;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: filter.hasDateRange
          ? DateTimeRange(start: filter.from ?? now, end: filter.to ?? now)
          : null,
      helpText: 'Fecha de creación',
      saveText: 'Aplicar',
    );
    if (range != null) viewModel.setDateRange(from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final filter = vm.filter;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tipo de incidencia', style: titleStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: filter.type == null,
                onSelected: (_) => vm.setType(null),
              ),
              for (final type in IncidentType.values)
                ChoiceChip(
                  key: Key('history.type.${type.value}'),
                  avatar: Icon(type.icon, size: 18),
                  label: Text(type.label),
                  selected: filter.type == type,
                  onSelected: (_) => vm.setType(type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Fecha de creación', style: titleStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDates(context),
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    filter.hasDateRange
                        ? '${DateFormats.shortDate(filter.from!)} – '
                              '${DateFormats.shortDate(filter.to!)}'
                        : 'Cualquier fecha',
                  ),
                ),
              ),
              if (filter.hasDateRange) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Quitar fechas',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => vm.setDateRange(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: filter.panelCount == 0
                      ? null
                      : () {
                          vm.setType(null);
                          vm.setDateRange();
                        },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    vm.results.length == 1
                        ? 'Ver 1 resultado'
                        : 'Ver ${vm.results.length} resultados',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
