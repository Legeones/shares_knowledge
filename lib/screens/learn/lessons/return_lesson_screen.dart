import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/returns.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Leçon « Rendement et gain » : euros gagnés vs pourcentage.
class ReturnLessonScreen extends StatefulWidget {
  const ReturnLessonScreen({super.key});

  @override
  State<ReturnLessonScreen> createState() => _ReturnLessonScreenState();
}

class _ReturnLessonScreenState extends State<ReturnLessonScreen> {
  static const _buyPrice = 50.0;
  double _amount = 1000;
  double _sellPrice = 60;
  bool _quizAnswered = false;

  double get _finalValue => _amount / _buyPrice * _sellPrice;
  double get _gain => gain(invested: _amount, finalValue: _finalValue);
  double get _performance =>
      performance(invested: _amount, finalValue: _finalValue);

  String _eur(double v) => formatMoney(v, 'EUR');

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: returnLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Alice place 200 € et gagne 50 €. Bob place 5 000 € et gagne '
                '500 €. Qui a la meilleure performance ?',
            answers: const ['Alice', 'Bob', 'Ils sont à égalité'],
            correctIndex: 0,
            explanation:
                'Alice : 50 / 200 = +25 %. Bob : 500 / 5 000 = +10 %. '
                'Bob a gagné plus d’euros, mais Alice a mieux fait fructifier '
                'chaque euro placé.',
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
        Text(
          'Tu achètes pour ${_eur(1000)} d’actions, à ${_eur(_buyPrice)} '
          'l’une. Quelques mois plus tard, l’action vaut ${_eur(60)}.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Pour savoir si c’était un bon placement, deux mesures existent : '
          'le gain en euros, et la performance en pourcentage. Elles ne disent '
          'pas la même chose.',
        ),
        const SizedBox(height: 16),
        const Text('Touche un mot pour sa définition :'),
        const SizedBox(height: 8),
        const Wrap(spacing: 16, children: [Term('gain'), Term('performance')]),
      ],
    );
  }

  Widget _playground() {
    final isGain = _gain >= 0;
    final color = isGain ? AppColors.gain : AppColors.loss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Somme investie : ${_eur(_amount)}'),
        Slider(
          value: _amount,
          min: 100,
          max: 10000,
          divisions: 99,
          label: _eur(_amount),
          onChanged: (v) => setState(() => _amount = v),
        ),
        Text(
          'Prix de revente de l’action : ${_eur(_sellPrice)} '
          '(achetée ${_eur(_buyPrice)})',
        ),
        Slider(
          value: _sellPrice,
          min: 20,
          max: 100,
          divisions: 80,
          label: _eur(_sellPrice),
          onChanged: (v) => setState(() => _sellPrice = v),
        ),
        const SizedBox(height: 16),
        _Bars(start: _amount, end: _finalValue, maxValue: 20000),
        const SizedBox(height: 16),
        Row(
          children: [
            _Figure(
              label: isGain ? 'Gain' : 'Perte',
              value: formatSignedMoney(_gain, 'EUR'),
              color: color,
            ),
            _Figure(
              label: 'Performance',
              value: formatPercent(_performance),
              color: color,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Essaie : change seulement la somme investie. Le gain en euros '
          'change… mais la performance reste la même.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _takeaway() {
    final perf = formatPercent(_performance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avec ${_eur(_amount)}, tu termines à ${_eur(_finalValue)} : '
          '${formatSignedMoney(_gain, 'EUR')}, soit $perf.',
        ),
        const SizedBox(height: 12),
        Text(
          'Avec 10 fois plus d’argent, tu gagnerais 10 fois plus d’euros, '
          'mais toujours $perf : la performance ne dépend que du prix '
          'd’achat et du prix de revente.',
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
                Text('• Le gain en euros dépend de la somme investie.'),
                Text(
                  '• La performance (%) permet de comparer deux placements '
                  'de tailles différentes.',
                ),
                Text('• Performance = gain ÷ somme investie.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Deux barres « départ » et « arrivée » dont la hauteur s'anime.
class _Bars extends StatelessWidget {
  final double start;
  final double end;
  final double maxValue;
  const _Bars({required this.start, required this.end, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    const maxHeight = 160.0;
    Widget bar(String label, double value, Color color) => Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(formatMoney(value, 'EUR'), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          // AnimatedContainer : la hauteur glisse vers sa nouvelle valeur.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: (value / maxValue * maxHeight).clamp(2, maxHeight),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: color,
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );

    return SizedBox(
      height: maxHeight + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bar('Départ', start, AppColors.blue),
          bar('Arrivée', end, end >= start ? AppColors.gain : AppColors.loss),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded : les deux chiffres se partagent la largeur sans déborder.
    return Expanded(
      child: Column(
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
