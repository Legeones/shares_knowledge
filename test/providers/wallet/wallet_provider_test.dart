import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shares_knowledge/screens/playground/playground_screen.dart';
import 'package:shares_knowledge/data/local/app_database.dart';
import 'package:shares_knowledge/data/local/price_cache_dao.dart';
import 'package:shares_knowledge/data/repositories/price_repository.dart';
import 'package:shares_knowledge/data/wallet/wallet_dao.dart';
import 'package:shares_knowledge/models/position_rule.dart';
import 'package:shares_knowledge/models/wallet/wallet.dart';
import 'package:shares_knowledge/providers/wallet/wallet_provider.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/fake_market.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late FakeMarket market;
  late Database db;
  late WalletProvider wallet;
  // L'horloge du test : on la fait avancer pour simuler les jours qui passent.
  var today = d(2024, 6, 17); // lundi

  setUp(() async {
    market = FakeMarket(); // cours = numéro du jour, du lundi au vendredi
    db = await inMemoryDatabase();
    today = d(2024, 6, 17);
    DateTime now() => today;
    wallet = WalletProvider(
      WalletDao(db),
      PriceRepository(market.api(now), PriceCacheDao(db), now: now),
      now: now,
    );
    await wallet.load();
  });
  tearDown(() => db.close());

  test(
    'pas de portefeuille au départ, puis création avec un capital',
    () async {
      expect(wallet.exists, isFalse);
      await wallet.create(1000);
      expect(wallet.exists, isTrue);
      expect(wallet.state.cash, 1000);
      expect(wallet.state.deposited, 1000);
      expect(wallet.transactions.single.source, WalletTxSource.initial);
    },
  );

  test('achat au dernier cours connu, refus sans assez de cash', () async {
    await wallet.create(1000);
    // Le 17 (lundi), le dernier cours connu est celui du vendredi 14.
    expect(await wallet.buy('SPY', 700, name: 'S&P 500'), isNull);
    expect(wallet.state.holdings['SPY']!.units, closeTo(700 / 14, 1e-9));
    expect(wallet.nameOf('SPY'), 'S&P 500');
    expect(wallet.totalValue, closeTo(1000, 1e-9));

    expect(
      await wallet.buy('SPY', 500),
      'Pas assez de cash : dépose de l’argent.',
    );
    expect(await wallet.deposit(500), isNull);
    expect(await wallet.buy('SPY', 500), isNull);
  });

  test(
    'les jours passent : versement mensuel et stop-loss rattrapés',
    () async {
      await wallet.create(1000);
      await wallet.buy('SPY', 500);
      await wallet.setRule(const PositionRule(symbol: 'SPY', stopLoss: 0.5));
      await wallet.addPlan(_qqq, 100, 20);

      // Deux semaines plus tard, l'application est rouverte.
      today = d(2024, 7, 3);
      await wallet.load();

      final auto = wallet.transactions.where(
        (t) =>
            t.source != WalletTxSource.initial &&
            t.source != WalletTxSource.manual,
      );
      expect(
        [for (final t in auto) (t.date, t.source, t.type)],
        [
          (d(2024, 6, 20), WalletTxSource.dca, WalletTxType.deposit),
          (d(2024, 6, 20), WalletTxSource.dca, WalletTxType.buy),
          // SPY acheté à 14 vaut 1 le lundi 1er juillet : −93 %, sous −50 %.
          (d(2024, 7, 1), WalletTxSource.stopLoss, WalletTxType.sell),
        ],
      );
      expect(wallet.state.holdings.keys, ['QQQ']);
      expect(wallet.rules, isEmpty); // la règle a servi
      expect(wallet.plans.single.lastTarget, d(2024, 6, 20));
      expect(wallet.state.deposited, 1100);
    },
  );

  test('rouvrir le même jour ne refait rien', () async {
    await wallet.create(1000);
    await wallet.addPlan(_qqq, 100, 20);
    today = d(2024, 6, 25);
    await wallet.load();
    final count = wallet.transactions.length;
    await wallet.load();
    expect(wallet.transactions, hasLength(count));
  });

  test(
    'hors connexion : le portefeuille reste affiché, rien n’est rattrapé',
    () async {
      await wallet.create(1000);
      await wallet.addPlan(_qqq, 100, 20);
      market.offline = true;
      today = d(2024, 7, 3);
      await wallet.load();
      expect(wallet.exists, isTrue);
      expect(wallet.warning, isNotNull);
      expect(wallet.transactions, hasLength(1)); // seulement le capital
    },
  );

  test('réinitialiser efface tout', () async {
    await wallet.create(1000);
    await wallet.addPlan(_qqq, 100, 20);
    await wallet.reset();
    expect(wallet.exists, isFalse);
    expect(await WalletDao(db).load(), isNull);
  });

  test(
    'migration v3 → v4 : les tables du portefeuille sont ajoutées',
    () async {
      sqfliteFfiInit();
      final factory = databaseFactoryFfiNoIsolate;
      final dir = Directory.systemTemp.createTempSync('sk_wallet');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/test.db';

      final v3 = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) =>
              db.execute('CREATE TABLE trader_attempt (id INTEGER)'),
        ),
      );
      await v3.close();

      final v4 = await AppDatabase.open(path: path, factory: factory);
      expect(await v4.query('wallet_transaction'), isEmpty);
      expect(await WalletDao(v4).load(), isNull);
      await v4.close();
    },
  );

  testWidgets('Playground : « Mon portefeuille », création puis valeur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wallet,
        child: const MaterialApp(home: Scaffold(body: PlaygroundScreen())),
      ),
    );
    await tester.tap(find.text('Mon portefeuille'));
    await tester.pump();
    expect(find.text('Créer mon portefeuille'), findsOneWidget);

    // SQLite travaille vraiment (hors du temps simulé du test) : runAsync.
    await tester.runAsync(() => wallet.create(2500));
    await tester.pump();
    expect(find.textContaining(RegExp(r'2.500,00')), findsWidgets);
    expect(find.text('Cash disponible'), findsOneWidget);
    expect(find.text('Programmer un versement mensuel'), findsOneWidget);
    expect(find.text('Répartition'), findsNothing); // tout en cash

    // Un achat : la répartition et le détail de la position apparaissent.
    await tester.runAsync(() => wallet.buy('SPY', 1000, name: 'S&P 500'));
    await tester.pump();
    expect(find.text('Répartition'), findsOneWidget);
    expect(find.text('60,00 %'), findsOneWidget); // le cash : 1 500 / 2 500

    final position = find.widgetWithText(ListTile, 'S&P 500');
    await tester.ensureVisible(position);
    await tester.pumpAndSettle();
    await tester.tap(position);
    await tester.pumpAndSettle();
    expect(find.text('Stop-loss et objectif'), findsOneWidget);
    expect(find.text('Aucune vente automatique.'), findsOneWidget);
  });
}

const _qqq = Asset(
  symbol: 'QQQ',
  name: 'Nasdaq-100',
  currency: 'USD',
  type: AssetType.etf,
);
