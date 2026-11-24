import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/drawdown.dart';
import 'package:shares_knowledge/logic/risk.dart';

void main() {
  group('volatilité', () {
    test('rendements d’une période à l’autre', () {
      final r = periodReturns([100, 110, 99]);
      expect(r[0], closeTo(0.10, 1e-9));
      expect(r[1], closeTo(-0.10, 1e-9));
    });

    test('une progression parfaitement régulière a une volatilité nulle', () {
      expect(volatility([100, 110, 121, 133.1]), closeTo(0, 1e-9));
    });

    test('même départ, même arrivée, quelle que soit l’agitation', () {
      for (final amplitude in [0.0, 0.1, 0.3]) {
        final path = pathWithVolatility(
          start: 1000,
          end: 1500,
          amplitude: amplitude,
        );
        expect(path, hasLength(11)); // 10 ans
        expect(path.first, closeTo(1000, 1e-9));
        expect(path.last, closeTo(1500, 1e-9));
      }
    });

    test('plus d’agitation : plus de volatilité, de plus fortes baisses', () {
      final calm = pathWithVolatility(start: 1000, end: 1500, amplitude: 0);
      final wild = pathWithVolatility(start: 1000, end: 1500, amplitude: 0.3);
      expect(volatility(wild), greaterThan(volatility(calm)));
      expect(worstReturn(wild), lessThan(0)); // au moins une année de perte
      expect(worstReturn(calm), greaterThan(0)); // que des années de gain
      expect(maxDrawdown(wild).depth, greaterThan(maxDrawdown(calm).depth));
    });
  });

  group('baisse maximale', () {
    test('après −50 %, il faut +100 % pour revenir', () {
      expect(recoveryGain(0.5), closeTo(1.0, 1e-9));
      expect(recoveryGain(0.2), closeTo(0.25, 1e-9));
      expect(recoveryGain(0), 0);
    });

    test('perte impossible : refusée', () {
      expect(() => recoveryGain(1), throwsArgumentError);
      expect(() => recoveryGain(-0.1), throwsArgumentError);
    });

    test('années pour revenir, à 7 % par an', () {
      // −50 % puis +7 %/an : doubler prend environ 10,2 ans.
      expect(yearsToRecover(0.5, 0.07), closeTo(10.24, 0.01));
      expect(yearsToRecover(0.5, 0), isNull);
    });
  });
}
