/// Calculs des leçons sur le risque : volatilité et baisse maximale.
library;

import 'dart:math';

/// Rendements d'une période à l'autre : 100, 110, 99 donne +10 %, −10 %.
List<double> periodReturns(List<double> values) => [
  for (var i = 1; i < values.length; i++) values[i] / values[i - 1] - 1,
];

/// Volatilité : l'écart type des rendements, c'est-à-dire leur écart moyen
/// autour de leur moyenne. 0 = une progression parfaitement régulière.
double volatility(List<double> values) {
  final returns = periodReturns(values);
  if (returns.length < 2) return 0;
  final mean = returns.reduce((a, b) => a + b) / returns.length;
  final variance =
      returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
      (returns.length - 1);
  return sqrt(variance);
}

/// Pire rendement d'une période (la plus mauvaise année).
double worstReturn(List<double> values) => periodReturns(values).reduce(min);

/// Écarts fixes autour d'une progression régulière : les « secousses » du
/// parcours agité.
const _shocks = [0.0, 0.9, -0.5, 1.2, -1.1, 0.4, -1.4, 0.7, -0.3, 0.6, 0.0];

/// Valeur année par année d'un placement qui passe de [start] à [end] en 10
/// ans.
List<double> pathWithVolatility({
  required double start,
  required double end,
  required double amplitude,
}) {
  final years = _shocks.length - 1;
  // En logarithme, une progression régulière est une droite : on lui ajoute
  // les secousses, nulles aux deux bouts.
  final growth = log(end / start) / years;
  return [
    for (var k = 0; k <= years; k++)
      start * exp(growth * k + amplitude * _shocks[k]),
  ];
}

/// Gain nécessaire pour revenir au départ après une perte de [loss]
/// (0,5 = −50 %) : il faut +100 %, pas +50 %.
double recoveryGain(double loss) {
  if (loss < 0 || loss >= 1) {
    throw ArgumentError('La perte doit être entre 0 et 1 (exclu) : $loss');
  }
  return 1 / (1 - loss) - 1;
}

/// Années pour revenir au départ après une perte de [loss], si le placement
/// rapporte ensuite [annualRate] par an. null si le taux est nul ou négatif.
double? yearsToRecover(double loss, double annualRate) {
  if (annualRate <= 0) return null;
  return log(1 + recoveryGain(loss)) / log(1 + annualRate);
}

/// Une valeur par année : celle de chaque date anniversaire du premier jour
/// (le dernier cours connu ce jour-là). Les années incomplètes sont ignorées.
List<double> yearlyValues(List<DateTime> dates, List<double> values) {
  final result = <double>[];
  final first = dates.first;
  var i = 0;
  for (var k = 0; ; k++) {
    final anniversary = DateTime.utc(first.year + k, first.month, first.day);
    if (anniversary.isAfter(dates.last)) break;
    while (i + 1 < dates.length && !dates[i + 1].isAfter(anniversary)) {
      i++;
    }
    result.add(values[i]);
  }
  return result;
}
