import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/chart_data.dart';
import 'package:shares_knowledge/models/simulation.dart';

import '../helpers.dart';

/// Vendredi 5 (valeur 1200), lundi 8 (1300) : un week-end au milieu.
final history = [
  ValuePoint(date: d(2024, 1, 5), price: 120, value: 1200, invested: 1000),
  ValuePoint(date: d(2024, 1, 8), price: 130, value: 1300, invested: 1000),
];

void main() {
  group('chartPoints', () {
    test('x = jours écoulés : le week-end laisse un écart de 3 jours', () {
      final pts = chartPoints(history, ChartMode.value);
      expect(pts.map((p) => p.x), [0, 3]);
    });

    test('mode valeur ou mode cours', () {
      expect(chartPoints(history, ChartMode.value).map((p) => p.y), [
        1200,
        1300,
      ]);
      expect(chartPoints(history, ChartMode.price).map((p) => p.y), [120, 130]);
    });

    test('historique vide : aucun point', () {
      expect(chartPoints([], ChartMode.value), isEmpty);
    });
  });

  group('verticalBounds', () {
    final pts = chartPoints(history, ChartMode.value);

    test('marge de 5 % autour des valeurs', () {
      final b = verticalBounds(pts);
      expect(b.minY, closeTo(1195, 1e-9)); // 1200 − 5 % de 100
      expect(b.maxY, closeTo(1305, 1e-9));
    });

    test('inclut la ligne du montant investi', () {
      final b = verticalBounds(pts, alsoInclude: 1000);
      expect(b.minY, lessThan(1000));
    });

    test('jamais sous zéro', () {
      final b = verticalBounds([
        ChartPoint(0, 0, d(2024, 1, 1)),
        ChartPoint(1, 100, d(2024, 1, 2)),
      ]);
      expect(b.minY, 0);
    });

    test('courbe plate : une hauteur est quand même donnée', () {
      final b = verticalBounds([
        ChartPoint(0, 50, d(2024, 1, 1)),
        ChartPoint(1, 50, d(2024, 1, 2)),
      ]);
      expect(b.maxY, greaterThan(b.minY));
    });
  });

  test('environ 4 dates sous l’axe', () {
    final pts = [
      ChartPoint(0, 1, d(2024, 1, 1)),
      ChartPoint(400, 1, d(2025, 2, 4)),
    ];
    expect(bottomLabelInterval(pts), 100);
  });
}
