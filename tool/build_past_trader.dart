// ignore_for_file: avoid_print — script en ligne de commande.

// Génère assets/scenarios/past_trader_2018_2020.json à partir des vrais cours.
//
// Usage (depuis la racine du projet) :
//   dart run tool/build_past_trader.dart
//
// Consomme une requête Twelve Data par actif, espacées de 8 s (≈ 2 min).

import 'dart:convert';
import 'dart:io';

import 'package:shares_knowledge/data/api/twelve_data_api.dart';

import 'past_trader_assets.dart';
import 'text_utils.dart';

Future<void> main() async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  final api = TwelveDataApi(apiKey: env['TWELVE_DATA_KEY'] as String);
  final from = DateTime.parse(game['historyFrom']! as String);
  final to = DateTime.parse(game['end']! as String);

  final out = <Map<String, Object>>[];
  for (final (i, asset) in assets.indexed) {
    if (i > 0) await Future<void>.delayed(const Duration(seconds: 8));
    final points = await api.fetchDailySeries(
      asset['symbol']!,
      start: from,
      end: to,
    );
    points.sort((a, b) => a.date.compareTo(b.date));
    out.add({
      for (final e in asset.entries) e.key: frenchSpaces(e.value),
      'prices': [
        for (final p in points)
          // 6 chiffres significatifs suffisent et allègent le fichier.
          [
            p.date.toIso8601String().substring(0, 10),
            double.parse(p.close.toStringAsPrecision(6)),
          ],
      ],
    });
    print('${asset['symbol']} : ${points.length} cours');
  }

  final json = {
    for (final e in game.entries)
      e.key: e.value is String ? frenchSpaces(e.value as String) : e.value,
    'source':
        'Twelve Data — cours de clôture quotidiens, ajustés des divisions '
        'd’actions (splits) survenues depuis.',
    'generatedAt': DateTime.now().toIso8601String().substring(0, 10),
    'assets': out,
  };

  final file = File('assets/scenarios/past_trader_2018_2020.json');
  file.writeAsStringSync(jsonEncode(json));
  print('Écrit : ${file.path} (${file.lengthSync() ~/ 1024} Ko)');
}
