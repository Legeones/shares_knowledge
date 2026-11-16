import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/learn/diversification.dart';

void main() {
  test('combinaisons : 4 éléments pris 2 à 2 = 6 paniers', () {
    final c = combinations([1, 2, 3, 4], 2);
    expect(c, hasLength(6));
    expect(c, contains(equals([2, 4])));
  });

  test('panier : somme partagée à parts égales, sans rééquilibrage', () {
    final path = basketPath([
      [1.0], // double
      [-0.5], // moitié
    ], capital: 100);
    expect(path, [100, 125]); // 50 × 2 + 50 × 0,5
  });

  test('une entreprise seule : de la faillite au jackpot', () {
    final r = basketRange(1);
    expect(r.count, companies.length);
    expect(r.worst.last, closeTo(0, 1e-9));
    expect(r.best.last, greaterThan(300)); // plus que quadruplé
    expect(r.worstDrawdown, closeTo(1, 1e-9));
  });

  test('plus d’entreprises : l’écart se réduit, la moyenne ne bouge pas', () {
    final ranges = [for (var n = 1; n <= companies.length; n++) basketRange(n)];
    for (var i = 1; i < ranges.length; i++) {
      final spread = ranges[i].best.last - ranges[i].worst.last;
      final before = ranges[i - 1].best.last - ranges[i - 1].worst.last;
      expect(spread, lessThan(before));
      expect(ranges[i].worstDrawdown, lessThan(ranges[i - 1].worstDrawdown));
      expect(ranges[i].averageFinal, closeTo(ranges[0].averageFinal, 1e-6));
    }
    expect(ranges.last.count, 1); // un seul panier : toutes
  });

  test('taille de panier impossible refusée', () {
    expect(() => basketRange(0), throwsArgumentError);
    expect(() => basketRange(companies.length + 1), throwsArgumentError);
  });
}
