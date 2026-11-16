// ignore_for_file: avoid_print — script en ligne de commande, print est voulu.

// Vérifie en vrai que chaque actif du catalogue répond chez Twelve Data.
//
// Usage (depuis la racine du projet) :
//   dart run tool/check_api.dart          → tout le catalogue
//   dart run tool/check_api.dart AAPL     → un seul symbole
//
// Ce n'est pas un test automatique : il consomme des requêtes du quota
// (1 par actif) et attend 8 secondes entre deux appels (limite : 8/minute).

import 'dart:convert';
import 'dart:io';

import 'package:shares_knowledge/data/api/api_exceptions.dart';
import 'package:shares_knowledge/data/api/twelve_data_api.dart';
import 'package:shares_knowledge/models/asset.dart';

Future<void> main(List<String> args) async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  final api = TwelveDataApi(apiKey: env['TWELVE_DATA_KEY'] as String);

  final symbols = args.isNotEmpty
      ? args
      : parseAssetCatalog(
          File('assets/data/assets_catalog.json').readAsStringSync(),
        ).map((a) => a.symbol).toList();

  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 10));

  for (final (i, symbol) in symbols.indexed) {
    if (i > 0) await Future<void>.delayed(const Duration(seconds: 8));
    try {
      final points = await api.fetchDailySeries(symbol, start: start, end: end);
      final last = points.first; // l'API renvoie le plus récent en premier
      print(
        'OK   $symbol : ${points.length} cours, dernier '
        '${last.date.toIso8601String().substring(0, 10)} = ${last.close}',
      );
    } on ApiException catch (e) {
      print('ERR  $symbol : ${e.message}');
    }
  }
}
