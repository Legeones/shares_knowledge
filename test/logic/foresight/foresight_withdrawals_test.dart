import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/foresight/foresight.dart';
import 'package:shares_knowledge/logic/foresight/inflation.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';
import 'package:shares_knowledge/models/price_point.dart';

import '../helpers.dart';

const _chapter = ForesightChapter(
  context: 'c',
  whyEnter: 'e',
  whyLeave: 'l',
  lessonTitle: 't',
  lesson: 'x',
);

/// Un actif détenu du 1er janvier au 31 mars, au prix [price] chaque jour.
ForesightScenario oneAsset(
  double Function(DateTime) price, {
  double? maxInvest,
}) {
  final start = d(2024, 1, 1);
  final end = d(2024, 3, 31);
  return ForesightScenario(
    decade: 2020,
    title: 'test',
    currency: 'USD',
    initialCapital: 1200,
    source: 'test',
    steps: [
      AssetStep(
        symbol: 'X',
        name: 'X',
        buy: start,
        sell: end,
        maxInvest: maxInvest,
        prices: [
          for (
            var day = start;
            !day.isAfter(end);
            day = day.add(const Duration(days: 1))
          )
            PricePoint(date: day, close: price(day)),
        ],
        story: 's',
        chapter: _chapter,
      ),
    ],
  );
}

void main() {
  test('règle des 4 % : un douzième par mois, plafonné', () {
    const plan = WithdrawalPlan.lifestyle;
    final today = d(2025, 6, 1);
    expect(plan.amountFor(12000, today), closeTo(40, 1e-9)); // 4 % / 12
    expect(plan.amountFor(10e6, today), 3000); // plafond
    expect(WithdrawalPlan.none.isNone, isTrue);
  });

  test('le plafond suit l’inflation : environ 360 \$ par mois en 1970', () {
    expect(WithdrawalPlan.lifestyle.capAt(d(1970, 6, 1)), closeTo(361, 1));
    expect(dollarsOf(1990), closeTo(0.41, 0.01));
  });

  test('sans retrait ni impôt : rien ne change', () {
    final run = ForesightRun(oneAsset((_) => 10));
    expect(run.finalCapital, 1200);
    expect(run.totalWithdrawn, 0);
  });

  test('un retrait au début de chaque nouveau mois (pas le premier jour)', () {
    final s = oneAsset((_) => 10);
    final run = ForesightRun(s, withdrawals: WithdrawalPlan.lifestyle);
    // 1er février et 1er mars : deux retraits de 4 %/12 du capital.
    final afterFeb = 1200 * (1 - 0.04 / 12);
    final afterMar = afterFeb * (1 - 0.04 / 12);
    expect(run.totalWithdrawn, closeTo(1200 - afterMar, 1e-9));
    expect(run.finalCapital, closeTo(afterMar, 1e-9));
    expect(run.lastMonthlyWithdrawal, closeTo(afterFeb * 0.04 / 12, 1e-9));
  });

  test('le plafond limite le retrait mensuel', () {
    final s = oneAsset((_) => 10);
    const plan = WithdrawalPlan(monthlyCapToday: 1);
    final run = ForesightRun(s, withdrawals: plan);
    // 2 mois au plafond : 1 $ d'aujourd'hui, en dollars de 2024.
    expect(run.totalWithdrawn, closeTo(2 * dollarsOf(2024), 1e-9));
  });

  test('réserve plafonnée : le surplus est mis à l’abri à l’achat', () {
    final s = oneAsset((day) => day.month == 1 ? 10 : 20, maxInvest: 1000);
    final run = ForesightRun(s, useReserveCaps: true);
    expect(run.totalSheltered, 200); // 1 200 − 1 000
    expect(run.finalCapital, 2000); // seuls 1 000 $ ont doublé
    expect(run.totalWealth, 2200);
    // Sans la règle, tout le capital est investi.
    expect(ForesightRun(s).finalCapital, 2400);
  });

  test('seule la part de gain d’un retrait est imposée', () {
    // Le prix double le 1er février : la moitié de chaque retrait est un gain.
    final s = oneAsset((day) => day.month == 1 ? 10 : 20);
    final run = ForesightRun(
      s,
      taxRate: (_) => 0.30,
      withdrawals: WithdrawalPlan.lifestyle,
    );
    final firstAmount = 2400 * 0.04 / 12; // capital doublé : 2 400 $
    final firstTax = firstAmount / 2 * 0.30;
    expect(
      run.days.firstWhere((x) => x.date == d(2024, 2, 1)).taxPaid,
      closeTo(firstTax, 1e-9),
    );
    // À la vente, l'impôt porte sur le gain des parts restantes.
    expect(run.totalTax, greaterThan(firstTax));
    expect(run.finalCapital, lessThan(2400));
  });
}
