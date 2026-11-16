import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/form_validators.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('parseAmount', () {
    test('accepte le point, la virgule et les espaces', () {
      expect(parseAmount('1000'), 1000);
      expect(parseAmount('1000.5'), 1000.5);
      expect(parseAmount('1000,5'), 1000.5);
      expect(parseAmount('1 000,50'), 1000.5);
    });

    test('renvoie null si ce n’est pas un nombre', () {
      expect(parseAmount('abc'), isNull);
      expect(parseAmount(''), isNull);
      expect(parseAmount(null), isNull);
      expect(parseAmount('12,3,4'), isNull);
    });
  });

  group('validateAmount', () {
    test('montant correct : aucune erreur', () {
      expect(validateAmount('1000'), isNull);
      expect(validateAmount('0,01'), isNull);
    });

    test('champ vide', () {
      expect(validateAmount(''), 'Indique un montant.');
      expect(validateAmount('   '), 'Indique un montant.');
    });

    test('texte non numérique', () {
      expect(validateAmount('mille'), 'Ce n’est pas un nombre valide.');
    });

    test('zéro ou négatif', () {
      expect(validateAmount('0'), 'Le montant doit être supérieur à 0.');
      expect(validateAmount('-50'), 'Le montant doit être supérieur à 0.');
    });

    test('trop grand', () {
      expect(validateAmount('10000001'), isNotNull);
      expect(validateAmount('10000000'), isNull); // limite incluse
    });
  });

  group('dates', () {
    final today = d(2024, 6, 15);

    test('début avant la fin : correct', () {
      expect(validateStartDate(d(2020, 1, 1), end: d(2024, 1, 1)), isNull);
    });

    test('début après ou égal à la fin', () {
      expect(validateStartDate(d(2024, 1, 1), end: d(2024, 1, 1)), isNotNull);
      expect(validateStartDate(d(2024, 2, 1), end: d(2024, 1, 1)), isNotNull);
    });

    test('début avant 1990', () {
      expect(validateStartDate(d(1989, 12, 31), end: d(2024, 1, 1)), isNotNull);
    });

    test('dates manquantes', () {
      expect(validateStartDate(null, end: d(2024, 1, 1)), isNotNull);
      expect(validateEndDate(null, today: today), isNotNull);
    });

    test('fin au plus tard hier', () {
      expect(validateEndDate(d(2024, 6, 14), today: today), isNull);
      expect(validateEndDate(d(2024, 6, 15), today: today), isNotNull);
      expect(validateEndDate(d(2024, 7, 1), today: today), isNotNull);
    });
  });
}
