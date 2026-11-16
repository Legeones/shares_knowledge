/// Investir en une fois ou par petits versements réguliers (DCA).
library;

/// Résultat d'une façon d'investir sur une suite de prix.
class InvestmentResult {
  /// Somme versée au total.
  final double invested;

  /// Parts achetées au total.
  final double units;

  /// Valeur à chaque période, après l'achat de cette période : les parts,
  /// plus l'argent pas encore versé (gardé de côté, sans rapporter).
  final List<double> values;

  const InvestmentResult({
    required this.invested,
    required this.units,
    required this.values,
  });

  /// Prix moyen payé par part.
  double get averageCost => invested / units;

  double get finalValue => values.last;
}

/// Tout investir ([amount]) au premier prix, puis attendre.
InvestmentResult lumpSum(List<double> prices, double amount) {
  _check(prices);
  final units = amount / prices.first;
  return InvestmentResult(
    invested: amount,
    units: units,
    values: [for (final p in prices) units * p],
  );
}

/// Verser [perPeriod] à chacune des [periods] premières périodes (DCA),
/// puis attendre jusqu'au dernier prix.
InvestmentResult regularInvestment(
  List<double> prices,
  double perPeriod,
  int periods,
) {
  _check(prices);
  if (periods < 1 || periods > prices.length) {
    throw ArgumentError('Nombre de versements impossible : $periods');
  }
  var units = 0.0;
  final values = <double>[];
  for (var i = 0; i < prices.length; i++) {
    // Même somme à chaque fois : plus de parts quand le prix est bas.
    if (i < periods) units += perPeriod / prices[i];
    final waiting = perPeriod * (periods - i - 1).clamp(0, periods);
    values.add(units * prices[i] + waiting);
  }
  return InvestmentResult(
    invested: perPeriod * periods,
    units: units,
    values: values,
  );
}

void _check(List<double> prices) {
  if (prices.isEmpty || prices.any((p) => p <= 0)) {
    throw ArgumentError('Les prix doivent être positifs.');
  }
}
