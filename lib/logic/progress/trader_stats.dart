import '../../models/past_trader/trader_attempt.dart';

/// Statistiques d'un scénario Past Trader.
class ScenarioStats {
  final String gameId;

  /// Parties de ce scénario, de la plus récente à la plus ancienne.
  final List<TraderAttempt> attempts;

  ScenarioStats(this.gameId, this.attempts);

  int get count => attempts.length;
  int get repeatCount => count - 1;

  /// La toute première partie : jouée sans connaître la suite.
  TraderAttempt get first => attempts.last;
  TraderAttempt get latest => attempts.first;

  TraderAttempt get best =>
      attempts.reduce((a, b) => b.performance > a.performance ? b : a);

  /// Parties ayant fait mieux que le S&P 500 gardé sur la même durée.
  int get beatSpyCount =>
      attempts.where((a) => a.performance > a.spyPerformance).length;

  /// Parties menées jusqu'à la dernière date (pas arrêtées en cours).
  int get fullCount => attempts.where((a) => !a.stoppedEarly).length;
}

/// Regroupe les parties par scénario, le plus récemment joué en premier.
List<ScenarioStats> statsByScenario(List<TraderAttempt> attempts) {
  final groups = <String, List<TraderAttempt>>{};
  for (final a in attempts) {
    groups.putIfAbsent(a.gameId, () => []).add(a);
  }
  return [for (final e in groups.entries) ScenarioStats(e.key, e.value)];
}
