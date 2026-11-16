import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/returns.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Leçon « Rendement composé » : l'effet du temps et du réinvestissement.
class CompoundLessonScreen extends StatefulWidget {
  const CompoundLessonScreen({super.key});

  @override
  State<CompoundLessonScreen> createState() => _CompoundLessonScreenState();
}

class _CompoundLessonScreenState extends State<CompoundLessonScreen> {
  double _capital = 1000;
  double _rate = 0.07;
  int _years = 30;
  bool _quizAnswered = false;

  static const _hypothesis =
      'taux constant chaque année. Ce n’est pas un cours historique : '
      'en réalité, les rendements varient d’une année à l’autre.';

  List<GrowthRow> get _table =>
      growthTable(capital: _capital, annualRate: _rate, years: _years);

  String _eur(double v) => formatMoney(v, 'EUR');
  String _pct(double r) => formatPercent(r, signed: false);

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: compoundLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Tu places 1 000 € à 10 % par an et tu réinvestis les gains. '
                'Combien as-tu au bout de 2 ans ?',
            answers: const ['1 200 €', '1 210 €', '1 100 €'],
            correctIndex: 1,
            explanation:
                'Année 1 : 1 000 € + 10 % = 1 100 €. Année 2 : 1 100 € + 10 % '
                '= 1 210 €. Les 100 € gagnés la 1re année ont rapporté 10 € de '
                'plus : c’est l’effet composé. Sans réinvestissement, on aurait '
                '1 200 €.',
            onAnswered: () => setState(() => _quizAnswered = true),
          ),
        ),
      ],
    );
  }

  Widget _situation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deux amis placent chacun 1 000 € à 7 % par an. Le premier '
          'dépense ses gains chaque année. Le second les laisse placés : ses '
          'gains rapportent à leur tour.',
        ),
        const SizedBox(height: 12),
        const Text('Au bout de 30 ans, l’écart est-il petit ou énorme ?'),
        const SizedBox(height: 16),
        const Text('Touche un mot pour sa définition :'),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Term('rendement composé'),
            Term('intérêts simples'),
            Term('taux annuel'),
          ],
        ),
        const SizedBox(height: 16),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _playground() {
    final last = _table.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Capital de départ : ${_eur(_capital)}'),
        Slider(
          value: _capital,
          min: 100,
          max: 20000,
          divisions: 199,
          label: _eur(_capital),
          onChanged: (v) => setState(() => _capital = v),
        ),
        Text('Taux annuel : ${_pct(_rate)}'),
        Slider(
          value: _rate,
          max: 0.15,
          divisions: 30,
          label: _pct(_rate),
          onChanged: (v) => setState(() => _rate = v),
        ),
        Text('Durée : $_years ans'),
        Slider(
          value: _years.toDouble(),
          min: 1,
          max: 40,
          divisions: 39,
          label: '$_years ans',
          onChanged: (v) => setState(() => _years = v.round()),
        ),
        const SizedBox(height: 8),
        _GrowthChart(table: _table),
        const SizedBox(height: 8),
        _Row('Avec réinvestissement', _eur(last.compound), AppColors.blue),
        _Row('Sans réinvestissement', _eur(last.simple), AppColors.turquoise),
        _Row(
          'Gagné grâce au réinvestissement',
          formatSignedMoney(last.compound - last.simple, 'EUR'),
          AppColors.gain,
        ),
        const SizedBox(height: 12),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _takeaway() {
    final doubling = doublingYears(_rate);
    final last = _table.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avec ${_eur(_capital)} à ${_pct(_rate)} pendant $_years ans, le '
          'réinvestissement fait passer le résultat de ${_eur(last.simple)} '
          'à ${_eur(last.compound)}.',
        ),
        const SizedBox(height: 12),
        if (doubling != null)
          Text(
            'À ${_pct(_rate)} par an, un capital double environ tous les '
            '${doubling.toStringAsFixed(1).replaceAll('.', ',')} ans.',
          ),
        const SizedBox(height: 12),
        const Text(
          'Au début, les deux courbes sont presque confondues. L’écart se '
          'creuse avec le temps : plus la durée est longue, plus l’effet '
          'composé est fort.',
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À retenir',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Réinvestir les gains les fait travailler à leur tour.'),
                Text('• Le temps est le facteur le plus puissant.'),
                Text(
                  '• Un taux constant est une hypothèse : un vrai placement '
                  'monte et baisse, et peut perdre de l’argent.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Courbes « avec » et « sans » réinvestissement, année par année.
class _GrowthChart extends StatelessWidget {
  final List<GrowthRow> table;
  const _GrowthChart({required this.table});

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact(locale: 'fr_FR');
    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            lineBarsData: [
              _line([
                for (final r in table) FlSpot(r.year.toDouble(), r.compound),
              ], AppColors.blue),
              _line([
                for (final r in table) FlSpot(r.year.toDouble(), r.simple),
              ], AppColors.turquoise),
            ],
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
                  // La borne haute tombe sur une valeur arrondie bizarre : masquée.
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : SideTitleWidget(
                          meta: meta,
                          child: Text(
                            compact.format(v),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'années',
                  style: TextStyle(fontSize: 11),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: table.length > 10 ? 10 : 1,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: false),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Row(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
