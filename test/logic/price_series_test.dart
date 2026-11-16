import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/price_series.dart';
import 'package:shares_knowledge/models/price_point.dart';

import 'helpers.dart';

void main() {
  test('trie les cours reçus dans le désordre', () {
    final s = PriceSeries([
      PricePoint(date: d(2024, 1, 3), close: 3),
      PricePoint(date: d(2024, 1, 1), close: 1),
      PricePoint(date: d(2024, 1, 2), close: 2),
    ]);
    expect([for (final p in s.points) p.close], [1, 2, 3]);
  });

  test('un samedi, on achète le lundi suivant', () {
    expect(weekSeries.firstOnOrAfter(d(2024, 1, 6))!.date, d(2024, 1, 8));
  });

  test('un dimanche, la valeur est celle du vendredi', () {
    final p = weekSeries.lastOnOrBefore(d(2024, 1, 7))!;
    expect(p.date, d(2024, 1, 5));
    expect(p.close, 120);
  });

  test('pas de cours avant le début ni après la fin : null, jamais 0', () {
    expect(weekSeries.lastOnOrBefore(d(2023, 12, 31)), isNull);
    expect(weekSeries.firstOnOrAfter(d(2024, 1, 9)), isNull);
  });

  test('distingue jour de cotation et marché fermé', () {
    expect(weekSeries.isMarketDay(d(2024, 1, 5)), isTrue);
    expect(weekSeries.isMarketDay(d(2024, 1, 6)), isFalse);
  });

  test('ignore l’heure dans les dates', () {
    final afternoon = DateTime.utc(2024, 1, 2, 15, 30);
    expect(weekSeries.isMarketDay(afternoon), isTrue);
  });

  test('between inclut les deux bornes', () {
    final pts = weekSeries.between(d(2024, 1, 2), d(2024, 1, 4));
    expect([for (final p in pts) p.close], [110, 90, 95]);
  });
}
