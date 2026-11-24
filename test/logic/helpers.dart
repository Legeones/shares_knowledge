import 'package:shares_knowledge/logic/price_series.dart';
import 'package:shares_knowledge/models/price_point.dart';

/// Raccourci pour écrire une date dans les tests : d(2024, 1, 5).
DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

/// Construit une série à partir de couples (date, prix).
PriceSeries series(Map<DateTime, double> prices) => PriceSeries([
  for (final e in prices.entries) PricePoint(date: e.key, close: e.value),
]);

/// Une semaine de bourse type : du lundi 1er au vendredi 5 janvier 2024,
/// puis le lundi 8. Les 6 et 7 (week-end) n'ont pas de cotation.
final weekSeries = series({
  d(2024, 1, 1): 100,
  d(2024, 1, 2): 110,
  d(2024, 1, 3): 90,
  d(2024, 1, 4): 95,
  d(2024, 1, 5): 120,
  d(2024, 1, 8): 130,
});
