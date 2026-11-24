// ignore_for_file: avoid_print — script en ligne de commande.

// Génère assets/scenarios/past_trader_news.json (sans appel réseau).
//
// Usage (depuis la racine du projet) :
//   dart run tool/build_past_trader_news.dart

import 'dart:convert';
import 'dart:io';

import 'past_trader_news.dart';
import 'text_utils.dart';

void main() {
  final items = [
    for (final n in news)
      {
        'date': n['date'],
        'category': n['category'],
        'major': n['major'] ?? false,
        'title': frenchSpaces(n['title']! as String),
        'body': frenchSpaces(n['body']! as String),
        'symbols': n['symbols'] ?? <String>[],
      },
  ]..sort((a, b) => (a['date']! as String).compareTo(b['date']! as String));

  final file = File('assets/scenarios/past_trader_news.json');
  file.writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({
      'source':
          'Événements réels, résumés à la main à partir de la presse de '
          'l’époque.',
      'items': items,
    }),
  );
  print('${items.length} actualités → ${file.path}');
}
