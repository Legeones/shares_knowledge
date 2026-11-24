import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/progress/trader_stats.dart';
import 'package:shares_knowledge/models/past_trader/trader_attempt.dart';

import '../helpers.dart';

var _nextId = 1;

TraderAttempt attempt(
  String game,
  double perf, {
  double spy = 0.2,
  bool early = false,
}) => TraderAttempt(
  id: _nextId++,
  gameId: game,
  playedAt: d(2026, 10, 6),
  endDate: d(2020, 12, 31),
  finalValue: 10000 * (1 + perf),
  performance: perf,
  spyPerformance: spy,
  maxDrawdown: 0.3,
  tradesCount: 4,
  stoppedEarly: early,
  isRepeat: false,
);

void main() {
  test('aucune partie : aucune statistique', () {
    expect(statsByScenario([]), isEmpty);
  });

  test('regroupe par scénario, le plus récent en premier', () {
    // Ordre du DAO : la plus récente d'abord.
    final stats = statsByScenario([
      attempt('b', 0.1),
      attempt('a', 0.3),
      attempt('a', -0.1),
    ]);
    expect(stats.map((s) => s.gameId), ['b', 'a']);
    expect(stats[1].count, 2);
    expect(stats[1].repeatCount, 1);
  });

  test('première, dernière et meilleure partie', () {
    final first = attempt('a', -0.1);
    final best = attempt('a', 0.5);
    final latest = attempt('a', 0.2);
    final s = statsByScenario([latest, best, first]).single;
    expect(s.first, same(first));
    expect(s.latest, same(latest));
    expect(s.best, same(best));
  });

  test('parties ayant battu le S&P 500, parties menées au bout', () {
    final s = statsByScenario([
      attempt('a', 0.5, spy: 0.4),
      attempt('a', 0.1, spy: 0.4, early: true),
      attempt('a', 0.4, spy: 0.4), // égalité : pas « mieux »
    ]).single;
    expect(s.beatSpyCount, 1);
    expect(s.fullCount, 2);
  });
}
