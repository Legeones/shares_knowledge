import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/wallet/wallet_engine.dart';
import 'package:shares_knowledge/models/position_rule.dart';
import 'package:shares_knowledge/models/wallet/wallet.dart';
import 'package:shares_knowledge/logic/price_series.dart';
import 'package:shares_knowledge/models/price_point.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

PriceSeries series(Map<DateTime, double> prices) => PriceSeries([
  for (final e in prices.entries) PricePoint(date: e.key, close: e.value),
]);

WalletTransaction start(double amount, DateTime date) => WalletTransaction(
  date: date,
  type: WalletTxType.deposit,
  source: WalletTxSource.initial,
  amount: amount,
);

void main() {
  group('état et ordres', () {
    test('dépôt, achat, vente partielle puis totale', () {
      final txs = [start(1000, d(2026, 1, 5))];
      var state = walletStateOf(txs);
      txs.add(
        buyOrder(
          state,
          symbol: 'SPY',
          amount: 600,
          price: 100,
          date: d(2026, 1, 5),
        ),
      );
      state = walletStateOf(txs);
      expect(state.cash, 400);
      expect(state.holdings['SPY']!.units, 6);

      txs.add(
        sellOrder(
          state,
          symbol: 'SPY',
          amount: 240,
          price: 120,
          date: d(2026, 1, 6),
        ),
      );
      state = walletStateOf(txs);
      expect(state.holdings['SPY']!.units, closeTo(4, 1e-9));
      expect(state.holdings['SPY']!.averagePrice, closeTo(100, 1e-9));
      expect(state.cash, closeTo(640, 1e-9));
      expect(state.valueWith((_) => 120), closeTo(1120, 1e-9));
      expect(state.deposited, 1000);

      txs.add(
        sellOrder(
          state,
          symbol: 'SPY',
          price: 120,
          date: d(2026, 1, 7),
          all: true,
        ),
      );
      expect(walletStateOf(txs).holdings, isEmpty);
    });

    test('ordres impossibles refusés', () {
      final state = walletStateOf([start(100, d(2026, 1, 5))]);
      expect(
        () => buyOrder(
          state,
          symbol: 'SPY',
          amount: 500,
          price: 10,
          date: d(2026, 1, 5),
        ),
        throwsA(isA<WalletException>()),
      );
      expect(
        () => sellOrder(state, symbol: 'SPY', price: 10, date: d(2026, 1, 5)),
        throwsA(isA<WalletException>()),
      );
      expect(
        () => depositOrder(0, d(2026, 1, 5)),
        throwsA(isA<WalletException>()),
      );
    });
  });

  group('versements mensuels', () {
    test('prochaine date : ce mois-ci ou le suivant', () {
      DcaPlan plan(DateTime created, {DateTime? last}) => DcaPlan(
        symbol: 'SPY',
        name: 'S&P 500',
        amount: 100,
        dayOfMonth: 5,
        createdAt: created,
        lastTarget: last,
      );
      expect(nextTarget(plan(d(2026, 1, 2))), d(2026, 1, 5));
      expect(nextTarget(plan(d(2026, 1, 20))), d(2026, 2, 5));
      expect(
        nextTarget(plan(d(2026, 1, 2), last: d(2026, 1, 5))),
        d(2026, 2, 5),
      );
    });

    test('rattrapage : chaque mois manqué, au jour de bourse suivant', () {
      final plan = DcaPlan(
        symbol: 'SPY',
        name: 'S&P 500',
        amount: 100,
        dayOfMonth: 3,
        createdAt: d(2026, 1, 1),
      );
      final prices = {
        'SPY': series({
          d(2026, 1, 2): 50,
          d(2026, 1, 5): 50, // le 3 est un samedi : achat le lundi 5
          d(2026, 2, 3): 100,
          d(2026, 3, 3): 80,
          d(2026, 3, 4): 90,
        }),
      };
      final r = catchUp(
        transactions: const [],
        plans: [plan],
        rules: const {},
        prices: prices,
        after: d(2026, 1, 1),
        until: d(2026, 3, 4),
      );
      final buys = r.transactions.where((t) => t.type == WalletTxType.buy);
      expect(
        [for (final b in buys) b.date],
        [d(2026, 1, 5), d(2026, 2, 3), d(2026, 3, 3)],
      );
      expect(r.plans.single.lastTarget, d(2026, 3, 3));
      final state = walletStateOf(r.transactions);
      expect(state.deposited, 300);
      expect(state.cash, closeTo(0, 1e-9));
      expect(state.holdings['SPY']!.units, closeTo(2 + 1 + 1.25, 1e-9));
    });
  });

  group('stop-loss et prise de bénéfices', () {
    final bought = [
      start(1000, d(2026, 1, 5)),
      WalletTransaction(
        date: d(2026, 1, 5),
        type: WalletTxType.buy,
        source: WalletTxSource.manual,
        symbol: 'BTC',
        units: 10,
        price: 100,
        amount: 1000,
      ),
    ];

    CatchUpResult run(PositionRule rule) => catchUp(
      transactions: bought,
      plans: const [],
      rules: {'BTC': rule},
      prices: {
        'BTC': series({
          d(2026, 1, 6): 90,
          d(2026, 1, 7): 75, // −25 %
          d(2026, 1, 8): 160, // +60 %
        }),
      },
      after: d(2026, 1, 5),
      until: d(2026, 1, 8),
    );

    test('stop-loss à −20 % : tout vendu le premier jour sous le seuil', () {
      final r = run(const PositionRule(symbol: 'BTC', stopLoss: 0.2));
      final sell = r.transactions.single;
      expect(sell.source, WalletTxSource.stopLoss);
      expect(sell.date, d(2026, 1, 7));
      expect(sell.amount, 750);
      expect(r.triggeredRules, {'BTC'});
    });

    test('prise de bénéfices à +50 %', () {
      final r = run(const PositionRule(symbol: 'BTC', takeProfit: 0.5));
      expect(r.transactions.single.source, WalletTxSource.takeProfit);
      expect(r.transactions.single.amount, 1600);
    });

    test('rien à faire tant que les seuils ne sont pas atteints', () {
      final r = run(const PositionRule(symbol: 'BTC', stopLoss: 0.3));
      expect(r.transactions, isEmpty);
    });
  });

  test('valeur au fil du temps, somme déposée comprise', () {
    final history = walletHistory(
      transactions: [
        start(1000, d(2026, 1, 5)),
        WalletTransaction(
          date: d(2026, 1, 5),
          type: WalletTxType.buy,
          source: WalletTxSource.manual,
          symbol: 'SPY',
          units: 5,
          price: 100,
          amount: 500,
        ),
      ],
      prices: {
        'SPY': series({d(2026, 1, 5): 100, d(2026, 1, 6): 120}),
      },
      from: d(2026, 1, 5),
      to: d(2026, 1, 6),
    );
    expect([for (final p in history) p.value], [1000, 1100]);
    expect(history.last.deposited, 1000);
  });
}
