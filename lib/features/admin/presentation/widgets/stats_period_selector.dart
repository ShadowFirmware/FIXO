import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/stats_period.dart';
import '../providers/incident_stats_view_model.dart';

/// Selección del periodo: semanal, mensual o personalizado, con flechas
/// para ir al periodo anterior o siguiente.
class StatsPeriodSelector extends StatelessWidget {
  const StatsPeriodSelector({super.key, required this.viewModel});

  final IncidentStatsViewModel viewModel;

  Future<void> _pickRange(BuildContext context) async {
    final period = viewModel.period;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: period.kind == StatsPeriodKind.custom
          ? DateTimeRange(start: period.start, end: period.lastDay)
          : null,
      helpText: 'Periodo de consulta',
      saveText: 'Aplicar',
    );
    if (range == null) return;
    final error = viewModel.setCustomRange(range.start, range.end);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final period = vm.period;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<StatsPeriodKind>(
            showSelectedIcon: false,
            segments: [
              for (final kind in StatsPeriodKind.values)
                ButtonSegment(
                  value: kind,
                  label: Text(
                    kind.label,
                    key: Key('stats.period.${kind.name}'),
                  ),
                ),
            ],
            selected: {period.kind},
            onSelectionChanged: (selection) {
              final kind = selection.first;
              if (kind == StatsPeriodKind.custom) {
                _pickRange(context);
              } else {
                vm.selectKind(kind);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                key: const Key('stats.previous'),
                tooltip: 'Periodo anterior',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: vm.previous,
              ),
              Expanded(
                child: TextButton(
                  key: const Key('stats.periodLabel'),
                  onPressed: period.kind == StatsPeriodKind.custom
                      ? () => _pickRange(context)
                      : null,
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('stats.next'),
                tooltip: 'Periodo siguiente',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: vm.canGoNext ? vm.next : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
