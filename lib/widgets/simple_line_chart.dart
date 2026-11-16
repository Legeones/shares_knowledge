import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

/// Courbe simple (cours d'un actif, valeur du portefeuille).
///
/// Les bornes sont calculées **uniquement sur les points fournis** : dans
/// Past Trader, on ne passe que le passé, donc l'échelle ne trahit jamais
/// les prix futurs.
class SimpleLineChart extends StatelessWidget {
  final List<({DateTime date, double value})> points;
  final Color color;

  /// Ligne horizontale de référence (ex. capital de départ).
  final double? reference;

  const SimpleLineChart({
    super.key,
    required this.points,
    this.color = AppColors.blue,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Pas encore assez de données.')),
      );
    }
    final first = points.first.date;
    double x(DateTime d) => d.difference(first).inDays.toDouble();

    var low = points.map((p) => p.value).reduce(min);
    var high = points.map((p) => p.value).reduce(max);
    if (reference != null) {
      low = min(low, reference!);
      high = max(high, reference!);
    }
    final margin = max((high - low) * 0.08, high * 0.01);
    final compact = NumberFormat.compact(locale: 'fr_FR');
    final years = (x(points.last.date) / 365).ceil();

    Widget label(String t, TitleMeta meta) => SideTitleWidget(
      meta: meta,
      child: Text(t, style: const TextStyle(fontSize: 10)),
    );

    return AspectRatio(
      aspectRatio: 1.9,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: max(0, low - margin),
            maxY: high + margin,
            lineBarsData: [
              LineChartBarData(
                spots: [for (final p in points) FlSpot(x(p.date), p.value)],
                color: color,
                barWidth: 2,
                dotData: FlDotData(
                  checkToShowDot: (spot, bar) => spot == bar.spots.last,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: AppColors.fadeDown(color),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (reference != null)
                  HorizontalLine(
                    y: reference!,
                    color: AppColors.turquoise,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
              ],
            ),
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                      ? const SizedBox.shrink()
                      : label(
                          v < 10 ? v.toStringAsFixed(2) : compact.format(v),
                          meta,
                        ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: max(30, x(points.last.date) / 4),
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : label(
                          DateFormat(years > 1 ? 'MM/yy' : 'dd/MM')
                              .format(first.add(Duration(days: v.round()))),
                          meta,
                        ),
                ),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}
