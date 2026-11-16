import '../price_point.dart';

/// Le récit d'une étape, raconté au moment d'y entrer et d'en sortir.
class ForesightChapter {
  final String context; // ce qui se passe dans le monde
  final String whyEnter; // pourquoi acheter (ou attendre) maintenant
  final String whyLeave; // pourquoi vendre (ou reprendre) à la fin
  final String lessonTitle;
  final String lesson;

  const ForesightChapter({
    required this.context,
    required this.whyEnter,
    required this.whyLeave,
    required this.lessonTitle,
    required this.lesson,
  });

  factory ForesightChapter.fromJson(Map<String, dynamic> json) =>
      ForesightChapter(
        context: json['context'] as String,
        whyEnter: json['whyEnter'] as String,
        whyLeave: json['whyLeave'] as String,
        lessonTitle: json['lessonTitle'] as String,
        lesson: json['lesson'] as String,
      );
}

/// Une étape du parcours : un actif détenu, ou une attente en cash.
sealed class ForesightStep {
  /// Résumé en une phrase.
  final String story;
  final ForesightChapter chapter;
  const ForesightStep(this.story, this.chapter);

  DateTime get start;
  DateTime get end;
}

class AssetStep extends ForesightStep {
  final String symbol;
  final String name;
  final DateTime buy;
  final DateTime sell;

  /// Cours de l'actif autour de l'étape, du plus ancien au plus récent.
  final List<PricePoint> prices;

  /// Montant maximal réinvesti à l'achat (null : tout le capital).
  final double? maxInvest;

  const AssetStep({
    required this.symbol,
    required this.name,
    required this.buy,
    required this.sell,
    required this.prices,
    this.maxInvest,
    required String story,
    required ForesightChapter chapter,
  }) : super(story, chapter);

  @override
  DateTime get start => buy;
  @override
  DateTime get end => sell;

  int get holdingDays => sell.difference(buy).inDays;
}

class CashStep extends ForesightStep {
  final DateTime from;
  final DateTime to;

  const CashStep({
    required this.from,
    required this.to,
    required String story,
    required ForesightChapter chapter,
  }) : super(story, chapter);

  @override
  DateTime get start => from;
  @override
  DateTime get end => to;
}

/// Un parcours complet (une décennie), lu depuis assets/scenarios/foresight/.
class ForesightScenario {
  /// Première année de la décennie : 1970, 1980…
  final int decade;
  final String title;
  final String currency;
  final double initialCapital;
  final String source;
  final List<ForesightStep> steps;

  const ForesightScenario({
    required this.decade,
    required this.title,
    required this.currency,
    required this.initialCapital,
    required this.source,
    required this.steps,
  });

  /// « Années 1970 ».
  String get decadeLabel => 'Années $decade';

  DateTime get start => steps.first.start;
  DateTime get end => steps.last.end;
  List<AssetStep> get assetSteps => steps.whereType<AssetStep>().toList();

  factory ForesightScenario.fromJson(Map<String, dynamic> json) {
    final prices = json['prices'] as Map<String, dynamic>;
    DateTime day(Object? s) => dateOnly(DateTime.parse(s as String));

    // Chaque cours est stocké sous la forme ["2021-01-04", 4.3125].
    List<PricePoint> seriesOf(String symbol) => [
      for (final p in prices[symbol] as List<dynamic>)
        PricePoint(
          date: day((p as List<dynamic>)[0]),
          close: (p[1] as num).toDouble(),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return ForesightScenario(
      decade: json['decade'] as int,
      title: json['title'] as String,
      currency: json['currency'] as String,
      initialCapital: (json['initialCapital'] as num).toDouble(),
      source: json['source'] as String,
      steps: [
        for (final s in json['steps'] as List<dynamic>)
          switch ((s as Map<String, dynamic>)['kind']) {
            'asset' => AssetStep(
              symbol: s['symbol'] as String,
              name: s['name'] as String,
              buy: day(s['buy']),
              sell: day(s['sell']),
              prices: seriesOf(s['symbol'] as String),
              maxInvest: (s['maxInvest'] as num?)?.toDouble(),
              story: s['story'] as String,
              chapter: ForesightChapter.fromJson(s),
            ),
            'cash' => CashStep(
              from: day(s['from']),
              to: day(s['to']),
              story: s['story'] as String,
              chapter: ForesightChapter.fromJson(s),
            ),
            final kind => throw FormatException('Étape inconnue : $kind'),
          },
      ],
    );
  }
}

/// Tous les parcours, de la décennie la plus ancienne à la plus récente.
class ForesightCatalog {
  final List<ForesightScenario> scenarios;

  ForesightCatalog(List<ForesightScenario> all)
    : scenarios = [...all]..sort((a, b) => a.decade.compareTo(b.decade));

  List<int> get decades => [for (final s in scenarios) s.decade];

  ForesightScenario byDecade(int decade) =>
      scenarios.firstWhere((s) => s.decade == decade);
}
