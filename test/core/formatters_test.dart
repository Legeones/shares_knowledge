import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/core/formatters.dart';

/// intl utilise des espaces insécables (fines) comme séparateur de milliers ;
/// on les remplace par des espaces normaux pour écrire les tests simplement.
String plain(String s) => s.replaceAll(RegExp(r'[  ]'), ' ');

void main() {
  test('montants en français', () {
    expect(plain(formatMoney(1234.5, 'USD')), r'1 234,50 $');
    expect(plain(formatMoney(1234.5, 'EUR')), '1 234,50 €');
  });

  test('montants signés : le signe ne dépend pas que de la couleur', () {
    expect(plain(formatSignedMoney(250, 'USD')), r'+250,00 $');
    expect(plain(formatSignedMoney(-300, 'USD')), r'−300,00 $');
    expect(plain(formatSignedMoney(0, 'USD')), r'0,00 $');
    // Erreur d'arrondi minuscule : pas de signe.
    expect(plain(formatSignedMoney(1e-9, 'USD')), r'0,00 $');
    expect(plain(formatSignedMoney(-1e-9, 'USD')), r'0,00 $');
  });

  test('pourcentages', () {
    expect(plain(formatPercent(0.2534)), '+25,34 %');
    expect(plain(formatPercent(-0.1)), '−10,00 %');
    expect(plain(formatPercent(0)), '0,00 %');
    expect(plain(formatPercent(1e-12)), '0,00 %');
    expect(plain(formatPercent(0.3, signed: false)), '30,00 %');
  });

  test('quantités sans zéros inutiles', () {
    expect(formatUnits(10), '10');
    expect(formatUnits(10.5), '10,5');
    expect(formatUnits(0.123456), '0,1235');
  });

  test('dates jj/mm/aaaa', () {
    expect(formatDate(DateTime.utc(2024, 1, 5)), '05/01/2024');
  });
}
