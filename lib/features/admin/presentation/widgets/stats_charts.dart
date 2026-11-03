import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'stats_widgets.dart';

/// Gráfica de barras horizontales: la barra más larga es la de mayor
/// cantidad, y cada renglón muestra su cantidad y porcentaje del [total].
class StatsBarChart extends StatelessWidget {
  const StatsBarChart({super.key, required this.entries, required this.total});

  final List<StatsEntry> entries;
  final int total;

  /// Largo de la barra entre 0 y 1, respecto a la mayor cantidad.
  static double barFactor(int count, int maxCount) =>
      maxCount == 0 ? 0 : count / maxCount;

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.fold(0, (m, e) => math.max(m, e.count));
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final entry in entries)
          Semantics(
            label:
                '${entry.label}: ${entry.count}, '
                '${formatPercent(entry.count, total)}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (entry.icon != null) ...[
                        Icon(entry.icon, size: 16, color: entry.color),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${entry.count} · ${formatPercent(entry.count, total)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 10, color: AppColors.surfaceAlt),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: barFactor(entry.count, maxCount)),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          builder: (context, value, _) => FractionallySizedBox(
                            widthFactor: value,
                            child: Container(height: 10, color: entry.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Gráfica de dona con el total al centro y la leyenda debajo.
class StatsDonutChart extends StatelessWidget {
  const StatsDonutChart({
    super.key,
    required this.entries,
    required this.total,
  });

  final List<StatsEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: StatsDonutPainter(
              values: [for (final e in entries) e.count],
              colors: [for (final e in entries) e.color],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    total == 1 ? 'incidencia' : 'incidencias',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StatsCountList(entries: entries, total: total),
      ],
    );
  }
}

/// Dibuja un arco por cada valor, proporcional a su parte del total.
class StatsDonutPainter extends CustomPainter {
  StatsDonutPainter({required this.values, required this.colors});

  final List<int> values;
  final List<Color> colors;

  /// Ángulo de cada valor en radianes; suman una vuelta completa.
  static List<double> sweeps(List<int> values) {
    final total = values.fold(0, (sum, v) => sum + v);
    if (total == 0) return [for (final _ in values) 0];
    return [for (final v in values) v / total * 2 * math.pi];
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: math.min(size.width, size.height) / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      paint..color = AppColors.surfaceAlt,
    );
    var start = -math.pi / 2;
    final angles = sweeps(values);
    for (var i = 0; i < angles.length; i++) {
      if (angles[i] == 0) continue;
      canvas.drawArc(rect, start, angles[i], false, paint..color = colors[i]);
      start += angles[i];
    }
  }

  @override
  bool shouldRepaint(StatsDonutPainter old) =>
      old.values.toString() != values.toString() ||
      old.colors.toString() != colors.toString();
}
