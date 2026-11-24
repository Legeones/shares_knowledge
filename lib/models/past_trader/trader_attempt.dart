/// Une partie Past Trader terminée.
class TraderAttempt {
  final int id;
  final String gameId;
  final DateTime playedAt;
  final DateTime endDate;
  final double finalValue;
  final double performance;
  final double spyPerformance;
  final double maxDrawdown;
  final int tradesCount;
  final bool stoppedEarly;

  /// Vrai si une partie du même jeu avait déjà été jouée avant celle-ci.
  final bool isRepeat;

  const TraderAttempt({
    required this.id,
    required this.gameId,
    required this.playedAt,
    required this.endDate,
    required this.finalValue,
    required this.performance,
    required this.spyPerformance,
    required this.maxDrawdown,
    required this.tradesCount,
    required this.stoppedEarly,
    required this.isRepeat,
  });
}
