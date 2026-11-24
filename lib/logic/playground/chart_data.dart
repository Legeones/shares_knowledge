import 'dart:math';

import '../../models/simulation.dart';

/// Ce que montre le graphique.
enum ChartMode {
  /// Valeur du portefeuille simulé (quantité × cours).
  value,

  /// Cours de l'actif.
  price,
}

/// Un point prêt à dessiner.
class ChartPoint {
  final double x;
  final double y;
  final DateTime date;
  const ChartPoint(this.x, this.y, this.date);
}

/// Transforme l'historique de la simulation en points de graphique.
List<ChartPoint> chartPoints(List<ValuePoint> history, ChartMode mode) {
  if (history.isEmpty) return [];
  final first = history.first.date;
  return [
    for (final p in history)
      ChartPoint(
        p.date.difference(first).inDays.toDouble(),
        mode == ChartMode.value ? p.value : p.price,
        p.date,
      ),
  ];
}

/// Bornes verticales du graphique, avec une marge de 5 % pour que la courbe
/// ne touche pas les bords.
({double minY, double maxY}) verticalBounds(
  List<ChartPoint> points, {
  double? alsoInclude,
}) {
  var low = points.map((p) => p.y).reduce(min);
  var high = points.map((p) => p.y).reduce(max);
  // Permet de garder la ligne du portefeuille sur le graphique.
  if (alsoInclude != null) {
    low = min(low, alsoInclude);
    high = max(high, alsoInclude);
  }
  final margin = (high - low) * 0.05;
  // Courbe plate (une seule valeur) : on invente une petite hauteur.
  if (margin == 0) return (minY: low * 0.95, maxY: high * 1.05 + 1);
  return (minY: max(0, low - margin), maxY: high + margin);
}

/// Écart entre deux dates affichées sous l'axe : environ 4 étiquettes.
double bottomLabelInterval(List<ChartPoint> points) {
  if (points.length < 2) return 1;
  return max(1, (points.last.x - points.first.x) / 4);
}
