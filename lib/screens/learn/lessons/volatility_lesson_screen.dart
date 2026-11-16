import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/drawdown.dart';
import '../../../logic/risk.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Leçon « Volatilité » : même résultat final, parcours très différents.
class VolatilityLessonScreen extends StatefulWidget {
  const VolatilityLessonScreen({super.key});

  @override
  State<VolatilityLessonScreen> createState() => _VolatilityLessonScreenState();
}

class _VolatilityLessonScreenState extends State<VolatilityLessonScreen> {
  /// Force des secousses du parcours de Bruno (0 = aussi calme qu'Anna).
  double _amplitude = 0.25;
  bool _quizAnswered = false;

  static const _start = 1000.0;
  static const _end = 1500.0;
  static const _hypothesis =
      'parcours imaginaires, construits pour l’exemple : ce ne sont pas des '
      'cours historiques.';

  List<double> get _anna =>
      pathWithVolatility(start: _start, end: _end, amplitude: 0);
  List<double> get _bruno =>
      pathWithVolatility(start: _start, end: _end, amplitude: _amplitude);

  String _eur(double v) => formatMoney(v, 'EUR');
  String _pct(double r) => formatPercent(r, signed: false);

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: volatilityLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Deux placements passent de 1 000 € à 1 500 € en 10 ans. L’un '
                'a perdu 40 % en cours de route, l’autre jamais plus de 5 %. '
                'Lequel était le plus risqué ?',
            answers: const [
              'Celui qui a perdu 40 %',
              'Aucun : ils ont le même résultat',
              'Celui qui n’a jamais perdu plus de 5 %',
            ],
            correctIndex: 0,
            explanation:
                'Le résultat final ne dit pas tout. Avec une chute de 40 %, '
                'beaucoup d’investisseurs auraient vendu par peur, au pire '
                'moment, et n’auraient jamais vu les 1 500 €.',
            onAnswered: () => setState(() => _quizAnswered = true),
          ),
        ),
      ],
    );
  }

  Widget _situation() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anna et Bruno placent chacun 1 000 € pendant 10 ans. À la fin, ils '
          'ont tous les deux 1 500 €.',
        ),
        SizedBox(height: 12),
        Text('Ont-ils pris le même risque ?'),
        SizedBox(height: 16),
        Text('Touche un mot pour sa définition :'),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Term('volatilité'),
            Term('écart type'),
            Term('baisse maximale'),
          ],
        ),
        SizedBox(height: 16),
        HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _playground() {
    final anna = _anna;
    final bruno = _bruno;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Agitation du placement de Bruno : ${(_amplitude * 100).round()}'),
        Slider(
          value: _amplitude,
          max: 0.4,
          divisions: 40,
          onChanged: (v) => setState(() => _amplitude = v),
        ),
        const SizedBox(height: 8),
        LessonChart(
          series: [
            (values: anna, color: AppColors.turquoise),
            (values: bruno, color: AppColors.blue),
          ],
          reference: _start,
        ),
        const SizedBox(height: 12),
        CompareTable(
          left: ('Anna', AppColors.turquoise),
          right: ('Bruno', AppColors.blue),
          rows: [
            ('Résultat final', _eur(anna.last), _eur(bruno.last)),
            ('Volatilité', _pct(volatility(anna)), _pct(volatility(bruno))),
            (
              'Pire année',
              formatPercent(worstReturn(anna)),
              formatPercent(worstReturn(bruno)),
            ),
            (
              'Baisse maximale',
              _pct(maxDrawdown(anna).depth),
              _pct(maxDrawdown(bruno).depth),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _takeaway() {
    final bruno = _bruno;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anna et Bruno finissent à ${_eur(_end)}. Mais Bruno a connu une '
          'année à ${formatPercent(worstReturn(bruno))} et une chute de '
          '${_pct(maxDrawdown(bruno).depth)} en chemin.',
        ),
        const SizedBox(height: 12),
        const Text(
          'La volatilité mesure cette agitation : l’écart type des '
          'rendements d’une année à l’autre. Les actions sont bien plus '
          'volatiles que le livret ou les obligations ; les cryptomonnaies, '
          'encore beaucoup plus.',
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
                Text('• Même résultat final ne veut pas dire même risque.'),
                Text(
                  '• Plus un placement est volatil, plus il est difficile à '
                  'garder dans les mauvais moments.',
                ),
                Text(
                  '• La volatilité n’est pas une perte : elle le devient si '
                  'on vend au mauvais moment, ou si on a besoin de l’argent.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
