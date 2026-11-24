import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/risk.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Leçon « Baisse maximale » : une perte se rattrape plus difficilement
/// qu'elle ne se subit.
class DrawdownLessonScreen extends StatefulWidget {
  const DrawdownLessonScreen({super.key});

  @override
  State<DrawdownLessonScreen> createState() => _DrawdownLessonScreenState();
}

class _DrawdownLessonScreenState extends State<DrawdownLessonScreen> {
  double _loss = 0.5;
  double _rate = 0.07;
  bool _quizAnswered = false;

  static const _start = 10000.0;
  static const _hypothesis =
      'chute d’un seul coup, puis progression régulière chaque année. En '
      'réalité, la remontée est irrégulière et n’est jamais garantie.';

  String _eur(double v) => formatMoney(v, 'EUR');
  String _pct(double r) => formatPercent(r, signed: false);

  /// Valeur année par année : la chute la 1re année, puis la remontée au
  /// taux choisi jusqu'à revenir au départ (et un peu au-delà).
  List<double> get _path {
    final years = yearsToRecover(_loss, _rate)?.ceil() ?? 0;
    final values = [_start, _start * (1 - _loss)];
    for (var y = 0; y < years + 1; y++) {
      values.add(values.last * (1 + _rate));
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: drawdownLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Un placement perd 50 %. Quel gain lui faut-il ensuite pour '
                'revenir à sa valeur de départ ?',
            answers: const ['+50 %', '+100 %', '+200 %'],
            correctIndex: 1,
            explanation:
                '10 000 € − 50 % = 5 000 €. Pour revenir à 10 000 €, il faut '
                'doubler ces 5 000 € : +100 %. Le gain se calcule sur une '
                'somme devenue plus petite.',
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
          'Un placement de 10 000 € perd 50 % pendant un krach : il ne vaut '
          'plus que 5 000 €.',
        ),
        SizedBox(height: 12),
        Text('Pour revenir à 10 000 €, suffit-il qu’il regagne 50 % ?'),
        SizedBox(height: 16),
        Text('Touche un mot pour sa définition :'),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [Term('baisse maximale'), Term('rattrapage')],
        ),
        SizedBox(height: 16),
        HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _playground() {
    final years = yearsToRecover(_loss, _rate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Perte : −${_pct(_loss)}'),
        Slider(
          value: _loss,
          min: 0.05,
          max: 0.8,
          divisions: 15,
          label: '−${_pct(_loss)}',
          onChanged: (v) => setState(() => _loss = v),
        ),
        Text('Rendement ensuite : ${_pct(_rate)} par an'),
        Slider(
          value: _rate,
          min: 0.02,
          max: 0.12,
          divisions: 10,
          label: _pct(_rate),
          onChanged: (v) => setState(() => _rate = v),
        ),
        const SizedBox(height: 8),
        LessonChart(
          series: [(values: _path, color: AppColors.blue)],
          reference: _start,
        ),
        const SizedBox(height: 12),
        ValueLine('Il reste', _eur(_start * (1 - _loss))),
        ValueLine(
          'Gain nécessaire pour revenir',
          '+${_pct(recoveryGain(_loss))}',
          color: AppColors.loss,
        ),
        ValueLine(
          'Temps pour revenir',
          '${years!.toStringAsFixed(1).replaceAll('.', ',')} ans',
        ),
        const SizedBox(height: 12),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _takeaway() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Une perte et le gain qui la rattrape ne sont pas symétriques :',
        ),
        const SizedBox(height: 8),
        for (final loss in const [0.1, 0.25, 0.5, 0.8])
          ValueLine(
            'Après −${_pct(loss)}',
            'il faut +${_pct(recoveryGain(loss))}',
          ),
        const SizedBox(height: 12),
        const Text(
          'Exemple réel : le Nasdaq, la bourse des valeurs technologiques, a '
          'perdu près de 80 % entre 2000 et 2002. Il lui a fallu quinze ans '
          'pour retrouver son record.',
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
                Text(
                  '• La baisse maximale est la pire chute subie entre un '
                  'sommet et le creux qui suit.',
                ),
                Text(
                  '• Plus la chute est profonde, plus le rattrapage est long : '
                  'après −50 %, il faut +100 %.',
                ),
                Text(
                  '• Limiter les grosses pertes compte souvent plus que viser '
                  'les plus gros gains.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
