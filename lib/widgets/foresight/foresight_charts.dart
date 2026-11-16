import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../logic/foresight/foresight.dart';
import '../../models/price_point.dart';

final _compact = NumberFormat.compact(locale: 'fr_FR');

double _log10(double v) => log(v) / ln10;

Widget _label(String text, TitleMeta meta) => SideTitleWidget(
  meta: meta,
  child: Text(text, style: const TextStyle(fontSize: 10)),
);

/// Patrimoine sur tout le parcours (investi + mis à l'abri + retiré), en
/// échelle logarithmique : chaque ligne horizontale = ×10 (1 k, 10 k…).
///
/// Le patrimoine, et pas seulement l'argent investi : mettre le surplus à
/// l'abri n'est pas une perte, la courbe ne doit pas chuter à ce moment-là.
class WealthLogChart extends StatelessWidget {
  final List<ForesightDay> days;

  /// Nombre de jours déjà « vécus » à afficher.
  final int visibleCount;

  const WealthLogChart({
    super.key,
    required this.days,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    final shown = days.take(visibleCount.clamp(1, days.length));
    final maxY = _log10(days.map((d) => d.wealth).reduce(max)).ceilToDouble();
    // Une année sur 1, 2, 5 ou 10 : au plus 5 étiquettes, sinon elles se
    // chevauchent sur un écran de téléphone.
    final years = days.length / 365;
    final everyYears = const [
      1,
      2,
      5,
      10,
    ].firstWhere((n) => years / n <= 5, orElse: () => 10);

    return AspectRatio(
      aspectRatio: 1.8,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: days.length - 1,
            minY: 3, // 10^3 = 1 000
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final (i, d) in shown.indexed)
                    FlSpot(i.toDouble(), _log10(d.wealth)),
                ],
                color: AppColors.blue,
                barWidth: 2,
                dotData: FlDotData(
                  checkToShowDot: (spot, bar) => spot == bar.spots.last,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: AppColors.fadeDown(AppColors.blue),
                ),
              ),
            ],
            gridData: const FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 1,
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 48,
                  // Montants en dollars (indiqué dans le titre du graphique).
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : _label(_compact.format(pow(10, v)), meta),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 365.0 * everyYears,
                  reservedSize: 22,
                  // La dernière borne tomberait sur une année déjà écrite.
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : _label('${days[v.toInt()].date.year}', meta),
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

/// Cours de l'actif de l'étape en cours, révélé jusqu'à la date courante.
class StepPriceChart extends StatelessWidget {
  final List<PricePoint> prices;
  final DateTime buy;
  final DateTime sell;
  final DateTime current;

  const StepPriceChart({
    super.key,
    required this.prices,
    required this.buy,
    required this.sell,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final window = [
      for (final p in prices)
        if (!p.date.isBefore(buy) && !p.date.isAfter(sell)) p,
    ];
    final shown = [
      for (final p in window)
        if (!p.date.isAfter(current)) p,
    ];
    double x(DateTime d) => d.difference(buy).inDays.toDouble();
    final values = window.map((p) => p.close);
    final low = values.reduce(min);
    final high = values.reduce(max);

    return AspectRatio(
      aspectRatio: 2.2,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: x(sell),
            minY: low * 0.9,
            maxY: high * 1.05,
            lineBarsData: [
              LineChartBarData(
                spots: [for (final p in shown) FlSpot(x(p.date), p.close)],
                color: AppColors.turquoise,
                barWidth: 2,
                dotData: FlDotData(
                  checkToShowDot: (spot, bar) => spot == bar.spots.last,
                ),
              ),
            ],
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                      ? const SizedBox.shrink()
                      : _label(_price(v), meta),
                ),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  /// Dogecoin vaut quelques centimes : plus de décimales.
  static String _price(double v) =>
      v < 1 ? v.toStringAsFixed(2) : _compact.format(v);
}
