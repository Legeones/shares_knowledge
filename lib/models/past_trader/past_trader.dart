import '../asset.dart';
import '../price_point.dart';

/// Un actif proposé dans la partie, avec tout son historique de cours.
class TraderAsset {
  final String symbol;
  final String name;
  final AssetType type;
  final String description;

  /// Du plus ancien au plus récent. Le jeu n'en montre que la partie passée.
  final List<PricePoint> prices;

  const TraderAsset({
    required this.symbol,
    required this.name,
    required this.type,
    required this.description,
    required this.prices,
  });

  factory TraderAsset.fromJson(Map<String, dynamic> json) => TraderAsset(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    type: AssetType.values.byName(json['type'] as String),
    description: json['description'] as String,
    prices: [
      for (final p in json['prices'] as List<dynamic>)
        PricePoint(
          date: DateTime.parse((p as List<dynamic>)[0] as String),
          close: (p[1] as num).toDouble(),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date)),
  );
}

/// Une partie Past Trader : période, capital et actifs disponibles.
/// Lue depuis assets/scenarios/past_trader_2018_2020.json.
class TraderGameData {
  final String id;
  final String title;
  final String intro;
  final DateTime start;
  final DateTime end;
  final DateTime historyFrom;
  final double initialCash;
  final String source;
  final List<TraderAsset> assets;

  const TraderGameData({
    required this.id,
    required this.title,
    required this.intro,
    required this.start,
    required this.end,
    required this.historyFrom,
    required this.initialCash,
    required this.source,
    required this.assets,
  });

  TraderAsset asset(String symbol) =>
      assets.firstWhere((a) => a.symbol == symbol);

  factory TraderGameData.fromJson(Map<String, dynamic> json) {
    DateTime day(String key) => dateOnly(DateTime.parse(json[key] as String));
    return TraderGameData(
      id: json['id'] as String,
      title: json['title'] as String,
      intro: json['intro'] as String,
      start: day('start'),
      end: day('end'),
      historyFrom: day('historyFrom'),
      initialCash: (json['initialCash'] as num).toDouble(),
      source: json['source'] as String,
      assets: [
        for (final a in json['assets'] as List<dynamic>)
          TraderAsset.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}
