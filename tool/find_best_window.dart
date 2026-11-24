// ignore_for_file: avoid_print — script en ligne de commande.

// Aide à construire un parcours Perfect Foresight : pour un actif et une
// fenêtre, trouve le meilleur couple achat → vente (le plus grand
// multiplicateur avec l'achat avant la vente).
//
// Usage :
//   dart run tool/find_best_window.dart AAPL:2003-01-01:2007-12-31 ...
//
// Consomme 1 requête Twelve Data par fenêtre, espacées de 8 s.

import 'dart:convert';
import 'dart:io';

import 'package:shares_knowledge/data/api/twelve_data_api.dart';

Future<void> main(List<String> args) async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  final api = TwelveDataApi(apiKey: env['TWELVE_DATA_KEY'] as String);

  for (final (i, arg) in args.indexed) {
    if (i > 0) await Future<void>.delayed(const Duration(seconds: 8));
    final [symbol, from, to] = arg.split(':');
    try {
      final points = await api.fetchDailySeries(
        symbol,
        start: DateTime.parse(from),
        end: DateTime.parse(to),
      );
      points.sort((a, b) => a.date.compareTo(b.date));
      String day(DateTime d) => d.toIso8601String().substring(0, 10);

      // Meilleur couple : on garde le plus bas vu jusqu'ici.
      var low = points.first;
      var best = (points.first, points.first, 1.0);
      for (final p in points) {
        if (p.close < low.close) low = p;
        final m = p.close / low.close;
        if (m > best.$3) best = (low, p, m);
      }
      print(
        '$symbol [$from → $to] ${points.length} cours · '
        'premier ${day(points.first.date)}=${points.first.close} · '
        'dernier ${day(points.last.date)}=${points.last.close} · '
        'MEILLEUR achat ${day(best.$1.date)}=${best.$1.close} '
        'vente ${day(best.$2.date)}=${best.$2.close} ×${best.$3.toStringAsFixed(2)}',
      );
    } on Object catch (e) {
      print('$symbol [$from → $to] ERREUR $e');
    }
  }
}
