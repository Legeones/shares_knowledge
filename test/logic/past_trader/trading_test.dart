import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/time_cursor.dart';
import 'package:shares_knowledge/logic/past_trader/trading.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/past_trader/past_trader.dart';
import 'package:shares_knowledge/models/price_point.dart';

import '../helpers.dart';

/// Petite partie fictive : une action (cours de weekSeries, pas de
/// week-end), une crypto cotée tous les jours, et SPY pour la comparaison.
TraderGameData fakeData() {
  List<PricePoint> pts(Map<DateTime, double> m) => [
    for (final e in m.entries) PricePoint(date: e.key, close: e.value),
  ];
  return TraderGameData(
    id: 'test',
    title: 'Test',
    intro: '',
    start: d(2024, 1, 1),
    end: d(2024, 1, 8),
    historyFrom: d(2023, 12, 25),
    initialCash: 1000,
    source: '',
    assets: [
      TraderAsset(
        symbol: 'ACT',
        name: 'Action',
        type: AssetType.stock,
        description: '',
        prices: weekSeries.points,
      ),
      TraderAsset(
        symbol: 'CRY',
        name: 'Crypto',
        type: AssetType.crypto,
        description: '',
        prices: pts({
          for (var i = 0; i < 8; i++) d(2024, 1, 1 + i): 10.0 + i, // 10 → 17
        }),
      ),
      TraderAsset(
        symbol: 'SPY',
        name: 'S&P 500',
        type: AssetType.etf,
        description: '',
        prices: weekSeries.points,
      ),
      TraderAsset(
        symbol: 'NEW',
        name: 'Introduite plus tard',
        type: AssetType.stock,
        description: '',
        prices: pts({d(2024, 1, 5): 50, d(2024, 1, 8): 60}),
      ),
    ],
  );
}

void main() {
  late TraderGame game;
  setUp(() => game = TraderGame(fakeData()));

  test('départ : tout en cash', () {
    expect(game.cash, 1000);
    expect(game.totalValue, 1000);
    expect(game.positions, isEmpty);
    expect(game.current, d(2024, 1, 1));
  });

  test('acheter puis la valeur suit le cours', () {
    game.buy('ACT', 500); // 5 parts à 100
    expect(game.cash, 500);
    expect(game.positions['ACT']!.units, 5);
    game.advance(TimeStep.day); // 110
    expect(game.totalValue, 500 + 5 * 110);
  });

  test('plusieurs actifs en même temps', () {
    game.buy('ACT', 400);
    game.buy('CRY', 600); // 60 unités à 10
    game.advance(TimeStep.day); // ACT 110, CRY 11
    expect(game.totalValue, closeTo(4 * 110 + 60 * 11, 1e-9));
  });

  test('vendre une partie : plus-value au prix moyen pondéré', () {
    game.buy('ACT', 1000); // 10 parts à 100
    game.advance(TimeStep.day); // 110
    game.sell('ACT', amount: 550); // 5 parts : gain 5 × (110 − 100)
    expect(game.trades.last.realizedGain, closeTo(50, 1e-9));
    expect(game.positions['ACT']!.units, closeTo(5, 1e-9));
    expect(game.positions['ACT']!.averagePrice, closeTo(100, 1e-9));
    expect(game.cash, closeTo(550, 1e-9));
  });

  test('tout vendre : la ligne disparaît, pas de miettes', () {
    game.buy('ACT', 1000);
    game.advance(TimeStep.day);
    game.advance(TimeStep.day); // 90 : perte
    game.sell('ACT', all: true);
    expect(game.positions, isEmpty);
    expect(game.cash, closeTo(900, 1e-9));
    expect(game.realizedGains, closeTo(-100, 1e-9));
  });

  test('passer de l’action à la crypto (changer d’avis)', () {
    game.buy('ACT', 1000);
    game.advance(TimeStep.day); // ACT 110 → 1100
    game.sell('ACT', all: true);
    game.buy('CRY', game.cash); // 1100 / 11 = 100 unités
    game.advance(TimeStep.day); // CRY 12
    expect(game.totalValue, closeTo(1200, 1e-9));
  });

  group('ordres refusés', () {
    test('plus que le cash disponible', () {
      expect(() => game.buy('ACT', 1500), throwsA(isA<OrderException>()));
    });

    test('vendre ce qu’on n’a pas', () {
      expect(
        () => game.sell('ACT', amount: 10),
        throwsA(isA<OrderException>()),
      );
      game.buy('ACT', 100);
      expect(
        () => game.sell('ACT', amount: 500),
        throwsA(isA<OrderException>()),
      );
    });

    test('montant nul ou négatif', () {
      expect(() => game.buy('ACT', 0), throwsA(isA<OrderException>()));
      expect(() => game.buy('ACT', -5), throwsA(isA<OrderException>()));
    });

    test('Bourse fermée le week-end, crypto ouverte', () {
      for (var i = 0; i < 5; i++) {
        game.advance(TimeStep.day); // samedi 6
      }
      expect(game.isMarketOpen('ACT'), isFalse);
      expect(() => game.buy('ACT', 100), throwsA(isA<OrderException>()));
      game.buy('CRY', 100); // OK
    });

    test('actif pas encore coté', () {
      expect(game.isListed('NEW'), isFalse);
      expect(() => game.buy('NEW', 100), throwsA(isA<OrderException>()));
      for (var i = 0; i < 4; i++) {
        game.advance(TimeStep.day); // vendredi 5 : première cotation
      }
      game.buy('NEW', 100);
    });
  });

  test('aucun cours futur n’est visible', () {
    game.advance(TimeStep.day); // mardi 2
    final visible = game.visiblePrices('ACT');
    expect(visible.last.date, d(2024, 1, 2));
    expect(visible.every((p) => !p.date.isAfter(game.current)), isTrue);
  });

  test('le temps n’avance que vers l’avant, jusqu’à la fin', () {
    game.advance(TimeStep.month);
    expect(game.current, d(2024, 1, 8));
    expect(game.isFinished, isTrue);
    expect(() => game.buy('ACT', 10), throwsA(isA<OrderException>()));
  });

  test('une valeur par jour traversé dans l’historique', () {
    game.buy('ACT', 1000);
    game.advance(TimeStep.week);
    expect(game.history, hasLength(8)); // du 1er au 8
    expect(game.history[5].value, 1200); // samedi : cours du vendredi
  });

  test('comparaison avec « acheter le S&P 500 et garder »', () {
    game.advance(TimeStep.week);
    expect(game.buyAndHoldSpy, closeTo(1300, 1e-9)); // 100 → 130
  });

  test('le vrai fichier du jeu se lit correctement', () {
    final data = TraderGameData.fromJson(
      jsonDecode(
        File('assets/scenarios/past_trader_2018_2020.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    expect(data.assets, hasLength(16));
    expect(data.start, d(2018, 1, 2));
    expect(data.initialCash, 10000);
    final real = TraderGame(data);
    expect(real.isListed('SPY'), isTrue);
    expect(real.isListed('ZM'), isFalse); // introduite en 2019
    expect(real.isListed('DOGE/USD'), isFalse); // données dès mars 2020
  });

  test('avancer jusqu’à une date précise', () {
    game.advanceTo(d(2024, 1, 4));
    expect(game.current, d(2024, 1, 4));
    game.advanceTo(d(2023, 1, 1)); // dans le passé : rien ne se passe
    expect(game.current, d(2024, 1, 4));
  });

  test('variation d’un actif sur une période', () {
    game.advanceTo(d(2024, 1, 5)); // 120, contre 100 le lundi
    expect(game.changeOver('ACT', 4), closeTo(0.20, 1e-9));
    expect(game.changeOver('NEW', 30), isNull); // pas d'historique assez long
  });

  group('bilan', () {
    test('durée de détention depuis l’ouverture de la position', () {
      game.buy('ACT', 500); // lundi 1er
      game.advanceTo(d(2024, 1, 5)); // vendredi 5
      game.sell('ACT', all: true);
      expect(game.trades.last.holdingDays, 4);
    });

    test('arrêter la partie avant la fin', () {
      game.advance(TimeStep.day);
      game.stop();
      expect(game.isFinished, isTrue);
      expect(game.stoppedEarly, isTrue);
      expect(() => game.buy('ACT', 10), throwsA(isA<OrderException>()));
    });

    test('plus-values imposables : ventes + positions encore ouvertes', () {
      game.buy('ACT', 500); // 5 parts à 100
      game.buy('CRY', 100); // 10 unités à 10
      game.advance(TimeStep.day); // ACT 110, CRY 11
      game.sell('ACT', all: true); // +50
      game.advance(TimeStep.day); // CRY 12
      final gains = game.taxableGains();
      expect(gains.map((g) => g.gain), [
        closeTo(50, 1e-9),
        closeTo(20, 1e-9), // CRY : 10 × 12 − 100
      ]);
      expect(gains.last.holdingDays, 2);
    });

    test('baisse maximale du portefeuille', () {
      game.buy('ACT', 1000);
      game.advanceTo(d(2024, 1, 5)); // 100 → 110 → 90 → 95 → 120
      expect(game.drawdown.depth, closeTo(200 / 1100, 1e-9));
    });

    test('performance de chaque actif acheté au début et gardé', () {
      game.advanceTo(d(2024, 1, 8));
      final perf = game.buyAndHoldPerformances();
      expect(perf['ACT'], closeTo(0.30, 1e-9)); // 100 → 130
      expect(perf['CRY'], closeTo(0.70, 1e-9)); // 10 → 17
    });

    test('les actifs pas encore cotés au début sont ignorés', () {
      final real = TraderGame(
        TraderGameData.fromJson(
          jsonDecode(
            File('assets/scenarios/past_trader_2018_2020.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>,
        ),
      );
      final perf = real.buyAndHoldPerformances();
      expect(perf.containsKey('BTC/USD'), isTrue);
      expect(perf.containsKey('ZM'), isFalse);
      expect(perf.containsKey('DOGE/USD'), isFalse);
    });
  });
}
