import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/returns.dart';

void main() {
  group('gain', () {
    test('positif quand la valeur finale dépasse le montant investi', () {
      expect(gain(invested: 1000, finalValue: 1250), 250);
    });

    test('négatif en cas de perte', () {
      expect(gain(invested: 1000, finalValue: 700), -300);
    });

    test('perte totale', () {
      expect(gain(invested: 1000, finalValue: 0), -1000);
    });
  });

  group('performance', () {
    test('+25 % quand 1000 devient 1250', () {
      expect(performance(invested: 1000, finalValue: 1250), 0.25);
    });

    test('-100 % en cas de perte totale', () {
      expect(performance(invested: 1000, finalValue: 0), -1);
    });

    test('0 % quand rien ne bouge', () {
      expect(performance(invested: 500, finalValue: 500), 0);
    });

    test('refuse un montant investi nul (division par zéro)', () {
      expect(
        () => performance(invested: 0, finalValue: 100),
        throwsArgumentError,
      );
    });
  });

  group('compoundValue', () {
    test('1000 à 10 % pendant 2 ans donne 1210 (et non 1200)', () {
      // 1000 → 1100 → 1210 : la 2e année, les 100 de gain rapportent aussi.
      expect(
        compoundValue(capital: 1000, annualRate: 0.10, years: 2),
        closeTo(1210, 1e-9),
      );
    });

    test('0 an : le capital ne change pas', () {
      expect(compoundValue(capital: 1000, annualRate: 0.05, years: 0), 1000);
    });

    test('taux négatif : le capital diminue', () {
      expect(
        compoundValue(capital: 1000, annualRate: -0.10, years: 1),
        closeTo(900, 1e-9),
      );
    });

    test('refuse une durée négative', () {
      expect(
        () => compoundValue(capital: 1000, annualRate: 0.05, years: -1),
        throwsArgumentError,
      );
    });

    test('refuse un taux de -100 % ou moins', () {
      expect(
        () => compoundValue(capital: 1000, annualRate: -1, years: 3),
        throwsArgumentError,
      );
    });
  });

  group('simpleValue', () {
    test('1000 à 10 % pendant 2 ans sans réinvestissement : 1200', () {
      expect(
        simpleValue(capital: 1000, annualRate: 0.10, years: 2),
        closeTo(1200, 1e-9),
      );
    });

    test('refuse une durée négative', () {
      expect(
        () => simpleValue(capital: 1000, annualRate: 0.1, years: -1),
        throwsArgumentError,
      );
    });
  });

  group('growthTable', () {
    final table = growthTable(capital: 1000, annualRate: 0.10, years: 3);

    test('une ligne par année, de 0 à la durée', () {
      expect(table.map((r) => r.year), [0, 1, 2, 3]);
    });

    test('identiques la 1re année, puis le composé prend l’avantage', () {
      expect(table[0].compound, table[0].simple); // 1000
      expect(table[1].compound, closeTo(table[1].simple, 1e-9)); // 1100
      expect(table[2].compound, greaterThan(table[2].simple)); // 1210 > 1200
      expect(table[3].compound, closeTo(1331, 1e-9));
    });

    test('taux nul : rien ne bouge', () {
      final flat = growthTable(capital: 500, annualRate: 0, years: 5);
      expect(flat.every((r) => r.compound == 500 && r.simple == 500), isTrue);
    });
  });

  group('doublingYears', () {
    test('à 7 % par an : environ 10 ans', () {
      expect(doublingYears(0.07), closeTo(10.24, 0.01));
    });

    test('à 100 % par an : exactement 1 an', () {
      expect(doublingYears(1), closeTo(1, 1e-9));
    });

    test('taux nul ou négatif : ne double jamais', () {
      expect(doublingYears(0), isNull);
      expect(doublingYears(-0.05), isNull);
    });
  });
}
