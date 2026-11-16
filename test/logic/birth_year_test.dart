import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/birth_year.dart';

void main() {
  group('validateBirthYear', () {
    String? v(String text) => validateBirthYear(text, currentYear: 2026);

    test('vide : permis (facultatif)', () {
      expect(v(''), isNull);
      expect(v('  '), isNull);
    });
    test('année plausible : acceptée', () => expect(v('1985'), isNull));
    test('pas un nombre : refusé', () => expect(v('abc'), isNotNull));
    test('trop ancienne ou trop récente : refusée', () {
      expect(v('1900'), isNotNull);
      expect(v('2020'), isNotNull);
    });
  });

  test('parseBirthYear : null si vide', () {
    expect(parseBirthYear(''), isNull);
    expect(parseBirthYear(' 1985 '), 1985);
  });

  group('suggestedDecade : la décennie de tes 25 ans', () {
    const decades = [1970, 1980, 1990, 2000, 2010, 2020];

    test(
      'né en 1985 → 2010',
      () => expect(suggestedDecade(1985, decades), 2010),
    );
    test(
      'né en 1964 → 1980',
      () => expect(suggestedDecade(1964, decades), 1980),
    );
    test('trop tôt → la première', () {
      expect(suggestedDecade(1930, decades), 1970);
    });
    test('trop tard → la dernière', () {
      expect(suggestedDecade(2005, decades), 2020);
    });
    test('sans année → la plus récente', () {
      expect(suggestedDecade(null, decades), 2020);
    });
  });
}
