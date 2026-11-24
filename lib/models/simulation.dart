import 'asset.dart';
import 'drawdown.dart';
import 'price_point.dart';

/// Façon d'investir : tout au début, ou la même somme chaque mois (DCA).
enum InvestMode { lumpSum, monthly }

/// Ce que l'utilisateur a demandé dans le formulaire du Playground.
class SimulationParams {
  final Asset asset;

  /// Somme placée au début, ou versée chaque mois en mode [InvestMode.monthly].
  final double amount;
  final DateTime start;
  final DateTime end;
  final InvestMode mode;

  const SimulationParams({
    required this.asset,
    required this.amount,
    required this.start,
    required this.end,
    this.mode = InvestMode.lumpSum,
  });

  bool get isMonthly => mode == InvestMode.monthly;

  /// Sert à mémoriser une simulation (sauvegarde, « reprendre »).
  Map<String, dynamic> toJson() => {
    'asset': asset.toJson(),
    'amount': amount,
    'start': _day(start),
    'end': _day(end),
    'mode': mode.name,
  };

  factory SimulationParams.fromJson(Map<String, dynamic> json) {
    return SimulationParams(
      asset: Asset.fromJson(json['asset'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      start: dateOnly(DateTime.parse(json['start'] as String)),
      end: dateOnly(DateTime.parse(json['end'] as String)),
      // Absent des sauvegardes d'avant le DCA : achat unique.
      mode: json['mode'] == 'monthly' ? InvestMode.monthly : InvestMode.lumpSum,
    );
  }

  static String _day(DateTime d) =>
      dateOnly(d).toIso8601String().substring(0, 10);
}

/// Valeur du portefeuille simulé à une date (un point de la courbe).
class ValuePoint {
  final DateTime date;
  final double price; // cours de l'actif ce jour-là
  final double value; // quantité détenue × cours
  final double invested; // somme versée jusqu'à ce jour

  const ValuePoint({
    required this.date,
    required this.price,
    required this.value,
    required this.invested,
  });
}

/// Tout ce que l'écran de résultat doit afficher.
class SimulationResult {
  final SimulationParams params;

  /// Dates réellement utilisées : elles peuvent différer de celles demandées
  /// si le marché était fermé (week-end, jour férié). L'écran doit le signaler.
  final DateTime actualStart;
  final DateTime actualEnd;

  final double units; // quantité achetée (peut être fractionnaire)
  final int payments; // nombre de versements (1 pour un achat unique)
  final double totalInvested;
  final double finalValue;
  final double gain; // en devise de l'actif, négatif = perte
  final double performance; // 0.25 = +25 %
  /// Baisse maximale, avec la position du sommet et du creux dans [history]
  /// pour pouvoir les marquer sur le graphique.
  final Drawdown drawdown;
  final List<ValuePoint> history;

  const SimulationResult({
    required this.params,
    required this.actualStart,
    required this.actualEnd,
    required this.units,
    required this.payments,
    required this.totalInvested,
    required this.finalValue,
    required this.gain,
    required this.performance,
    required this.drawdown,
    required this.history,
  });

  /// Prix moyen payé par part.
  double get averageCost => totalInvested / units;

  /// Valeur finale si tout avait été placé au premier jour (comparaison
  /// avec les versements mensuels).
  double get lumpSumFinalValue =>
      totalInvested / history.first.price * history.last.price;

  /// Ampleur de la baisse maximale : 0.30 = −30 %.
  double get maxDrawdown => drawdown.depth;

  /// Vrai si les dates utilisées ne sont pas exactement celles demandées.
  bool get periodWasAdjusted =>
      actualStart != dateOnly(params.start) ||
      actualEnd != dateOnly(params.end);
}
