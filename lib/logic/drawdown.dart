import '../models/drawdown.dart';

/// Baisse maximale (« max drawdown ») d'une suite de valeurs.
///
/// Exemple : 100, 150, 90, 200, 180
///   sommet 150, creux 90 : baisse de 40 % (la plus forte)
///   sommet 200, creux 180 : baisse de 10 %
Drawdown maxDrawdown(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('Impossible de calculer une baisse sans valeurs');
  }

  var peakIndex = 0;
  var best = const Drawdown(depth: 0, peakIndex: 0, troughIndex: 0);

  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[peakIndex]) {
      peakIndex = i; // nouveau sommet
      continue;
    }
    final peak = values[peakIndex];
    if (peak <= 0) continue; // évite une division par zéro
    final depth = (peak - values[i]) / peak;
    if (depth > best.depth) {
      best = Drawdown(depth: depth, peakIndex: peakIndex, troughIndex: i);
    }
  }
  return best;
}
