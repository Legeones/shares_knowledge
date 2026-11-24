/// Ce qui a déclenché une vente automatique.
enum RuleTrigger {
  stopLoss('Stop-loss'),
  takeProfit('Objectif atteint');

  final String label;
  const RuleTrigger(this.label);
}

/// Ventes automatiques d'une position, par rapport à son prix moyen d'achat :
/// [stopLoss] 0,2 = tout vendre si le cours perd 20 % ; [takeProfit] 0,5 = tout
/// vendre s'il gagne 50 %.
class PositionRule {
  final String symbol;
  final double? stopLoss;
  final double? takeProfit;

  const PositionRule({required this.symbol, this.stopLoss, this.takeProfit});

  bool get isEmpty => stopLoss == null && takeProfit == null;

  /// La règle se déclenche-t-elle à ce cours de clôture ? null sinon.
  RuleTrigger? triggerAt({
    required double averagePrice,
    required double close,
  }) {
    final change = close / averagePrice - 1;
    return switch ((stopLoss, takeProfit)) {
      (final s?, _) when change <= -s => RuleTrigger.stopLoss,
      (_, final t?) when change >= t => RuleTrigger.takeProfit,
      _ => null,
    };
  }

  Map<String, Object?> toRow() => {
    'symbol': symbol,
    'stop_loss': stopLoss,
    'take_profit': takeProfit,
  };

  factory PositionRule.fromRow(Map<String, Object?> row) => PositionRule(
    symbol: row['symbol'] as String,
    stopLoss: (row['stop_loss'] as num?)?.toDouble(),
    takeProfit: (row['take_profit'] as num?)?.toDouble(),
  );
}
