import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/foresight/foresight_loader.dart';
import 'package:shares_knowledge/logic/foresight/foresight.dart';
import 'package:shares_knowledge/logic/taxes.dart';
import 'package:shares_knowledge/models/price_point.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';

/// Les vrais parcours embarqués, un par décennie.
final catalog = ForesightCatalog([
  for (final decade in foresightDecades)
    ForesightScenario.fromJson(
      jsonDecode(File(foresightAsset(decade)).readAsStringSync())
          as Map<String, dynamic>,
    ),
]);

void main() {
  test('une décennie par fichier, de 1970 à 2020', () {
    expect(catalog.decades, [1970, 1980, 1990, 2000, 2010, 2020]);
    for (final s in catalog.scenarios) {
      expect(s.start.year, inInclusiveRange(s.decade, s.decade + 1));
      expect(s.initialCapital, 1000);
      // 40 ans au plus, et pas après 2026.
      expect(s.end.year, lessThanOrEqualTo(s.decade + 40));
      expect(s.end.year, lessThanOrEqualTo(2026));
    }
  });

  for (final scenario in catalog.scenarios) {
    group(scenario.decadeLabel, () {
      test('les étapes se suivent sans se chevaucher', () {
        for (var i = 1; i < scenario.steps.length; i++) {
          final previous = scenario.steps[i - 1].end;
          final start = scenario.steps[i].start;
          expect(start.isAfter(previous), isTrue, reason: '$i');
        }
      });

      test('les cours couvrent chaque achat et chaque vente', () {
        for (final step in scenario.assetSteps) {
          expect(
            step.prices.any((p) => !p.date.isAfter(step.buy)),
            isTrue,
            reason: '${step.name} achat',
          );
          expect(
            step.prices.any((p) => p.date == step.sell),
            isTrue,
            reason: '${step.name} vente',
          );
        }
      });

      test('chaque étape a son chapitre complet', () {
        for (final step in scenario.steps) {
          final c = step.chapter;
          for (final text in [
            step.story,
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

      test('chaque achat a une réserve plafonnée', () {
        for (final step in scenario.assetSteps) {
          expect(step.maxInvest, isNotNull, reason: step.name);
        }
      });

      test('impôts, retraits et réserve réduisent le résultat théorique', () {
        final pure = ForesightRun(scenario);
        final lived = livedRun(
          scenario,
          taxRate: TaxProfile(taxCountryFor('FR')).rateFor,
        );
        expect(pure.finalCapital, greaterThan(scenario.initialCapital));
        expect(lived.totalWealth, lessThan(pure.finalCapital));
        expect(lived.totalWithdrawn, greaterThan(0));
        expect(
          lived.lastMonthlyWithdrawal,
          lessThanOrEqualTo(
            WithdrawalPlan.lifestyle.capAt(scenario.end) + 1e-9,
          ),
        );
        // Le patrimoine additionne bien ses trois parts.
        expect(
          lived.totalWealth,
          closeTo(
            lived.finalCapital + lived.totalSheltered + lived.totalWithdrawn,
            1e-6,
          ),
        );
      });
    });
  }

  test('« sans impôts ni retraits » : même réserve plafonnée que le vécu', () {
    final france = TaxProfile(taxCountryFor('FR'));
    for (final s in catalog.scenarios) {
      final lived = livedRun(s, taxRate: france.rateFor);
      final capped = ForesightRun(s, useReserveCaps: true);
      // Les impôts et les retraits coûtent quelque chose…
      expect(capped.totalWealth, greaterThan(lived.totalWealth));
      // …mais pas un facteur 1 000 : l'écart géant venait de la réserve.
      expect(capped.totalWealth, lessThan(lived.totalWealth * 3));
    }
  });

  test('la vente et son impôt tombent le jour même ; mettre à l’abri ne fait '
      'pas chuter le patrimoine', () {
    final france = TaxProfile(taxCountryFor('FR'));
    for (final s in catalog.scenarios) {
      final run = livedRun(s, taxRate: france.rateFor);
      for (final (i, result) in run.steps.indexed) {
        final step = result.step;
        if (step is! AssetStep) continue;
        final sellDay = run.days.lastWhere(
          (d) => d.stepIndex == i && !d.date.isAfter(step.sell),
        );
        expect(sellDay.capital, closeTo(result.capitalAfter, 1e-6));

        // Jour d'achat : le surplus part à l'abri, le patrimoine ne bouge
        // pas (au même cours, sans retrait ce jour-là).
        if (result.sheltered == 0) continue;
        final buy = run.days.indexWhere((d) => d.date == dateOnly(step.buy));
        final before = run.days[buy - 1];
        final after = run.days[buy];
        if (after.withdrawn != before.withdrawn) continue;
        expect(after.wealth, closeTo(before.wealth, before.wealth * 1e-9));
      }
    }
  });
}
