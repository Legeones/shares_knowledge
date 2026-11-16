import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/api/api_exceptions.dart';
import 'package:shares_knowledge/data/local/price_cache_dao.dart';
import 'package:shares_knowledge/data/repositories/price_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_market.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late FakeMarket market;
  late PriceRepository repo;
  late DateTime today;
  late Database db;

  setUp(() async {
    market = FakeMarket();
    today = d(2024, 6, 15);
    // L'horloge lit la variable `today` : un test peut avancer le temps.
    DateTime now() => today;
    db = await inMemoryDatabase();
    repo = PriceRepository(market.api(now), PriceCacheDao(db), now: now);
  });

  tearDown(() => db.close());

  Future<PriceData> get(DateTime start, DateTime end, [String s = 'AAPL']) =>
      repo.getDailySeries(s, start: start, end: end);

  test(
    '1er appel : téléchargement ; 2e appel identique : cache seul',
    () async {
      final first = await get(d(2024, 1, 1), d(2024, 1, 31));
      expect(market.requests, hasLength(1));
      expect(first.series.points, hasLength(23)); // jours de semaine de janvier

      final second = await get(d(2024, 1, 1), d(2024, 1, 31));
      expect(market.requests, hasLength(1)); // aucune nouvelle requête
      expect(second.series.points, hasLength(23));
      expect(second.isFallback, isFalse);
    },
  );

  test('une sous-période déjà couverte ne déclenche aucune requête', () async {
    await get(d(2024, 1, 1), d(2024, 3, 31));
    final r = await get(d(2024, 2, 1), d(2024, 2, 29));
    expect(market.requests, hasLength(1));
    expect(r.series.firstDate, d(2024, 2, 1));
    expect(r.series.lastDate, d(2024, 2, 29));
  });

  test('ne télécharge que les jours manquants', () async {
    await get(d(2024, 1, 1), d(2024, 1, 31));
    await get(d(2024, 1, 1), d(2024, 2, 29));

    expect(market.requests, hasLength(2));
    final second = market.requests.last.queryParameters;
    expect(second['start_date'], '2024-02-01'); // seulement février
    expect(second['end_date'], '2024-02-29');
  });

  test('complète aussi avant la période en cache', () async {
    await get(d(2024, 2, 1), d(2024, 2, 29));
    final r = await get(d(2024, 1, 1), d(2024, 2, 29));

    final second = market.requests.last.queryParameters;
    expect(second['start_date'], '2024-01-01');
    expect(second['end_date'], '2024-01-31');
    expect(r.series.firstDate, d(2024, 1, 1));
  });

  test('ne demande jamais le cours du jour (incomplet)', () async {
    final r = await get(d(2024, 6, 1), d(2024, 12, 31));
    expect(market.requests.single.queryParameters['end_date'], '2024-06-14');
    expect(r.series.lastDate, d(2024, 6, 14));
  });

  test('le lendemain, seul le nouveau jour est demandé', () async {
    await get(d(2024, 6, 1), d(2024, 6, 14)); // aujourd'hui = 15 (samedi)
    today = d(2024, 6, 18); // on revient le mardi
    await get(d(2024, 6, 1), d(2024, 6, 30));

    final second = market.requests.last.queryParameters;
    expect(second['start_date'], '2024-06-15');
    expect(second['end_date'], '2024-06-17');
  });

  test('un trou sans cotation (week-end) n’est pas une erreur', () async {
    await get(d(2024, 6, 3), d(2024, 6, 7)); // lundi → vendredi
    final r = await get(d(2024, 6, 3), d(2024, 6, 9)); // + samedi, dimanche
    expect(r.series.lastDate, d(2024, 6, 7));
    // Une 3e demande ne redemande pas le week-end : il est noté comme couvert.
    await get(d(2024, 6, 3), d(2024, 6, 9));
    expect(market.requests, hasLength(2));
  });

  test('date du dernier téléchargement conservée', () async {
    final r = await get(d(2024, 1, 1), d(2024, 1, 31));
    expect(r.updatedAt, today);
  });

  group('sans réseau', () {
    test('avec cache : données du cache, signalées comme telles', () async {
      await get(d(2024, 1, 1), d(2024, 1, 31));
      market.offline = true;

      final r = await get(d(2024, 1, 1), d(2024, 2, 29));
      expect(r.isFallback, isTrue);
      expect(r.fallbackReason, isA<NetworkException>());
      expect(r.series.lastDate, d(2024, 1, 31)); // seulement janvier
    });

    test('déjà tout en cache : aucune différence, aucun signalement', () async {
      await get(d(2024, 1, 1), d(2024, 1, 31));
      market.offline = true;

      final r = await get(d(2024, 1, 1), d(2024, 1, 31));
      expect(r.isFallback, isFalse);
    });

    test('sans cache : erreur réseau transmise à l’écran', () async {
      market.offline = true;
      expect(
        get(d(2024, 1, 1), d(2024, 1, 31)),
        throwsA(isA<NetworkException>()),
      );
    });

    test('quota dépassé : même comportement que hors connexion', () async {
      await get(d(2024, 1, 1), d(2024, 1, 31));
      market.quotaExceeded = true;

      final r = await get(d(2024, 1, 1), d(2024, 2, 29));
      expect(r.isFallback, isTrue);
      expect(r.fallbackReason, isA<QuotaExceededException>());
    });
  });

  test('symbole inconnu : erreur transmise', () {
    expect(
      get(d(2024, 1, 1), d(2024, 1, 31), 'INCONNU'),
      throwsA(isA<NoDataException>()),
    );
  });

  test('période entièrement dans le futur : erreur, sans requête', () async {
    await expectLater(
      get(d(2024, 7, 1), d(2024, 8, 1)),
      throwsA(isA<NoDataException>()),
    );
    expect(market.requests, isEmpty);
  });
}
