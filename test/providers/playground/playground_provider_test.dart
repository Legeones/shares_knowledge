import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/local/price_cache_dao.dart';
import 'package:shares_knowledge/data/repositories/price_repository.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';
import 'package:shares_knowledge/providers/playground/playground_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/fake_market.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const apple = Asset(
  symbol: 'AAPL',
  name: 'Apple',
  currency: 'USD',
  type: AssetType.stock,
);

void main() {
  late FakeMarket market;
  late Database db;
  late PlaygroundProvider provider;

  setUp(() async {
    market = FakeMarket();
    DateTime now() => d(2024, 6, 15);
    db = await inMemoryDatabase();
    final repo = PriceRepository(market.api(now), PriceCacheDao(db), now: now);
    provider = PlaygroundProvider(repo);
  });

  tearDown(() => db.close());

  SimulationParams params({Asset asset = apple, double amount = 1000}) =>
      SimulationParams(
        asset: asset,
        amount: amount,
        start: d(2024, 1, 2), // mardi 2 janvier : cours fictif = 2
        end: d(2024, 1, 31), // mercredi 31 janvier : cours fictif = 31
      );

  test('état initial : rien de lancé', () {
    expect(provider.state, isA<PlaygroundIdle>());
  });

  test('passe par « chargement » puis « succès »', () async {
    final states = <PlaygroundState>[];
    provider.addListener(() => states.add(provider.state));

    await provider.simulate(params());

    expect(states, [isA<PlaygroundLoading>(), isA<PlaygroundSuccess>()]);
    final success = provider.state as PlaygroundSuccess;
    expect(success.result.units, 500); // 1000 / 2
    expect(success.result.finalValue, 15500); // 500 × 31
  });

  test('versements mensuels : un achat par mois', () async {
    await provider.simulate(
      SimulationParams(
        asset: apple,
        amount: 100,
        start: d(2024, 1, 2),
        end: d(2024, 3, 28),
        mode: InvestMode.monthly,
      ),
    );
    final result = (provider.state as PlaygroundSuccess).result;
    // 2 janvier, 2 février, puis lundi 4 mars (le 2 est un samedi).
    expect(result.payments, 3);
    expect(result.totalInvested, 300);
    expect(result.units, closeTo(100 / 2 + 100 / 2 + 100 / 4, 1e-9));
  });

  test('erreur réseau sans cache : état « échec » avec message', () async {
    market.offline = true;
    await provider.simulate(params());

    final failure = provider.state as PlaygroundFailure;
    expect(failure.message, contains('Connexion impossible'));
  });

  test('symbole inconnu : état « échec »', () async {
    const unknown = Asset(
      symbol: 'INCONNU',
      name: 'Inconnu',
      currency: 'USD',
      type: AssetType.stock,
    );
    await provider.simulate(params(asset: unknown));
    expect(provider.state, isA<PlaygroundFailure>());
  });

  test('réessayer après le retour du réseau : succès', () async {
    market.offline = true;
    await provider.simulate(params());
    expect(provider.state, isA<PlaygroundFailure>());

    market.offline = false;
    await provider.retry();
    expect(provider.state, isA<PlaygroundSuccess>());
  });

  group('compteur des nouvelles simulations', () {
    late List<SimulationParams> recorded;
    late PlaygroundProvider counted;

    setUp(() {
      recorded = [];
      DateTime now() => d(2024, 6, 15);
      counted = PlaygroundProvider(
        PriceRepository(market.api(now), PriceCacheDao(db), now: now),
        onNewRunSucceeded: recorded.add,
      );
    });

    test('une simulation du formulaire est comptée', () async {
      await counted.simulate(params());
      expect(recorded, hasLength(1));
    });

    test('rouvrir une sauvegarde n’est pas compté', () async {
      await counted.simulate(params(), isNewRun: false);
      expect(recorded, isEmpty);
    });

    test('un échec n’est pas compté', () async {
      market.offline = true;
      await counted.simulate(params());
      expect(recorded, isEmpty);
    });
  });
}
