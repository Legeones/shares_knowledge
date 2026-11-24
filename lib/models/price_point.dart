/// Un cours de clôture à une date donnée.
class PricePoint {
  final DateTime date;
  final double close;

  PricePoint({required DateTime date, required this.close})
    : date = dateOnly(date);

  /// Construit un PricePoint à partir d'un élément JSON de Twelve Data :
  ///   {"datetime": "2024-01-05", "open": "...", "close": "185.92", ...}
  factory PricePoint.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Un cours doit être un objet JSON');
    }
    final datetime = json['datetime'];
    final close = json['close'];
    if (datetime is! String || close is! String) {
      throw const FormatException('Champs "datetime" ou "close" manquants');
    }
    return PricePoint(
      date: DateTime.parse(datetime), // lève FormatException si invalide
      close: double.parse(close), // idem
    );
  }

  /// L'inverse de fromJson : sert à stocker le cours dans le cache local.
  Map<String, dynamic> toJson() => {
    'datetime': date.toIso8601String().substring(0, 10),
    'close': close.toString(),
  };

  @override
  String toString() => 'PricePoint(${date.toIso8601String()}, $close)';
}

/// Retire l'heure d'une date : 2024-03-05 14:32 devient 2024-03-05 00:00 UTC.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
