import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/replay.dart';
import 'package:shares_knowledge/logic/returns.dart';
import 'package:shares_knowledge/logic/risk.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/logic/time_cursor.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';

import '../helpers.dart';

const testAsset = Asset(
  symbol: 'TEST',
  name: 'Action test',
  currency: 'USD',
  type: AssetType.stock,
);

/// Le 31 de chaque mois (ou le jour de bourse suivant), puis la fin.
final monthSeries = series({
  d(2024, 1, 31): 100,
  d(2024, 2, 29): 50, // février : le 31 devient le 29
  d(2024, 4, 1): 100, // dimanche 31 mars : on achète le lundi
  d(2024, 4, 15): 80,
});

final monthly = SimulationParams(
  asset: testAsset,
  amount: 100,
  start: d(2024, 1, 31),
  end: d(2024, 4, 15),
  mode: InvestMode.monthly,
);

void main() {
  group('versements mensuels', () {
    final r = simulateMonthly(monthly, monthSeries);

    test('100 par mois : plus de parts quand le cours est bas', () {
      expect(r.payments, 3);
      expect(r.totalInvested, 300);
      expect(r.units, closeTo(4, 1e-9)); // 1 + 2 + 1
      expect(r.averageCost, closeTo(75, 1e-9));
      expect(r.finalValue, closeTo(320, 1e-9));
      expect(r.performance, closeTo(20 / 300, 1e-9));
    });

    test('la somme versée grandit à chaque versement', () {
      expect([for (final p in r.history) p.invested], [100, 200, 300, 300]);
    });

    test('comparaison avec un placement le premier jour', () {
      expect(r.lumpSumFinalValue, closeTo(240, 1e-9)); // 3 parts à 80
    });

    test('baisse maximale mesurée sur le cours', () {
      expect(r.maxDrawdown, closeTo(0.5, 1e-9));
    });

    test('le rejeu compte ce qui a été versé à la date courante', () {
      final replay = Replay(r)..jumpTo(d(2024, 2, 29));
      expect(replay.currentInvested, 200);
      expect(replay.currentValue, closeTo(150, 1e-9)); // 3 parts à 50
    });

    test('le mode est enregistré avec la simulation', () {
      final back = SimulationParams.fromJson(monthly.toJson());
      expect(back.mode, InvestMode.monthly);
      // Anciennes sauvegardes, sans mode : achat unique.
      final old = monthly.toJson()..remove('mode');
      expect(SimulationParams.fromJson(old).mode, InvestMode.lumpSum);
    });

    test('runSimulation choisit la bonne méthode', () {
      expect(runSimulation(monthly, monthSeries).payments, 3);
    });
  });

  test('ajout de mois : reste dans le mois visé', () {
    expect(addMonths(d(2024, 1, 31), 1), d(2024, 2, 29));
    expect(addMonths(d(2023, 1, 31), 1), d(2023, 2, 28));
    expect(addMonths(d(2024, 11, 15), 3), d(2025, 2, 15));
  });

  group('rendement annualisé', () {
    test('×2 en un peu plus de 10 ans à 7 %', () {
      final r = annualizedReturn(
        invested: 1000,
        finalValue: 2000,
        days: (10.24 * 365.25).round(),
      );
      expect(r, closeTo(0.07, 0.001));
    });

    test('rien sous un an', () {
      expect(
        annualizedReturn(invested: 1000, finalValue: 1500, days: 200),
        isNull,
      );
    });
  });

  test('une valeur par année complète', () {
    final values = yearlyValues(
      [
        d(2020, 3, 2),
        d(2021, 3, 1),
        d(2021, 3, 3),
        d(2022, 3, 2),
        d(2022, 6, 1),
      ],
      [100, 110, 115, 120, 130],
    );
    // 2 mars 2020, 2 mars 2021 (cours du 1er), 2 mars 2022 ; juin ignoré.
    expect(values, [100, 110, 120]);
  });
}
