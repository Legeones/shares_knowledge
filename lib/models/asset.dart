import 'dart:convert';

/// Catégorie d'un actif. Un enum limite les valeurs possibles :
/// impossible d'écrire par erreur « actoin ».
enum AssetType { stock, etf, crypto }

/// Un actif que l'utilisateur peut choisir (action, ETF ou crypto).
class Asset {
  final String symbol; // ex. "AAPL", "BTC/USD"
  final String name; // ex. "Apple"
  final String currency; // ex. "USD"
  final AssetType type;
  final String description; // une phrase pour un débutant

  const Asset({
    required this.symbol,
    required this.name,
    required this.currency,
    required this.type,
    this.description = '',
  });

  /// {"symbol": "AAPL", "name": "Apple", "currency": "USD", "type": "stock", ...}
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      // "stock" devient AssetType.stock (erreur si le texte ne correspond à aucune valeur)
      type: AssetType.values.byName(json['type'] as String),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'currency': currency,
    'type': type.name, // AssetType.stock → "stock"
    'description': description,
  };
}

/// Lit le catalogue d'actifs (contenu du fichier assets/data/assets_catalog.json).
List<Asset> parseAssetCatalog(String jsonText) {
  final list = jsonDecode(jsonText) as List<dynamic>;
  return [
    for (final item in list) Asset.fromJson(item as Map<String, dynamic>),
  ];
}
