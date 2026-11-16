import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';

import '../helpers.dart';

const testAsset = Asset(
  symbol: 'TEST',
  name: 'Action test',
  currency: 'USD',
  type: AssetType.stock,
);

SimulationParams params(double amount, DateTime start, DateTime end) =>
    SimulationParams(asset: testAsset, amount: amount, start: start, end: end);

void main() {
  test('1000 investis à 100, revendus à 120 : +200 soit +20 %', () {
    final r = simulateLumpSum(
      params(1000, d(2024, 1, 1), d(2024, 1, 5)),
      weekSeries,
    );
    expect(r.units, 10);
    expect(r.totalInvested, 1000);
    expect(r.finalValue, 1200);
    expect(r.gain, 200);
    expect(r.performance, closeTo(0.20, 1e-9));
    expect(r.periodWasAdjusted, isFalse);
  });

  test('l’historique contient une valeur par jour de cotation', () {
    final r = simulateLumpSum(
      params(1000, d(2024, 1, 1), d(2024, 1, 5)),
      weekSeries,
    );
    expect([for (final v in r.history) v.value], [1000, 1100, 900, 950, 1200]);
  });

  test('calcule la baisse maximale du portefeuille', () {
    final r = simulateLumpSum(
      params(1000, d(2024, 1, 1), d(2024, 1, 5)),
      weekSeries,
    );
    // Sommet 1100 le 2, creux 900 le 3 : -18,18 %
    expect(r.maxDrawdown, closeTo(200 / 1100, 1e-9));
    // Positions dans l'historique, pour le graphique.
    expect(r.history[r.drawdown.peakIndex].date, d(2024, 1, 2));
    expect(r.history[r.drawdown.troughIndex].date, d(2024, 1, 3));
  });

  test('début un week-end : achat le lundi et période signalée', () {
    final r = simulateLumpSum(
      params(1300, d(2024, 1, 6), d(2024, 1, 8)),
      weekSeries,
    );
    expect(r.actualStart, d(2024, 1, 8));
    expect(r.units, 10); // 1300 / 130
    expect(r.periodWasAdjusted, isTrue);
  });

  test('fin un week-end : valeur du vendredi', () {
    final r = simulateLumpSum(
      params(1000, d(2024, 1, 1), d(2024, 1, 7)),
      weekSeries,
    );
    expect(r.actualEnd, d(2024, 1, 5));
    expect(r.finalValue, 1200);
  });

  test('quantité fractionnaire autorisée', () {
    final r = simulateLumpSum(
      params(50, d(2024, 1, 1), d(2024, 1, 2)),
      weekSeries,
    );
    expect(r.units, 0.5);
  });

  group('erreurs expliquées à l’utilisateur', () {
    test('montant nul ou négatif', () {
      for (final amount in [0.0, -10.0]) {
        expect(
          () => simulateLumpSum(
            params(amount, d(2024, 1, 1), d(2024, 1, 5)),
            weekSeries,
          ),
          throwsA(isA<SimulationException>()),
        );
      }
    });

    test('date de début après la date de fin', () {
      expect(
        () => simulateLumpSum(
          params(1000, d(2024, 1, 5), d(2024, 1, 1)),
          weekSeries,
        ),
        throwsA(isA<SimulationException>()),
      );
    });

    test('période entièrement hors de l’historique', () {
      expect(
        () => simulateLumpSum(
          params(1000, d(2020, 1, 1), d(2020, 6, 1)),
          weekSeries,
        ),
        throwsA(isA<SimulationException>()),
      );
    });

    test('période sans aucune cotation (un week-end seul)', () {
      expect(
        () => simulateLumpSum(
          params(1000, d(2024, 1, 6), d(2024, 1, 7)),
          weekSeries,
        ),
        throwsA(isA<SimulationException>()),
      );
    });

    test('historique vide', () {
      expect(
        () => simulateLumpSum(
          params(1000, d(2024, 1, 1), d(2024, 1, 5)),
          series({}),
        ),
        throwsA(isA<SimulationException>()),
      );
    });
  });
}
