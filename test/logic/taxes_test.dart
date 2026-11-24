import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/taxes.dart';

import 'helpers.dart';

TaxableGain g(int year, double gain, {int days = 30}) =>
    (date: d(year, 6, 1), gain: gain, holdingDays: days);

final france = TaxProfile(taxCountryFor('FR'));
UsState state(String name) => usStates.firstWhere((s) => s.name == name);

void main() {
  group('taux', () {
    test('France : 30 % quel que soit le revenu ou la durée', () {
      expect(france.rateFor(10), 0.30);
      expect(france.rateFor(1000), 0.30);
    });

    test('Belgique et Suisse : 0 %', () {
      expect(TaxProfile(taxCountryFor('BE')).rateFor(10), 0);
      expect(TaxProfile(taxCountryFor('CH')).rateFor(10), 0);
    });

    test('États-Unis : revenus et durée de détention changent le taux', () {
      final modest = TaxProfile(
        taxCountryFor('US'),
        income: IncomeLevel.modest,
      );
      expect(modest.rateFor(30), 0.12);
      expect(modest.rateFor(400), 0); // long terme, revenus modestes
      final middle = TaxProfile(taxCountryFor('US'));
      expect(middle.rateFor(30), 0.22);
      expect(middle.rateFor(400), 0.15);
    });

    test('États-Unis : l’État s’ajoute au fédéral', () {
      final ca = TaxProfile(taxCountryFor('US'), state: state('Californie'));
      expect(ca.rateFor(30), closeTo(0.22 + 0.093, 1e-9));
      final tx = TaxProfile(taxCountryFor('US'), state: state('Texas'));
      expect(tx.rateFor(30), 0.22);
      final ma = TaxProfile(taxCountryFor('US'), state: state('Massachusetts'));
      expect(ma.rateFor(30), closeTo(0.22 + 0.12, 1e-9));
      expect(ma.rateFor(400), closeTo(0.15 + 0.05, 1e-9));
    });

    test('Canada : la moitié du gain au taux marginal', () {
      expect(
        TaxProfile(taxCountryFor('CA'), income: IncomeLevel.high).rateFor(1),
        0.267,
      );
    });

    test('une explication pour chaque pays', () {
      for (final c in taxCountries) {
        expect(TaxProfile(c).explanation, isNotEmpty);
      }
    });
  });

  group('calcul annuel', () {
    test('un gain : 30 % en France', () {
      final r = computeAnnualTaxes([g(2018, 1000)], france);
      expect(r.totalTax, closeTo(300, 1e-9));
    });

    test('dans une année, les pertes compensent les gains', () {
      final r = computeAnnualTaxes([g(2018, 1000), g(2018, -400)], france);
      expect(r.years.single.taxable, closeTo(600, 1e-9));
      expect(r.totalTax, closeTo(180, 1e-9));
    });

    test('une perte nette est reportée sur l’année suivante', () {
      final r = computeAnnualTaxes([g(2018, -500), g(2019, 800)], france);
      expect(r.years[0].tax, 0);
      expect(r.years[1].taxable, closeTo(300, 1e-9));
      expect(r.totalTax, closeTo(90, 1e-9));
      expect(r.lossCarriedForward, 0);
    });

    test('pertes restantes à la fin', () {
      final r = computeAnnualTaxes([g(2018, -500), g(2019, 200)], france);
      expect(r.totalTax, 0);
      expect(r.lossCarriedForward, closeTo(-300, 1e-9));
    });

    test('États-Unis : court et long terme taxés différemment', () {
      final us = TaxProfile(taxCountryFor('US'));
      final r = computeAnnualTaxes([
        g(2018, 1000, days: 30), // court terme : 22 %
        g(2018, 1000, days: 400), // long terme : 15 %
      ], us);
      expect(r.totalTax, closeTo(220 + 150, 1e-9));
    });

    test('aucun gain : aucun impôt', () {
      expect(computeAnnualTaxes([], france).totalTax, 0);
    });
  });
}
