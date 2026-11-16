import '../../models/price_point.dart';
import '../../models/simulation.dart';
import '../drawdown.dart';
import '../price_series.dart';
import '../time_cursor.dart';
import '../returns.dart';

/// Erreur prévue, avec un message destiné à l'utilisateur.
class SimulationException implements Exception {
  final String message;
  const SimulationException(this.message);

  @override
  String toString() => message;
}

/// Simule la façon d'investir choisie dans [params].
SimulationResult runSimulation(SimulationParams params, PriceSeries series) =>
    params.isMonthly
    ? simulateMonthly(params, series)
    : simulateLumpSum(params, series);

/// Simule un investissement unique au début de la période.
///
/// Hypothèses (à afficher avec le résultat) :
/// - achat au cours de clôture du premier jour de cotation à partir du début ;
/// - valeur finale au cours de clôture du dernier jour de cotation avant la fin ;
/// - pas de frais, pas de dividendes, montant dans la devise de l'actif ;
/// - quantité fractionnaire autorisée (on peut acheter 0,37 action).
SimulationResult simulateLumpSum(SimulationParams params, PriceSeries series) {
  _checkParams(params);

  final buy = series.firstOnOrAfter(params.start);
  final sell = series.lastOnOrBefore(params.end);

  // Aucun cours dans la période : ne surtout pas afficher un résultat calculé
  // sur une autre période sans le dire.
  if (buy == null || sell == null || buy.date.isAfter(sell.date)) {
    throw const SimulationException(
      'Aucun cours disponible sur cette période. Essaie d’autres dates.',
    );
  }
  if (buy.close <= 0) {
    throw const SimulationException('Cours d’achat invalide dans les données.');
  }

  final units = params.amount / buy.close;

  final history = [
    for (final PricePoint p in series.between(buy.date, sell.date))
      ValuePoint(
        date: p.date,
        price: p.close,
        value: units * p.close,
        invested: params.amount,
      ),
  ];

  final finalValue = units * sell.close;

  return SimulationResult(
    params: params,
    actualStart: buy.date,
    actualEnd: sell.date,
    units: units,
    payments: 1,
    totalInvested: params.amount,
    finalValue: finalValue,
    gain: gain(invested: params.amount, finalValue: finalValue),
    performance: performance(invested: params.amount, finalValue: finalValue),
    drawdown: maxDrawdown([for (final v in history) v.value]),
    history: history,
  );
}

/// Simule des versements mensuels (DCA) : [SimulationParams.amount] chaque
/// mois, au premier jour de bourse à partir du même jour du mois que le
/// début (le 31 devient le 30 ou le 28 si le mois est plus court).
///
/// La baisse maximale est celle du cours : la valeur du portefeuille
/// monte aussi à chaque versement, ce qui masquerait les chutes.
SimulationResult simulateMonthly(SimulationParams params, PriceSeries series) {
  _checkParams(params);

  final first = series.firstOnOrAfter(params.start);
  final sell = series.lastOnOrBefore(params.end);
  if (first == null || sell == null || first.date.isAfter(sell.date)) {
    throw const SimulationException(
      'Aucun cours disponible sur cette période. Essaie d’autres dates.',
    );
  }

  // Jours de bourse des versements, jusqu'à la date de fin.
  final buyDays = <DateTime>{};
  for (var k = 0; ; k++) {
    final target = addMonths(dateOnly(params.start), k);
    final day = series.firstOnOrAfter(target);
    if (day == null || day.date.isAfter(sell.date)) break;
    buyDays.add(day.date);
  }

  var units = 0.0;
  var invested = 0.0;
  final history = <ValuePoint>[];
  for (final p in series.between(first.date, sell.date)) {
    if (p.close <= 0) {
      throw const SimulationException('Cours invalide dans les données.');
    }
    if (buyDays.contains(p.date)) {
      // Même somme chaque mois : plus de parts quand le cours est bas.
      units += params.amount / p.close;
      invested += params.amount;
    }
    history.add(
      ValuePoint(
        date: p.date,
        price: p.close,
        value: units * p.close,
        invested: invested,
      ),
    );
  }

  final finalValue = units * sell.close;
  return SimulationResult(
    params: params,
    actualStart: first.date,
    actualEnd: sell.date,
    units: units,
    payments: buyDays.length,
    totalInvested: invested,
    finalValue: finalValue,
    gain: gain(invested: invested, finalValue: finalValue),
    performance: performance(invested: invested, finalValue: finalValue),
    drawdown: maxDrawdown([for (final v in history) v.price]),
    history: history,
  );
}

void _checkParams(SimulationParams params) {
  if (params.amount <= 0) {
    throw const SimulationException('Le montant doit être supérieur à 0.');
  }
  if (!params.start.isBefore(params.end)) {
    throw const SimulationException(
      'La date de début doit être avant la date de fin.',
    );
  }
}
