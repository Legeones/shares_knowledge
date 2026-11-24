import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shares_knowledge/widgets/glass.dart';
import 'package:shares_knowledge/data/past_trader/news_source.dart';
import 'package:shares_knowledge/logic/past_trader/news_feed.dart';
import 'package:shares_knowledge/models/past_trader/past_trader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shares_knowledge/logic/taxes.dart';
import 'package:shares_knowledge/logic/past_trader/trading.dart';
import 'package:shares_knowledge/models/position_rule.dart';
import 'package:shares_knowledge/providers/settings_provider.dart';
import 'package:shares_knowledge/providers/past_trader/trader_attempts_provider.dart';
import 'package:shares_knowledge/providers/past_trader/trader_game_controller.dart';
import 'package:shares_knowledge/providers/past_trader/trader_save_provider.dart';
import 'package:shares_knowledge/screens/past_trader/trader_debrief_screen.dart';
import 'package:shares_knowledge/screens/past_trader/past_trader_screen.dart';

import '../../fakes.dart';

final data = TraderGameData.fromJson(
  jsonDecode(
    File('assets/scenarios/past_trader_2018_2020.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

final news = NewsFeed(
  parseNews(File('assets/scenarios/past_trader_news.json').readAsStringSync()),
);

/// Montants avec espaces insécables : le point accepte n'importe quel caractère.
Finder money(String pattern) => find.textContaining(RegExp(pattern));

/// La liste verticale du marché (la première ListView ; le TabBarView,
/// lui, défile horizontalement).
Finder get marketList => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

late TraderSaveProvider traderSaves;

/// Ouvre l'onglet Past Trader (sans lancer de partie).
Future<void> pumpTab(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  traderSaves = TraderSaveProvider(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: data),
        Provider.value(value: news),
        ChangeNotifierProvider(
          create: (_) => TraderAttemptsProvider(FakeTraderAttemptDao()),
        ),
        ChangeNotifierProvider.value(value: traderSaves),
      ],
      child: const MaterialApp(home: Scaffold(body: PastTraderScreen())),
    ),
  );
}

Future<void> startGame(WidgetTester tester) async {
  await pumpTab(tester);
  await tester.scrollUntilVisible(find.text('Nouvelle partie'), 200);
  await tester.tap(find.text('Nouvelle partie'));
  await tester.pumpAndSettle();
}

Future<void> openAsset(WidgetTester tester, String name) async {
  final tile = find.widgetWithText(ListTile, name);
  await tester.scrollUntilVisible(tile, 200, scrollable: marketList);
  await tester.ensureVisible(tile); // entièrement à l'écran avant de toucher
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> buyHalf(WidgetTester tester) async {
  await tester.tap(find.text('Acheter'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('50 %'));
  await tester.pump();
  await tester.tap(find.text('Confirmer l’achat'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('départ : 10 000 \$ en cash, le 2 janvier 2018', (tester) async {
    await startGame(tester);
    expect(find.text('mardi 02/01/2018'), findsOneWidget);
    expect(money(r'^10.000,00.\$$'), findsNWidgets(2)); // valeur totale + cash
    expect(find.text('S&P 500'), findsOneWidget);
  });

  testWidgets('Zoom n’est pas encore coté en 2018', (tester) async {
    await startGame(tester);
    final zoom = find.widgetWithText(ListTile, 'Zoom');
    await tester.scrollUntilVisible(zoom, 200, scrollable: marketList);
    expect(
      find.descendant(of: zoom, matching: find.text('pas encore coté')),
      findsOneWidget,
    );
  });

  testWidgets('acheter la moitié en S&P 500 : cash et portefeuille à jour', (
    tester,
  ) async {
    await startGame(tester);
    await openAsset(tester, 'S&P 500');
    await buyHalf(tester);
    expect(find.text('Ma position'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(money(r'^5.000,00.\$$'), findsOneWidget); // cash restant

    await tester.tap(find.text('Ordres'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Achat S&P 500'), findsOneWidget);
  });

  testWidgets('le temps avance ; le week-end la Bourse est fermée', (
    tester,
  ) async {
    await startGame(tester);
    await tester.tap(find.text('+1 j')); // mercredi 3
    await tester.pumpAndSettle();
    expect(find.text('mercredi 03/01/2018'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1 j'));
      await tester.pumpAndSettle();
    }
    expect(find.text('samedi 06/01/2018'), findsOneWidget);
    expect(find.text('Bourse fermée · cryptos ouvertes'), findsOneWidget);

    await openAsset(tester, 'S&P 500');
    final buy = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Acheter'),
    );
    expect(buy.onPressed, isNull); // fermé
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await openAsset(tester, 'Bitcoin');
    final buyBtc = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Acheter'),
    );
    expect(buyBtc.onPressed, isNotNull); // crypto : ouvert
  });

  group('stop-loss et objectif', () {
    test('le bitcoin de début 2018 : stop-loss à −30 % déclenché', () {
      final c = TraderGameController(data, news)..buy('BTC/USD', 5000);
      final avg = c.game.positions['BTC/USD']!.averagePrice;
      expect(
        c.setRule(const PositionRule(symbol: 'BTC/USD', stopLoss: 0.3)),
        isNull,
      );
      c.advanceTo(DateTime.utc(2018, 12, 31));

      final sale = c.takeAutoSales().single;
      expect(sale.trigger, RuleTrigger.stopLoss);
      expect(sale.price, lessThanOrEqualTo(avg * 0.7));
      expect(c.game.positions.containsKey('BTC/USD'), isFalse);
      expect(c.game.rules, isEmpty); // position vendue : règle retirée
      expect(c.takeAutoSales(), isEmpty); // signalée une seule fois
    });

    test('objectif : vendu dès que le gain est atteint', () {
      final c = TraderGameController(data, news)
        ..buy('SPY', 5000)
        ..setRule(const PositionRule(symbol: 'SPY', takeProfit: 0.05));
      c.advanceTo(DateTime.utc(2020, 12, 31));
      final sale = c.takeAutoSales().single;
      expect(sale.trigger, RuleTrigger.takeProfit);
      expect(sale.realizedGain, greaterThan(0));
    });

    test('pas de règle sans position', () {
      final c = TraderGameController(data, news);
      expect(
        c.setRule(const PositionRule(symbol: 'SPY', stopLoss: 0.2)),
        'Tu ne détiens pas cet actif.',
      );
    });

    test('la règle est rejouée à la reprise de la partie', () {
      final played = TraderGameController(data, news)
        ..buy('BTC/USD', 5000)
        ..setRule(const PositionRule(symbol: 'BTC/USD', stopLoss: 0.3))
        ..advanceTo(DateTime.utc(2018, 12, 31));
      final resumed = TraderGameController.resume(
        data,
        news,
        played.snapshot(DateTime.utc(2026, 11, 17)),
      );
      expect(resumed.game.trades.last.trigger, RuleTrigger.stopLoss);
      expect(resumed.game.cash, closeTo(played.game.cash, 1e-9));
      expect(resumed.takeAutoSales(), isEmpty); // déjà vécue
    });
  });

  test(
    'lecture automatique : arrêt à la première grande nouvelle seulement',
    () {
      final c = TraderGameController(data, news);
      final all = news.between(c.game.current, DateTime.utc(2018, 12, 31));
      final major = all.firstWhere((n) => n.major);
      // Des petites nouvelles tombent avant : elles n'arrêtent pas la lecture.
      expect(all.first.major, isFalse);
      c.advanceTo(DateTime.utc(2018, 12, 31), stopAtMajorNews: true);
      expect(c.game.current, major.date);
      expect(c.takeFlashes(), [major]);
    },
  );

  testWidgets(
    'changer de vitesse pendant la lecture s’applique tout de suite',
    (tester) async {
      await startGame(tester);
      final game = Provider.of<TraderGameController>(
        tester.element(find.byType(TabBar)),
        listen: false,
      ).game;
      await tester.tap(find.text('Lent · 3 j/s'));
      await tester.pump();
      await tester.tap(find.byTooltip('Lecture'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final afterSlow = game.current;

      // Sans pause : la lecture continue, trois fois plus vite.
      await tester.tap(find.text('Moyen · 10 j/s'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(
        game.current.difference(afterSlow).inDays,
        inInclusiveRange(8, 12),
      );
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
    },
  );

  group('reprendre une partie', () {
    test('rejouer les décisions redonne exactement la même partie', () {
      final played = TraderGameController(data, news)
        ..advanceTo(DateTime.utc(2018, 3, 1))
        ..buy('SPY', 4000)
        ..advanceTo(DateTime.utc(2018, 6, 1))
        ..sell('SPY', amount: 1000)
        ..buy('BTC/USD', 2000)
        ..advanceTo(DateTime.utc(2018, 9, 3));
      final save = played.snapshot(DateTime.utc(2026, 10, 21));
      // Les avancées de la lecture automatique ne s'empilent pas.
      expect(save.actions, hasLength(6));

      final resumed = TraderGameController.resume(data, news, save);
      expect(resumed.game.current, played.game.current);
      expect(resumed.game.cash, closeTo(played.game.cash, 1e-9));
      expect(resumed.game.totalValue, closeTo(played.game.totalValue, 1e-9));
      expect(resumed.game.trades, hasLength(3));
      expect(resumed.game.history, hasLength(played.game.history.length));
    });

    test('des avancées successives n’en font qu’une', () {
      final c = TraderGameController(data, news);
      for (var d = 3; d <= 20; d++) {
        c.advanceTo(DateTime.utc(2018, 1, d));
      }
      expect(c.snapshot(DateTime.utc(2026)).actions, hasLength(1));
    });

    testWidgets('quitter enregistre la partie, « Reprendre » la retrouve', (
      tester,
    ) async {
      await startGame(tester);
      await openAsset(tester, 'S&P 500');
      await buyHalf(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1 mois'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton)); // quitter
      await tester.pumpAndSettle();
      expect(traderSaves.saveFor(data.id), isNotNull);
      expect(find.text('Partie en cours'), findsOneWidget);
      expect(find.text('Au 02/02/2018'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Reprendre la partie'), 200);
      await tester.tap(find.text('Reprendre la partie'));
      await tester.pumpAndSettle();
      expect(find.text('vendredi 02/02/2018'), findsOneWidget);
      await tester.tap(find.text('Ordres'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Achat S&P 500'), findsOneWidget);
    });

    testWidgets('nouvelle partie : confirmation, puis la sauvegarde part', (
      tester,
    ) async {
      final played = TraderGameController(data, news)
        ..advanceTo(DateTime.utc(2019, 5, 6));
      await pumpTab(tester);
      await traderSaves.save(played.snapshot(DateTime.utc(2026, 10, 21)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Nouvelle partie'), 200);
      await tester.tap(find.text('Nouvelle partie'));
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle partie ?'), findsOneWidget);
      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();
      expect(traderSaves.saveFor(data.id), isNull);
      expect(find.text('mardi 02/01/2018'), findsOneWidget);
    });
  });

  group('actualités', () {
    testWidgets('au départ : le contexte de fin 2017, non lu', (tester) async {
      await startGame(tester);
      expect(find.textContaining('réforme fiscale'), findsOneWidget); // bandeau
      expect(find.text('2'), findsOneWidget); // badge : 2 non lues

      await tester.tap(find.text('Actus'));
      await tester.pumpAndSettle();
      expect(find.text('Le bitcoin frôle les 20 000 \$'), findsOneWidget);
      expect(find.text('2'), findsNothing); // lues
    });

    testWidgets('une grande nouvelle déclenche un flash info', (tester) async {
      await startGame(tester);
      await tester.tap(find.text('+1 mois')); // 02/02/2018
      await tester.pumpAndSettle();
      expect(find.text('Flash info'), findsNothing); // Coincheck : pas majeur

      await tester.tap(find.text('+7 j')); // passe le 05/02/2018
      await tester.pumpAndSettle();
      expect(find.text('Flash info'), findsOneWidget);
      // Dans la fenêtre du flash (le titre est aussi dans le bandeau).
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('le Dow Jones perd 1'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Reprendre'));
      await tester.pumpAndSettle();
      expect(find.text('Flash info'), findsNothing);
    });

    testWidgets('la fiche d’un actif montre ses actualités', (tester) async {
      await startGame(tester);
      await openAsset(tester, 'Bitcoin');
      await tester.scrollUntilVisible(
        find.text('Actualités liées'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Actualités liées'), findsOneWidget);
    });
  });

  group('bilan', () {
    /// Partie terminée : moitié S&P 500, moitié Bitcoin, gardés 3 ans.
    TraderGame finishedGame() {
      final game = TraderGame(data)
        ..buy('SPY', 5000)
        ..buy('BTC/USD', 5000);
      game.advanceTo(data.end);
      return game;
    }

    Future<TraderAttemptsProvider> pumpDebrief(
      WidgetTester tester,
      TraderGame game, {
      String country = 'FR',
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tax_country': country});
      final settings = SettingsProvider(await SharedPreferences.getInstance());
      final attempts = TraderAttemptsProvider(FakeTraderAttemptDao());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: attempts),
          ],
          child: MaterialApp(
            home: TraderDebriefScreen(game: game, news: news),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return attempts;
    }

    testWidgets('résultat, comparaison, et partie enregistrée', (tester) async {
      final game = finishedGame();
      final attempts = await pumpDebrief(tester, game);
      expect(find.text('Première partie'), findsOneWidget);
      expect(find.text('Tout en S&P 500 dès le départ'), findsOneWidget);
      expect(attempts.count, 1); // enregistrée automatiquement
    });

    testWidgets('les impôts dépendent du pays choisi', (tester) async {
      final game = finishedGame();
      final france = computeAnnualTaxes(
        game.taxableGains(),
        TaxProfile(taxCountryFor('FR')),
      ).totalTax;
      expect(france, greaterThan(0));

      await pumpDebrief(tester, game, country: 'CH');
      await tester.scrollUntilVisible(
        find.textContaining('Impôts au total'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(money(r'Impôts au total : 0,00.\$'), findsOneWidget);
    });

    testWidgets('arrêter une partie en cours mène au bilan', (tester) async {
      await startGame(tester);
      await tester.tap(find.byTooltip('Arrêter et voir le bilan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir le bilan'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PageTitle, 'Bilan de ta partie'),
        findsOneWidget,
      );
      expect(find.textContaining('Arrêtée le 02/01/2018'), findsOneWidget);
    });
  });
}
