import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';

/// Une part du portefeuille : son nom et sa valeur.
typedef AllocationSlice = ({String label, double value});

/// Couleurs des parts, dans l'ordre ; le cash est toujours gris.
const _colors = [
  AppColors.blue,
  AppColors.turquoise,
  AppColors.gold,
  AppColors.navy,
  AppColors.sky,
  AppColors.gain,
  AppColors.loss,
];

/// Répartition du portefeuille : un anneau (une part par position, plus le
/// cash) et sa légende avec les pourcentages.
class AllocationChart extends StatefulWidget {
  final List<AllocationSlice> positions;
  final double cash;

  const AllocationChart({
    super.key,
    required this.positions,
    required this.cash,
  });

  @override
  State<AllocationChart> createState() => _AllocationChartState();
}

class _AllocationChartState extends State<AllocationChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (final (i, p) in widget.positions.indexed)
        (label: p.label, value: p.value, color: _colors[i % _colors.length]),
      if (widget.cash > 0.005)
        (label: 'Cash', value: widget.cash, color: AppColors.muted),
    ];
    final total = slices.fold(0.0, (sum, s) => sum + s.value);
    if (total <= 0) return const SizedBox.shrink();

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) => setState(
                  () => _touched = event.isInterestedForInteractions
                      ? response?.touchedSection?.touchedSectionIndex
                      : null,
                ),
              ),
              sections: [
                for (final (i, s) in slices.indexed)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: i == _touched ? 30 : 24,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in slices.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: i == _touched ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      Text(
                        formatPercent(s.value / total, signed: false),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
