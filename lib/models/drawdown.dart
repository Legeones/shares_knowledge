/// Résultat du calcul de baisse maximale.
class Drawdown {
  final double depth;

  /// Positions (dans la liste) du sommet et du creux, pour les montrer
  /// sur un graphique. Égales s'il n'y a eu aucune baisse.
  final int peakIndex;
  final int troughIndex;

  const Drawdown({
    required this.depth,
    required this.peakIndex,
    required this.troughIndex,
  });
}
