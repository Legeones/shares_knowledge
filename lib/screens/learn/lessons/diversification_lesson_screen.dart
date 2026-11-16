import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/learn/diversification.dart';
import '../../../logic/drawdown.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Leçon « Diversification » : ne pas mettre tous ses œufs dans le même
/// panier.
class DiversificationLessonScreen extends StatefulWidget {
  const DiversificationLessonScreen({super.key});

  @override
  State<DiversificationLessonScreen> createState() =>
      _DiversificationLessonScreenState();
}

class _DiversificationLessonScreenState
    extends State<DiversificationLessonScreen> {
  static const _capital = 10000.0;
  static const _hypothesis =
      'entreprises imaginaires, construites pour l’exemple ; somme partagée à '
      'parts égales au départ, sans frais ni rééquilibrage.';

  int _size = 1;
  bool _quizAnswered = false;

  String _eur(double v) => formatMoney(v, 'EUR');
  String _pct(double r) => formatPercent(r, signed: false);

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: diversificationLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Quand on met plus d’entreprises dans son panier, qu’est-ce '
                'qui change surtout ?',
            answers: const [
              'Le gain moyen augmente fortement',
              'L’écart entre le meilleur et le pire résultat se réduit',
              'Le risque disparaît complètement',
            ],
            correctIndex: 1,
            explanation:
                'La moyenne de tous les paniers ne bouge pas. Ce qui change : '
                'le pire cas devient bien moins grave, car une faillite ne pèse '
                'plus que sur une petite part du panier. Le risque ne disparaît '
                'pas pour autant : une mauvaise année touche tout le monde.',
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
          'Tu as ${_eur(_capital)} à placer pendant 10 ans dans '
          '${companies.length} entreprises possibles. L’une va quadrupler, '
          'une autre va faire faillite. Mais aujourd’hui, impossible de '
          'savoir lesquelles.',
        ),
        const SizedBox(height: 12),
        const Text('Vaut-il mieux tout miser sur une seule, ou répartir ?'),
        const SizedBox(height: 16),
        const Text('Touche un mot pour sa définition :'),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [Term('diversification'), Term('faillite')],
        ),
        const SizedBox(height: 16),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _playground() {
    final range = basketRange(_size, capital: _capital);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Entreprises dans ton panier : $_size '
          '(${range.count} panier${range.count > 1 ? 's' : ''} possible'
          '${range.count > 1 ? 's' : ''})',
        ),
        Slider(
          value: _size.toDouble(),
          min: 1,
          max: companies.length.toDouble(),
          divisions: companies.length - 1,
          label: '$_size',
          onChanged: (v) => setState(() => _size = v.round()),
        ),
        const SizedBox(height: 8),
        LessonChart(
          series: [
            (values: range.best, color: AppColors.gain),
            (values: range.worst, color: AppColors.loss),
          ],
          reference: _capital,
        ),
        const SizedBox(height: 12),
        CompareTable(
          left: ('Pire panier', AppColors.loss),
          right: ('Meilleur', AppColors.gain),
          rows: [
            (
              'Au bout de 10 ans',
              _eur(range.worst.last),
              _eur(range.best.last),
            ),
            (
              'Plus forte chute',
              _pct(maxDrawdown(range.worst).depth),
              _pct(maxDrawdown(range.best).depth),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueLine('Moyenne de tous les paniers', _eur(range.averageFinal)),
        ValueLine(
          'Pire chute parmi tous les paniers',
          _pct(range.worstDrawdown),
          color: AppColors.loss,
        ),
        const SizedBox(height: 12),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _takeaway() {
    final single = basketRange(1, capital: _capital);
    final all = basketRange(companies.length, capital: _capital);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avec une seule entreprise, tu pouvais finir entre '
          '${_eur(single.worst.last)} et ${_eur(single.best.last)}. Avec les '
          '${companies.length}, tu finis à coup sûr à ${_eur(all.best.last)} : '
          'la moyenne, sans la ruine ni le jackpot.',
        ),
        const SizedBox(height: 12),
        const Text(
          'C’est l’idée des fonds indiciels (ETF) : un S&P 500 contient '
          '500 entreprises. Les faillites existent, mais chacune ne pèse '
          'qu’une petite part du total.',
        ),
        const SizedBox(height: 16),
        const TakeawayCard([
          'Diversifier ne change pas le gain moyen : cela réduit l’écart '
              'entre le meilleur et le pire résultat.',
          'Une faillite ruine celui qui a tout misé dessus, pas celui qui a '
              'réparti.',
          'Le risque ne disparaît pas : une mauvaise année pour tout le '
              'marché touche toutes les entreprises.',
        ]),
      ],
    );
  }
}
