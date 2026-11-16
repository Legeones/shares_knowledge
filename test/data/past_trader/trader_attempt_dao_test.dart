import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/past_trader/trader_attempt_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../logic/helpers.dart';
import '../fake_market.dart';

void main() {
  late Database db;
  late TraderAttemptDao dao;

  setUp(() async {
    db = await inMemoryDatabase();
    dao = TraderAttemptDao(db);
  });
  tearDown(() => db.close());

  Future<void> add(String game, DateTime when, {bool early = false}) =>
      dao.insert(
        gameId: game,
        playedAt: when,
        endDate: d(2020, 12, 31),
        finalValue: 12000,
        performance: 0.2,
        spyPerformance: 0.45,
        maxDrawdown: 0.3,
        tradesCount: 7,
        stoppedEarly: early,
      );

  test('enregistrer puis relire une partie', () async {
    await add('jeu', DateTime(2026, 10, 6), early: true);
    final a = (await dao.getAll()).single;
    expect(a.gameId, 'jeu');
    expect(a.performance, 0.2);
    expect(a.tradesCount, 7);
    expect(a.stoppedEarly, isTrue);
    expect(a.isRepeat, isFalse);
  });

  test('la 2e partie d’un même jeu est une répétition', () async {
    await add('jeu', DateTime(2026, 10, 6));
    await add('autre', DateTime(2026, 10, 7));
    await add('jeu', DateTime(2026, 10, 8));
    final all = await dao.getAll(); // la plus récente en premier
    expect(all.map((a) => a.isRepeat), [true, false, false]);
  });

  test('tout supprimer', () async {
    await add('jeu', DateTime(2026, 10, 6));
    await dao.deleteAll();
    expect(await dao.getAll(), isEmpty);
  });
}
