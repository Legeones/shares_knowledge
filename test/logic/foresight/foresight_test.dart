import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/foresight/foresight.dart';
import 'package:shares_knowledge/logic/taxes.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';

/// Le vrai scénario embarqué dans l'application.
final scenario = ForesightScenario.fromJson(
  jsonDecode(
    File('assets/scenarios/foresight/foresight_2020s.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

void main() {
  final run = ForesightRun(scenario);

  test('le fichier contient les 9 étapes validées', () {
    expect(scenario.steps, hasLength(9));
    expect(scenario.assetSteps.map((s) => s.name), [
      'Tesla',
      'Dogecoin',
      'Nvidia',
      'Nvidia',
      'Palantir',
      'Palantir',
    ]);
    expect(scenario.steps[2], isA<CashStep>());
  });

  test('chaque étape a son chapitre complet (contexte, raisons, leçon)', () {
    for (final step in scenario.steps) {
      final c = step.chapter;
      for (final text in [
        c.context,
        c.whyEnter,
        c.whyLeave,
        c.lessonTitle,
        c.lesson,
      ]) {
        expect(text.trim(), isNotEmpty);
      }
    }
  });

  test('multiplicateurs vérifiés de chaque étape', () {
    final m = [for (final s in run.steps) s.multiplier];
    expect(m[0], closeTo(1.21, 0.01)); // Tesla
    expect(m[1], closeTo(92.36, 0.01)); // Dogecoin
    expect(m[2], 1); // cash
    expect(m[5], closeTo(12.08, 0.01)); // Nvidia, ruée vers l'IA
  });

  test('1 000 \$ deviennent environ 26,7 millions de dollars', () {
    expect(run.finalCapital, closeTo(26.68e6, 0.01e6));
  });

  test('les étapes s’enchaînent : le capital vendu est réinvesti', () {
    for (var i = 1; i < run.steps.length; i++) {
      expect(run.steps[i].capitalBefore, run.steps[i - 1].capitalAfter);
    }
  });

  test('un jour par date, sans trou, du 04/01/2021 au 05/10/2026', () {
    expect(run.days.first.date, DateTime.utc(2021, 1, 4));
    expect(run.days.last.date, DateTime.utc(2026, 10, 5));
    for (var i = 1; i < run.days.length; i++) {
      expect(run.days[i].date.difference(run.days[i - 1].date).inDays, 1);
    }
    expect(run.indexOf(DateTime.utc(2021, 1, 5)), 1);
  });

  test('pendant le cash, le capital ne bouge pas et il n’y a pas de cours', () {
    final cash = run.days.where((d) => d.stepIndex == 2);
    expect(cash.every((d) => d.price == null), isTrue);
    expect(cash.map((d) => d.capital).toSet(), hasLength(1));
  });

  test('même ce parcours idéal subit de fortes baisses en chemin', () {
    expect(run.drawdown.depth, greaterThan(0.3));
  });

  test('vendre un jour trop tard divise fortement le résultat', () {
    final late = finalCapitalIfSoldOneDayLater(scenario);
    expect(late, lessThan(run.finalCapital * 0.85));
  });

  group('impôts', () {
    test('France 30 % à chaque vente : l’effet se cumule', () {
      final taxed = ForesightRun(
        scenario,
        taxRate: const TaxProfile(TaxCountry('France', 'FR')).rateFor,
      );
      // Bien plus que 30 % de moins, car l'impôt réduit le capital réinvesti.
      expect(taxed.finalCapital, lessThan(run.finalCapital * 0.3));
      expect(taxed.totalTax, greaterThan(0));
    });

    test('pays sans impôt sur les plus-values : même résultat', () {
      final ch = ForesightRun(
        scenario,
        taxRate: const TaxProfile(TaxCountry('Suisse', 'CH')).rateFor,
      );
      expect(ch.finalCapital, closeTo(run.finalCapital, 1));
    });

    test('États-Unis : taux réduit après plus d’un an de détention', () {
      final us = TaxProfile(taxCountryFor('US'), income: IncomeLevel.high);
      expect(us.rateFor(30), 0.408);
      expect(us.rateFor(400), 0.238);
    });

    test('pays inconnu : la France par défaut', () {
      expect(taxCountryFor('JP').name, 'France');
      expect(taxCountryFor(null).name, 'France');
    });

    test('une perte n’est pas taxée', () {
      expect(gainAfterTax(-100, 0.3), -100);
      expect(gainAfterTax(100, 0.3), closeTo(70, 1e-9));
    });
  });
}
