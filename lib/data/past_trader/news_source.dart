import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/past_trader/news.dart';

/// D'où viennent les actualités du jeu.
///
/// Aujourd'hui : un fichier embarqué, écrit à la main. Demain, une autre
/// implémentation pourra interroger une API d'actualités historiques : le
/// reste de l'application ne dépend que de cette interface.
abstract interface class NewsSource {
  Future<List<NewsItem>> load();
}

/// Actualités lues depuis assets/scenarios/past_trader_news.json.
class AssetNewsSource implements NewsSource {
  final String path;
  const AssetNewsSource([this.path = 'assets/scenarios/past_trader_news.json']);

  @override
  Future<List<NewsItem>> load() async =>
      parseNews(await rootBundle.loadString(path));
}

List<NewsItem> parseNews(String jsonText) {
  final json = jsonDecode(jsonText) as Map<String, dynamic>;
  return [
    for (final item in json['items'] as List<dynamic>)
      NewsItem.fromJson(item as Map<String, dynamic>),
  ];
}
