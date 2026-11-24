import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/learn/dca.dart';

void main() {
  test('en une fois : toutes les parts au premier prix', () {
    final r = lumpSum([100, 50, 200], 1000);
    expect(r.units, 10);
    expect(r.averageCost, 100);
    expect(r.values, [1000, 500, 2000]);
  });

  test('chaque mois : plus de parts quand le prix est bas', () {
    // 100 € à 100 € → 1 part ; 100 € à 50 € → 2 parts.
    final r = regularInvestment([100, 50, 100], 100, 2);
    expect(r.invested, 200);
    expect(r.units, closeTo(3, 1e-9));
    // Prix moyen d'achat 66,67 € : sous le prix moyen du marché (75 €).
    expect(r.averageCost, closeTo(200 / 3, 1e-9));
    expect(r.finalValue, closeTo(300, 1e-9));
  });

  test('l’argent pas encore versé compte dans la valeur', () {
    final r = regularInvestment([100, 100, 100], 100, 3);
    expect(r.values, [300, 300, 300]); // prix stable : rien ne bouge
  });

  test('après un krach puis une reprise, le DCA rapporte plus', () {
    const prices = <double>[100, 60, 60, 100];
    expect(
      regularInvestment(prices, 100, 3).finalValue,
      greaterThan(lumpSum(prices, 300).finalValue),
    );
  });

  test('en hausse continue, tout placer d’un coup rapporte plus', () {
    const prices = <double>[100, 110, 120, 130];
    expect(
      lumpSum(prices, 300).finalValue,
      greaterThan(regularInvestment(prices, 100, 3).finalValue),
    );
  });

  test('prix impossibles refusés', () {
    expect(() => lumpSum([], 100), throwsArgumentError);
    expect(() => regularInvestment([100, 0], 10, 2), throwsArgumentError);
    expect(() => regularInvestment([100], 10, 2), throwsArgumentError);
  });
}
