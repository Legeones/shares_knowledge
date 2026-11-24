import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/learn/lessons.dart';
import '../../../core/theme.dart';
import '../../../logic/learn/dca.dart';
import '../../../widgets/learn/lesson_widgets.dart';
import 'lesson_scaffold.dart';

/// Un marché imaginaire : le prix d'une part au début de chaque mois.
typedef _Market = ({String label, List<double> prices});

/// Leçon « Investir régulièrement » : tout d'un coup ou chaque mois ?
class DcaLessonScreen extends StatefulWidget {
  const DcaLessonScreen({super.key});

  @override
  State<DcaLessonScreen> createState() => _DcaLessonScreenState();
}

class _DcaLessonScreenState extends State<DcaLessonScreen> {
  static const _total = 12000.0;
  static const _months = 12;

  /// 13 prix : 12 mois de versements, puis la valeur au bout d'un an.
  static final List<_Market> _markets = [
    (
      label: 'Hausse',
      prices: [for (var i = 0; i <= _months; i++) 100 + 30 * i / _months],
    ),
    (
      label: 'Krach',
      prices: [100, 92, 80, 68, 60, 58, 62, 70, 78, 86, 94, 100, 106],
    ),
    (
      label: 'Baisse',
      prices: [for (var i = 0; i <= _months; i++) 100 - 25 * i / _months],
    ),
  ];

  static const _hypothesis =
      'marchés imaginaires, construits pour l’exemple ; pas de frais. La part '
      'non encore versée en DCA reste de côté, sans rapporter.';

  int _market = 1;
  bool _quizAnswered = false;

  List<double> get _prices => _markets[_market].prices;
  InvestmentResult get _lump => lumpSum(_prices, _total);
  InvestmentResult get _dca =>
      regularInvestment(_prices, _total / _months, _months);

  String _eur(double v) => formatMoney(v, 'EUR');

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lesson: dcaLesson,
      steps: [
        LessonStep(title: 'La situation', content: _situation()),
        LessonStep(title: 'À toi de manipuler', content: _playground()),
        LessonStep(title: 'Ce qu’il faut retenir', content: _takeaway()),
        LessonStep(
          title: 'Vérifie ta compréhension',
          canContinue: _quizAnswered,
          content: QuizCard(
            question:
                'Tu investis 100 € chaque mois. Pourquoi ton prix moyen '
                'd’achat est-il souvent plus bas que le prix moyen du marché ?',
            answers: const [
              'Les frais sont plus bas',
              'On achète plus de parts quand le prix est bas',
              'Le marché finit toujours par monter',
            ],
            correctIndex: 1,
            explanation:
                'À 100 € par mois, une part à 50 € t’en donne 2, une part à '
                '100 € une seule. Les mois où le prix est bas pèsent plus dans '
                'ton panier : ton prix moyen baisse.',
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
          'Clara a 12 000 € à investir. Elle peut tout placer aujourd’hui, ou '
          'verser 1 000 € chaque mois pendant un an.',
        ),
        SizedBox(height: 12),
        Text('Quelle méthode lui rapportera le plus ? Ça dépend du marché…'),
        SizedBox(height: 16),
        Text('Touche un mot pour sa définition :'),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [Term('DCA'), Term('prix moyen d’achat')],
        ),
        SizedBox(height: 16),
        HypothesisBadge(_hypothesis),
      ],
    );
  }

  Widget _playground() {
    final lump = _lump;
    final dca = _dca;
    final dcaWins = dca.finalValue > lump.finalValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Comment évolue le marché pendant l’année ?'),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final (i, m) in _markets.indexed)
              ButtonSegment(value: i, label: Text(m.label)),
          ],
          selected: {_market},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _market = s.first),
        ),
        const SizedBox(height: 8),
        LessonChart(
          series: [
            (values: lump.values, color: AppColors.turquoise),
            (values: dca.values, color: AppColors.blue),
          ],
          unit: 'mois',
        ),
        const SizedBox(height: 12),
        CompareTable(
          left: ('En une fois', AppColors.turquoise),
          right: ('Chaque mois', AppColors.blue),
          rows: [
            ('Parts achetées', _units(lump.units), _units(dca.units)),
            (
              'Prix moyen d’achat',
              _eur(lump.averageCost),
              _eur(dca.averageCost),
            ),
            ('Au bout d’un an', _eur(lump.finalValue), _eur(dca.finalValue)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          dcaWins
              ? 'Ici, verser chaque mois rapporte plus : les mois de baisse '
                    'ont permis d’acheter des parts moins chères.'
              : 'Ici, tout placer d’un coup rapporte plus : l’argent a '
                    'profité de la hausse dès le premier mois.',
          style: TextStyle(color: dcaWins ? AppColors.blue : AppColors.ink),
        ),
        const SizedBox(height: 12),
        const HypothesisBadge(_hypothesis),
      ],
    );
  }

  String _units(double u) => u.toStringAsFixed(1).replaceAll('.', ',');

  Widget _takeaway() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aucune méthode ne gagne à tous les coups. Quand le marché monte, '
          'tout placer d’un coup rapporte plus ; quand il chute puis remonte, '
          'les versements réguliers achètent des parts au rabais.',
        ),
        SizedBox(height: 12),
        Text(
          'Comme les marchés montent plus souvent qu’ils ne baissent, le '
          'placement en une fois l’emporte le plus souvent sur le long terme. '
          'Mais le DCA évite de tout investir la veille d’un krach, et '
          'correspond à la vie réelle : on épargne une partie de son salaire '
          'chaque mois.',
        ),
        SizedBox(height: 16),
        TakeawayCard([
          'Le DCA consiste à investir la même somme à intervalles réguliers.',
          'On achète automatiquement plus de parts quand le prix est bas.',
          'Il ne rapporte pas toujours plus, mais réduit le risque de mal '
              'choisir son moment.',
        ]),
      ],
    );
  }
}
