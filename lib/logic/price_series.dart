import '../models/price_point.dart';

/// Un historique de cours triés par date, avec des fonctions de recherche.
class PriceSeries {
  final List<PricePoint> points;

  /// Les points reçus sont copiés puis triés du plus ancien au plus récent :
  /// l'API Twelve Data, par exemple, les renvoie du plus récent au plus ancien.
  PriceSeries(List<PricePoint> points)
    : points = [...points]..sort((a, b) => a.date.compareTo(b.date));

  bool get isEmpty => points.isEmpty;
  DateTime get firstDate => points.first.date;
  DateTime get lastDate => points.last.date;

  /// Premier cours à la date donnée ou juste après (null s'il n'y en a pas).
  PricePoint? firstOnOrAfter(DateTime date) {
    final day = dateOnly(date);
    for (final p in points) {
      if (!p.date.isBefore(day)) return p;
    }
    return null;
  }

  /// Dernier cours à la date donnée ou juste avant (null s'il n'y en a pas).
  PricePoint? lastOnOrBefore(DateTime date) {
    final day = dateOnly(date);
    for (final p in points.reversed) {
      if (!p.date.isAfter(day)) return p;
    }
    return null;
  }

  /// Vrai si une cotation existe exactement ce jour-là.
  bool isMarketDay(DateTime date) {
    final day = dateOnly(date);
    return points.any((p) => p.date == day);
  }

  /// Les cours compris entre deux dates (incluses).
  List<PricePoint> between(DateTime start, DateTime end) {
    final from = dateOnly(start);
    final to = dateOnly(end);
    return points
        .where((p) => !p.date.isBefore(from) && !p.date.isAfter(to))
        .toList();
  }
}
