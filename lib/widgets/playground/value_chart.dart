import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../chart_touch.dart';
import '../../logic/playground/chart_data.dart';
import '../../models/simulation.dart';

/// Graphique du résultat : valeur du portefeuille ou cours de l'actif,
/// montant investi en pointillés, baisse maximale en rouge.
class ValueChart extends StatefulWidget {
  final SimulationResult result;

  /// Mode « rejeu » : seuls les [revealCount] premiers jours sont dessinés.
  final int? revealCount;

  const ValueChart({super.key, required this.result, this.revealCount});

  @override
  State<ValueChart> createState() => _ValueChartState();
}

class _ValueChartState extends State<ValueChart> {
  ChartMode _mode = ChartMode.value;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final currency = result.params.asset.currency;
    final points = chartPoints(result.history, _mode);
    final showInvested = _mode == ChartMode.value;
    // Bornes calculées sur TOUS les points, même en rejeu : axes stables.
    final bounds = verticalBounds(
      points,
      alsoInclude: showInvested ? result.totalInvested : null,
    );

    final isReplay = widget.revealCount != null;
    final shown = isReplay
        ? points.take(widget.revealCount!.clamp(1, points.length)).toList()
        : points;

    // En versements mensuels, la somme versée monte par marches.
    final monthly = result.params.isMonthly;
    final invested = [
      for (final (i, p) in shown.indexed)
        ChartPoint(p.x, result.history[i].invested, p.date),
    ];

    final dd = result.drawdown;
    // La baisse maximale est un bilan : on ne la montre pas pendant le rejeu.
    // En mensuel, c'est celle du cours : on la montre sur la vue « Cours ».
    final hasDrawdown =
        dd.depth > 0 && !isReplay && (!monthly || _mode == ChartMode.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bascule entre les deux vues.
        SegmentedButton<ChartMode>(
          segments: const [
            ButtonSegment(
              value: ChartMode.value,
              label: Text('Mon investissement'),
            ),
            ButtonSegment(value: ChartMode.price, label: Text('Cours')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 16),
        // Résumé lu par les lecteurs d'écran (accessibilité).
        Semantics(
          label:
              'Graphique de ${formatDate(result.actualStart)} à '
              '${formatDate(result.actualEnd)}, de '
              '${formatMoney(shown.first.y, currency)} à '
              '${formatMoney(shown.last.y, currency)}.',
          child: AspectRatio(
            aspectRatio: 1.4,
            // Marge à droite : la dernière date sous l'axe n'est pas coupée.
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: LineChart(
                LineChartData(
                  minX: points.first.x,
                  maxX: points.last.x,
                  minY: bounds.minY,
                  maxY: bounds.maxY,
                  lineBarsData: [
                    _mainLine(shown, markLast: isReplay),
                    if (showInvested && monthly) _investedSteps(invested),
                    if (hasDrawdown)
                      _drawdownLine(
                        points[dd.peakIndex],
                        points[dd.troughIndex],
                      ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (showInvested && !monthly)
                        _investedLine(result.totalInvested),
                    ],
                  ),
                  titlesData: _titles(points),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  // Seule la courbe principale (n° 0) affiche une bulle.
                  lineTouchData: chartTouch(
                    (s) => s.barIndex != 0
                        ? null
                        : '${formatDate(points[s.spotIndex].date)}\n'
                              '${formatMoney(s.y, currency)}',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _Legend(
              color: AppColors.blue,
              label: showInvested ? 'Valeur' : 'Cours de clôture',
            ),
            if (showInvested)
              const _Legend(
                color: AppColors.turquoise,
                label: 'Montant investi',
                dashed: true,
              ),
            if (hasDrawdown)
              _Legend(
                color: AppColors.loss,
                label:
                    'Baisse maximale (−${formatPercent(dd.depth, signed: false)})',
              ),
          ],
        ),
      ],
    );
  }

  /// [markLast] : en rejeu, un rond marque le jour courant.
  LineChartBarData _mainLine(List<ChartPoint> points, {bool markLast = false}) {
    return LineChartBarData(
      spots: [for (final p in points) FlSpot(p.x, p.y)],
      color: AppColors.blue,
      barWidth: 2.5,
      dotData: FlDotData(
        show: markLast, // pas de rond sur chaque jour…
        checkToShowDot: (spot, bar) =>
            spot == bar.spots.last, // …sauf le dernier
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: AppColors.fadeDown(AppColors.blue),
      ),
    );
  }

  /// Segment pointillé rouge entre le sommet et le creux de la baisse maximale.
  LineChartBarData _drawdownLine(ChartPoint peak, ChartPoint trough) {
    return LineChartBarData(
      spots: [FlSpot(peak.x, peak.y), FlSpot(trough.x, trough.y)],
      color: AppColors.loss,
      barWidth: 2,
      dashArray: [4, 4],
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: AppColors.loss,
          strokeWidth: 0,
        ),
      ),
    );
  }

  /// Somme versée au fil des mois : une marche à chaque versement.
  LineChartBarData _investedSteps(List<ChartPoint> points) {
    return LineChartBarData(
      spots: [for (final p in points) FlSpot(p.x, p.y)],
      isStepLineChart: true,
      color: AppColors.turquoise,
      barWidth: 2,
      dashArray: [6, 4],
      dotData: const FlDotData(show: false),
    );
  }

  HorizontalLine _investedLine(double invested) {
    return HorizontalLine(
      y: invested,
      color: AppColors.turquoise,
      strokeWidth: 2,
      dashArray: [6, 4],
    );
  }

  FlTitlesData _titles(List<ChartPoint> points) {
    final compact = NumberFormat.compact(locale: 'fr_FR');
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return FlTitlesData(
      topTitles: hidden,
      rightTitles: hidden,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            // Les bornes tombent souvent sur des valeurs « bizarres » : on les masque.
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(
                compact.format(value),
                style: const TextStyle(fontSize: 11),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: bottomLabelInterval(points),
          getTitlesWidget: (value, meta) {
            final date = points.first.date.add(Duration(days: value.round()));
            return SideTitleWidget(
              meta: meta,
              child: Text(
                DateFormat('MM/yy').format(date),
                style: const TextStyle(fontSize: 11),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Petit élément de légende : un trait coloré et un libellé.
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _Legend({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 3,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4, height: 3, color: color),
                  ],
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
