import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Cifra destacada del resumen, por ejemplo "Total: 12".
class StatsSummaryTile extends StatelessWidget {
  const StatsSummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una sección del dashboard, con título e ícono.
class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Texto dentro de una sección que no tiene datos.
class StatsEmpty extends StatelessWidget {
  const StatsEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Acomoda las secciones en 1, 2 o 3 columnas según el ancho.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.children});

  final List<Widget> children;

  static int columnsFor(double width) => width >= 1100
      ? 3
      : width >= 700
      ? 2
      : 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = columnsFor(constraints.maxWidth);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Un renglón de una estadística: etiqueta, cantidad y color.
class StatsEntry {
  const StatsEntry({
    required this.label,
    required this.count,
    required this.color,
    this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData? icon;
}

/// Lista de cantidades con su porcentaje del total.
class StatsCountList extends StatelessWidget {
  const StatsCountList({super.key, required this.entries, required this.total});

  final List<StatsEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(entry.icon ?? Icons.circle, size: 16, color: entry.color),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.label, style: textTheme.bodyMedium)),
                Text(
                  '${entry.count}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatPercent(entry.count, total),
                    textAlign: TextAlign.end,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "25 %" o "33.3 %" del total; "0 %" si no hay incidencias.
String formatPercent(int count, int total) {
  if (total == 0) return '0 %';
  final value = count * 100 / total;
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text %';
}
