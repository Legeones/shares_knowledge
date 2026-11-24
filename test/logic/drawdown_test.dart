import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/drawdown.dart';

void main() {
  test('trouve la plus forte baisse entre un sommet et un creux', () {
    final d = maxDrawdown([100, 150, 90, 200, 180]);
    expect(d.depth, closeTo(0.40, 1e-9)); // 150 → 90
    expect(d.peakIndex, 1);
    expect(d.troughIndex, 2);
  });

  test('aucune baisse sur une hausse continue', () {
    final d = maxDrawdown([100, 110, 120, 130]);
    expect(d.depth, 0);
  });

  test('une seule valeur : aucune baisse', () {
    expect(maxDrawdown([42]).depth, 0);
  });

  test('baisse continue : du premier au dernier point', () {
    final d = maxDrawdown([100, 80, 50]);
    expect(d.depth, closeTo(0.50, 1e-9));
    expect(d.peakIndex, 0);
    expect(d.troughIndex, 2);
  });

  test('même performance finale, parcours différents', () {
    // Les deux finissent à 120, mais le second a fait peur en chemin.
    expect(maxDrawdown([100, 110, 120]).depth, 0);
    expect(maxDrawdown([100, 40, 120]).depth, closeTo(0.60, 1e-9));
  });

  test('perte totale : baisse de 100 %', () {
    expect(maxDrawdown([100, 0]).depth, 1);
  });

  test('liste vide refusée', () {
    expect(() => maxDrawdown([]), throwsArgumentError);
  });
}
