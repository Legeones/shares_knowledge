import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../chart_touch.dart';

/// Définitions courtes des termes nouveaux, expliqués sur place.
const glossary = {
  'gain': 'Ce que tu as à la fin moins ce que tu as mis. En euros.',
  'performance':
      'Le gain divisé par la somme investie, en pourcentage. Permet de comparer '
      'des placements de tailles différentes.',
  'rendement composé': 'Les gains sont réinvestis : l’année suivante, ils rapportent à leur tour.',
  'intérêts simples':
      'Les gains ne sont pas réinvestis : chaque année rapporte la même somme.',
  'taux annuel': 'La progression supposée chaque année, en pourcentage.',
  'volatilité':
      'L’ampleur des hausses et des baisses d’un placement d’une période à '
      'l’autre. Plus elle est forte, plus le parcours est agité.',
  'écart type':
      'L’écart moyen entre chaque valeur et la moyenne. Sert à mesurer la '
      'volatilité.',
  'baisse maximale':
      'La plus forte chute entre un sommet et le creux qui suit. On l’appelle '
      'aussi « drawdown ».',
  'rattrapage':
      'Le gain nécessaire pour revenir au point de départ après une perte.',
  'DCA':
      'Investir la même somme à intervalles réguliers (chaque mois, par '
      'exemple), quel que soit le prix. De l’anglais « dollar-cost averaging ».',
  'prix moyen d’achat':
      'Ce qu’on a payé en moyenne pour chaque part : la somme versée divisée '
      'par le nombre de parts.',
  'diversification':
      'Répartir son argent entre plusieurs placements différents, pour qu’un '
      'seul accident ne ruine pas tout.',
  'faillite':
      'L’entreprise ne peut plus payer ses dettes : ses actions perdent '
      'toute leur valeur.',
};

/// Un mot souligné : le toucher affiche sa définition.
class Term extends StatelessWidget {
  final String word;
  const Term(this.word, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(word[0].toUpperCase() + word.substring(1)),
          content: Text(glossary[word] ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Compris'),
            ),
          ],
        ),
      ),
      child: Text(
        word,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
        ),
      ),
    );
  }
}

/// Encadré « Hypothèse » : distingue un calcul théorique d'un cours réel.
class HypothesisBadge extends StatelessWidget {
  final String text;
  const HypothesisBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: colors.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hypothèse : $text',
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Question de compréhension avec retour explicatif.
class QuizCard extends StatefulWidget {
  final String question;
  final List<String> answers;
  final int correctIndex;
  final String explanation;

  /// Prévenu quand l'utilisateur a répondu (bonne réponse ou non).
  final VoidCallback? onAnswered;

  const QuizCard({
    super.key,
    required this.question,
    required this.answers,
    required this.correctIndex,
    required this.explanation,
    this.onAnswered,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _chosen;

  @override
  Widget build(BuildContext context) {
    final answered = _chosen != null;
    final isRight = _chosen == widget.correctIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.question, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final (i, answer) in widget.answers.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                backgroundColor: !answered
                    ? null
                    : i == widget.correctIndex
                    ? AppColors.gain.withValues(alpha: 0.15)
                    : i == _chosen
                    ? AppColors.loss.withValues(alpha: 0.15)
                    : null,
              ),
              // Une seule réponse possible : les boutons se bloquent ensuite.
              onPressed: answered
                  ? null
                  : () {
                      setState(() => _chosen = i);
                      widget.onAnswered?.call();
                    },
              child: Row(
                children: [
                  Expanded(child: Text(answer)),
                  if (answered && i == widget.correctIndex)
                    const Icon(Icons.check_circle, color: AppColors.gain),
                  if (answered && i == _chosen && !isRight)
                    const Icon(Icons.cancel, color: AppColors.loss),
                ],
              ),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 8),
          Text(
            isRight ? 'Bonne réponse !' : 'Pas tout à fait.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRight ? AppColors.gain : AppColors.loss,
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.explanation),
        ],
      ],
    );
  }
}

/// Une courbe d'un [LessonChart] : une valeur par année, une couleur.
typedef LessonSeries = ({List<double> values, Color color});

/// Graphique des leçons : une ou plusieurs courbes, une valeur par année,
/// et une ligne de référence facultative (ex. le capital de départ).
class LessonChart extends StatelessWidget {
  final List<LessonSeries> series;
  final double? reference;

  /// Unité de l'axe horizontal.
  final String unit;

  const LessonChart({
    super.key,
    required this.series,
    this.reference,
    this.unit = 'années',
  });

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact(locale: 'fr_FR');
    final years = series.map((s) => s.values.length).reduce(max) - 1;
    Widget label(String text, TitleMeta meta) => SideTitleWidget(
      meta: meta,
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [
                    for (final (i, v) in s.values.indexed)
                      FlSpot(i.toDouble(), v),
                  ],
                  color: s.color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (reference != null)
                  HorizontalLine(
                    y: reference!,
                    color: AppColors.muted,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
              ],
            ),
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineTouchData: chartTouch(
              (s) =>
                  '${s.barIndex == 0 ? '${unit == 'mois' ? 'Mois' : 'Année'} '
                            '${s.x.toInt()}\n' : ''}'
                  '${formatMoney(s.y, 'EUR')}',
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  // La borne haute tombe sur une valeur arrondie bizarre.
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : label(compact.format(v), meta),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  unit,
                  style: const TextStyle(fontSize: 11),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: years > 20
                      ? 5
                      : years > 10
                      ? 2
                      : 1,
                  getTitlesWidget: (v, meta) => label('${v.toInt()}', meta),
                ),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }
}

/// Une ligne « libellé … valeur ».
class ValueLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const ValueLine(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Tableau à deux colonnes comparées (ex. « Anna / Bruno »), ligne par
/// ligne. Chaque en-tête porte la couleur de sa courbe.
class CompareTable extends StatelessWidget {
  final (String, Color) left;
  final (String, Color) right;
  final List<(String, String, String)> rows;

  const CompareTable({
    super.key,
    required this.left,
    required this.right,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final bold = Theme.of(context).textTheme.titleSmall;
    Widget cell(String text, {TextStyle? style, Color? dot}) => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (dot != null) ...[
            Container(width: 10, height: 10, color: dot),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(text, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            const Expanded(flex: 2, child: SizedBox()),
            cell(left.$1, style: bold, dot: left.$2),
            cell(right.$1, style: bold, dot: right.$2),
          ],
        ),
        const Divider(),
        for (final (label, a, b) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(label)),
                cell(a, style: bold),
                cell(b, style: bold),
              ],
            ),
          ),
      ],
    );
  }
}

/// Encadré « À retenir » en fin de leçon.
class TakeawayCard extends StatelessWidget {
  final List<String> points;
  const TakeawayCard(this.points, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'À retenir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final p in points) Text('• $p'),
          ],
        ),
      ),
    );
  }
}
