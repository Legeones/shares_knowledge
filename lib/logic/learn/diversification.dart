/// Calculs de la leçon « Diversification » : des paniers d'entreprises
/// imaginaires, du plus concentré au plus diversifié.
library;

import '../drawdown.dart';

/// Une entreprise imaginaire : son rendement année par année.
typedef Company = ({String name, List<double> returns});

/// Huit entreprises sur 10 ans. Fixes (pas de hasard) pour que la leçon et
/// les tests donnent toujours le même résultat. Une fait faillite, une
/// quadruple ; toutes subissent la mauvaise année 3.
const companies = <Company>[
  (
    name: 'Énergie Sud',
    returns: [.06, .08, -.10, .07, .05, .09, -.02, .06, .07, .05],
  ),
  (
    name: 'TechNova',
    returns: [.40, .35, -.45, .60, .30, .25, -.30, .50, .20, .15],
  ),
  (
    name: 'Banque Lumière',
    returns: [.10, .12, -.40, -.10, .15, .20, -.05, .10, .12, .08],
  ),
  (
    name: 'Mode Express',
    returns: [.05, -.20, -.50, -.40, -.60, -1.0, 0, 0, 0, 0],
  ),
  (
    name: 'Santé Plus',
    returns: [.07, .09, -.05, .08, .10, .06, .04, .09, .05, .07],
  ),
  (
    name: 'Rail Europe',
    returns: [.12, -.08, -.20, .18, .04, .10, -.12, .14, .02, .09],
  ),
  (
    name: 'Agro Bio',
    returns: [-.05, .10, -.08, .12, .15, -.10, .20, .05, .10, .06],
  ),
  (
    name: 'Jeux Max',
    returns: [.25, -.15, -.30, .45, -.20, .35, .10, -.25, .40, .15],
  ),
];

/// Valeur année par année de [start] placé avec ces rendements.
List<double> growthPath(List<double> returns, {double start = 100}) {
  final values = [start];
  for (final r in returns) {
    values.add(values.last * (1 + r));
  }
  return values;
}

/// Panier : [capital] partagé à parts égales au départ, sans rééquilibrage.
List<double> basketPath(List<List<double>> returns, {double capital = 100}) {
  final paths = [
    for (final r in returns) growthPath(r, start: capital / returns.length),
  ];
  return [
    for (var t = 0; t < paths.first.length; t++)
      paths.fold(0.0, (sum, p) => sum + p[t]),
  ];
}

/// Toutes les façons de choisir [n] éléments de [items] (sans ordre).
List<List<T>> combinations<T>(List<T> items, int n) {
  if (n == 0) return [[]];
  if (items.length < n) return [];
  final first = items.first;
  final rest = items.sublist(1);
  return [
    for (final c in combinations(rest, n - 1)) [first, ...c],
    ...combinations(rest, n),
  ];
}

/// Ce qui peut arriver avec un panier de [size] entreprises : le meilleur,
/// le pire et la moyenne de tous les paniers possibles.
class BasketRange {
  final List<double> best;
  final List<double> worst;
  final double averageFinal;

  /// La plus forte chute subie par un des paniers possibles.
  final double worstDrawdown;

  /// Nombre de paniers possibles.
  final int count;

  const BasketRange({
    required this.best,
    required this.worst,
    required this.averageFinal,
    required this.worstDrawdown,
    required this.count,
  });
}

BasketRange basketRange(int size, {double capital = 100}) {
  if (size < 1 || size > companies.length) {
    throw ArgumentError('Taille de panier impossible : $size');
  }
  final paths = [
    for (final c in combinations(companies, size))
      basketPath([for (final company in c) company.returns], capital: capital),
  ];
  paths.sort((a, b) => a.last.compareTo(b.last));
  return BasketRange(
    best: paths.last,
    worst: paths.first,
    averageFinal: paths.fold(0.0, (sum, p) => sum + p.last) / paths.length,
    worstDrawdown: paths
        .map((p) => maxDrawdown(p).depth)
        .reduce((a, b) => a > b ? a : b),
    count: paths.length,
  );
}
