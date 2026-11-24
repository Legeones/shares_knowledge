import '../price_point.dart';

enum NewsCategory {
  politique('Politique'),
  economie('Économie'),
  banqueCentrale('Banque centrale'),
  entreprise('Entreprise'),
  crypto('Crypto'),
  geopolitique('Géopolitique'),
  sante('Santé');

  final String label;
  const NewsCategory(this.label);
}

/// Une actualité datée du fil Past Trader.
class NewsItem {
  final DateTime date;
  final NewsCategory category;

  /// Majeure : la lecture automatique se met en pause (« flash info »).
  final bool major;
  final String title;
  final String body;

  /// Actifs concernés (affichés aussi sur la fiche de l'actif).
  final List<String> symbols;

  const NewsItem({
    required this.date,
    required this.category,
    required this.major,
    required this.title,
    required this.body,
    required this.symbols,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    date: dateOnly(DateTime.parse(json['date'] as String)),
    category: NewsCategory.values.byName(json['category'] as String),
    major: json['major'] as bool? ?? false,
    title: json['title'] as String,
    body: json['body'] as String,
    symbols: [for (final s in json['symbols'] as List<dynamic>) s as String],
  );
}
