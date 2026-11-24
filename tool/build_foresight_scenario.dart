// ignore_for_file: avoid_print — script en ligne de commande.

// Génère assets/scenarios/foresight/foresight_<décennie>s.json à partir des
// vrais cours, un fichier par décennie.
//
// Usage (depuis la racine du projet) :
//   dart run tool/build_foresight_scenario.dart          → toutes
//   dart run tool/build_foresight_scenario.dart 1990     → une seule
//
// Consomme une requête Twelve Data par étape d'actif, espacées de 8 s.

import 'dart:convert';
import 'dart:io';

import 'package:shares_knowledge/data/api/twelve_data_api.dart';
import 'package:shares_knowledge/models/price_point.dart';

import 'foresight/steps_1970s.dart';
import 'foresight/steps_1980s.dart';
import 'foresight/steps_1990s.dart';
import 'foresight/steps_2000s.dart';
import 'foresight/steps_2010s.dart';
import 'foresight/steps_2020s.dart';
import 'text_utils.dart';

/// Les parcours, par décennie de départ.
const decades = [
  (decade: 1970, steps: steps1970s),
  (decade: 1980, steps: steps1980s),
  (decade: 1990, steps: steps1990s),
  (decade: 2000, steps: steps2000s),
  (decade: 2010, steps: steps2010s),
  (decade: 2020, steps: steps2020s),
];

/// Réserve maximale réinvestie à l'achat d'une étape (règle proposée avec
/// les parcours) : au-delà, un portefeuille ferait bouger les prix, le
/// surplus est mis à l'abri.
num maxInvestFor(Map<String, String> step) {
  if (step['symbol'] == 'DOGE/USD') return 100000;
  return DateTime.parse(step['buy']!).year < 1990 ? 10000 : 1000000;
}

Future<void> main(List<String> args) async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  final api = TwelveDataApi(apiKey: env['TWELVE_DATA_KEY'] as String);
  final only = args.isEmpty ? null : int.parse(args.first);

  var first = true;
  for (final d in decades.where((d) => only == null || d.decade == only)) {
    // Cours par symbole ; un symbole présent deux fois (Netflix dans les
    // années 2010) cumule ses deux fenêtres.
    final prices = <String, Map<String, double>>{};
    for (final step in d.steps.where((s) => s['kind'] == 'asset')) {
      if (!first) await Future<void>.delayed(const Duration(seconds: 8));
      first = false;
      final symbol = step['symbol']!;
      // Marge de 2 semaines autour de l'étape : contexte du graphique et
      // calcul « et si on avait vendu un jour plus tard ? ».
      final points = await api.fetchDailySeries(
        symbol,
        start: DateTime.parse(step['buy']!).subtract(const Duration(days: 14)),
        end: DateTime.parse(step['sell']!).add(const Duration(days: 14)),
      );
      final series = prices.putIfAbsent(symbol, () => {});
      for (final PricePoint p in points) {
        series[p.date.toIso8601String().substring(0, 10)] = p.close;
      }
      print('${d.decade} · $symbol : ${points.length} cours');
    }

    final start = d.steps.first['buy'] ?? d.steps.first['from']!;
    final json = {
      'decade': d.decade,
      'title':
          '1 000 \$ en ${start.substring(0, 4)}, avec une connaissance '
          'parfaite du futur',
      'currency': 'USD',
      'initialCapital': 1000,
      'source':
          'Twelve Data — cours de clôture quotidiens, ajustés des divisions '
          'd’actions (splits) survenues depuis.',
      'generatedAt': DateTime.now().toIso8601String().substring(0, 10),
      'steps': [
        for (final step in d.steps)
          {
            for (final e in step.entries) e.key: frenchSpaces(e.value),
            if (step['kind'] == 'asset') 'maxInvest': maxInvestFor(step),
          },
      ],
      'prices': {
        for (final e in prices.entries)
          e.key: [
            for (final day in e.value.keys.toList()..sort())
              [day, e.value[day]],
          ],
      },
    };

    final file = File('assets/scenarios/foresight/foresight_${d.decade}s.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert(json));
    print('Écrit : ${file.path}');
  }
}
