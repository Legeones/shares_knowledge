import '../../models/drawdown.dart';
import '../../models/foresight/foresight.dart';
import '../../models/price_point.dart';
import '../drawdown.dart';
import 'inflation.dart';
import '../price_series.dart';
import '../returns.dart';

/// Retraits pour vivre : chaque mois, une part du capital est retirée pour
/// améliorer son quotidien.
///
/// Règle « des 4 % » : 4 % du capital par an (un douzième chaque mois), un
/// rythme souvent cité pour vivre d'un placement sans l'épuiser. Plafonné à
/// un train de vie confortable : [monthlyCapToday] dollars d'aujourd'hui,
/// convertis chaque année avec l'inflation (environ 360 \$ par mois en 1970).
class WithdrawalPlan {
  final double yearlyRate;
  final double monthlyCapToday;

  const WithdrawalPlan({this.yearlyRate = 0.04, required this.monthlyCapToday});

  static const none = WithdrawalPlan(yearlyRate: 0, monthlyCapToday: 0);

  /// 4 % par an, au plus 3 000 \$ d'aujourd'hui par mois.
  static const lifestyle = WithdrawalPlan(monthlyCapToday: 3000);

  bool get isNone => yearlyRate == 0 || monthlyCapToday == 0;

  /// Plafond du mois, en dollars de l'année de [date].
  double capAt(DateTime date) => monthlyCapToday * dollarsOf(date.year);

  /// Montant retiré ce mois-ci pour un capital donné.
  double amountFor(double capital, DateTime date) {
    final amount = capital * yearlyRate / 12;
    final cap = capAt(date);
    return amount < cap ? amount : cap;
  }
}

/// Bilan d'une étape : capital avant / après, impôts et retraits.
class StepResult {
  final ForesightStep step;
  final double capitalBefore;
  final double capitalAfter;
  final double? buyPrice;
  final double? sellPrice;

  /// Impôts payés pendant l'étape (à la vente et sur les retraits).
  final double tax;

  /// Argent retiré pour vivre pendant l'étape (net d'impôt).
  final double withdrawn;

  /// Argent mis à l'abri à l'achat (au-delà de la réserve réinvestie).
  final double sheltered;

  const StepResult({
    required this.step,
    required this.capitalBefore,
    required this.capitalAfter,
    this.buyPrice,
    this.sellPrice,
    this.tax = 0,
    this.withdrawn = 0,
    this.sheltered = 0,
  });

  /// ×20,1 pour GameStop ; 1 pour une étape en cash.
  double get multiplier => buyPrice == null ? 1 : sellPrice! / buyPrice!;
}

/// Un jour du parcours, pour le rejeu.
class ForesightDay {
  final DateTime date;
  final int stepIndex;

  /// Cours de l'actif détenu (dernier connu), null pendant le cash.
  final double? price;
  final double capital;

  /// Totaux depuis le début : retiré pour vivre, impôts payés, mis à l'abri.
  final double withdrawn;
  final double taxPaid;
  final double sheltered;

  const ForesightDay({
    required this.date,
    required this.stepIndex,
    required this.price,
    required this.capital,
    this.withdrawn = 0,
    this.taxPaid = 0,
    this.sheltered = 0,
  });

  /// Patrimoine total : capital investi + mis à l'abri + retiré pour vivre.
  double get wealth => capital + sheltered + withdrawn;
}

/// Calcule le parcours jour par jour à partir du scénario.
///
/// [taxRate] : impôt sur le gain selon la durée de détention (null = sans
/// impôt), prélevé à chaque vente et sur la part de gain de chaque retrait.
/// [withdrawals] : retraits mensuels pour vivre. Impôts et retraits
/// diminuent le capital réinvesti : leur effet se cumule d'étape en étape.
/// [useReserveCaps] : à chaque achat, on ne réinvestit pas plus que la
/// réserve prévue par l'étape ([AssetStep.maxInvest]) ; le surplus est mis à
/// l'abri et ne bouge plus.
class ForesightRun {
  final ForesightScenario scenario;
  final double Function(int holdingDays)? taxRate;
  final WithdrawalPlan withdrawals;
  final bool useReserveCaps;

  /// Vrai : chaque vente a lieu au jour de cotation suivant (« un jour trop
  /// tard »), pour mesurer l'importance d'un timing parfait.
  final bool sellOneDayLater;

  final List<StepResult> steps = [];
  final List<ForesightDay> days = [];

  /// Dernier retrait mensuel (net d'impôt) : le train de vie à la fin.
  double lastMonthlyWithdrawal = 0;

  ForesightRun(
    this.scenario, {
    this.taxRate,
    this.withdrawals = WithdrawalPlan.none,
    this.useReserveCaps = false,
    this.sellOneDayLater = false,
  }) {
    var capital = scenario.initialCapital;
    var withdrawnTotal = 0.0;
    var taxTotal = 0.0;
    var shelteredTotal = 0.0;
    DateTime? previous; // jour précédent, pour repérer un nouveau mois

    // Premier jour d'un nouveau mois (pas le tout premier jour) : retrait.
    bool isWithdrawalDay(DateTime date) =>
        !withdrawals.isNone && previous != null && date.month != previous.month;

    for (final (i, step) in scenario.steps.indexed) {
      final capitalBefore = capital;
      var stepTax = 0.0;
      var stepWithdrawn = 0.0;
      var stepSheltered = 0.0;

      switch (step) {
        case AssetStep():
          // Réserve plafonnée : un portefeuille gigantesque ferait bouger
          // les prix ; le surplus est mis à l'abri.
          final cap = step.maxInvest;
          if (useReserveCaps && cap != null && capital > cap) {
            stepSheltered = capital - cap;
            capital = cap;
          }
          final series = PriceSeries(step.prices);
          final buyPrice = series.lastOnOrBefore(step.buy)!.close;
          final onTime = series.lastOnOrBefore(step.sell)!;
          final sellPrice = sellOneDayLater
              ? (series.firstOnOrAfter(
                          step.sell.add(const Duration(days: 1)),
                        ) ??
                        onTime)
                    .close
              : onTime.close;
          var units = capital / buyPrice;
          var basis = capital; // prix payé pour les parts encore détenues

          for (final date in _daysBetween(step.buy, step.sell)) {
            final price = series.lastOnOrBefore(date)!.close;
            if (isWithdrawalDay(date)) {
              // On vend une fraction des parts : seule la part de gain de
              // cette fraction est imposée.
              final value = units * price;
              final amount = withdrawals.amountFor(value, date);
              final fraction = amount / value;
              final gainPart = amount - basis * fraction;
              final rate = taxRate?.call(date.difference(step.buy).inDays) ?? 0;
              final tax = gainPart > 0 ? gainPart * rate : 0.0;
              units *= 1 - fraction;
              basis *= 1 - fraction;
              stepTax += tax;
              stepWithdrawn += amount - tax;
              lastMonthlyWithdrawal = amount - tax;
            }
            previous = date;
            days.add(
              ForesightDay(
                date: date,
                stepIndex: i,
                price: price,
                capital: units * price,
                withdrawn: withdrawnTotal + stepWithdrawn,
                taxPaid: taxTotal + stepTax,
                sheltered: shelteredTotal + stepSheltered,
              ),
            );
          }

          // Vente : impôt sur le gain des parts restantes.
          final gross = units * sellPrice;
          final saleGain = gross - basis;
          final rate = taxRate?.call(step.holdingDays) ?? 0;
          final saleTax = saleGain > 0 ? saleGain * rate : 0.0;
          stepTax += saleTax;
          capital = gross - saleTax;
          // Le jour de la vente montre déjà le capital après impôt (sinon la
          // baisse n'apparaîtrait que le lendemain).
          final sellDay = days.removeLast();
          days.add(
            ForesightDay(
              date: sellDay.date,
              stepIndex: i,
              price: sellDay.price,
              capital: capital,
              withdrawn: sellDay.withdrawn,
              taxPaid: taxTotal + stepTax,
              sheltered: sellDay.sheltered,
            ),
          );
          steps.add(
            StepResult(
              step: step,
              capitalBefore: capitalBefore,
              capitalAfter: capital,
              buyPrice: buyPrice,
              sellPrice: sellPrice,
              tax: stepTax,
              withdrawn: stepWithdrawn,
              sheltered: stepSheltered,
            ),
          );

        case CashStep():
          for (final date in _daysBetween(step.from, step.to)) {
            if (isWithdrawalDay(date)) {
              // En cash, pas de gain : le retrait n'est pas imposé.
              final amount = withdrawals.amountFor(capital, date);
              capital -= amount;
              stepWithdrawn += amount;
              lastMonthlyWithdrawal = amount;
            }
            previous = date;
            days.add(
              ForesightDay(
                date: date,
                stepIndex: i,
                price: null,
                capital: capital,
                withdrawn: withdrawnTotal + stepWithdrawn,
                taxPaid: taxTotal,
                sheltered: shelteredTotal,
              ),
            );
          }
          steps.add(
            StepResult(
              step: step,
              capitalBefore: capitalBefore,
              capitalAfter: capital,
              withdrawn: stepWithdrawn,
            ),
          );
      }
      withdrawnTotal += stepWithdrawn;
      taxTotal += stepTax;
      shelteredTotal += stepSheltered;

      // Jours entre la vente et l'étape suivante (un week-end, un jour
      // férié) : l'argent attend, sans retrait. Les jours restent ainsi
      // continus, ce dont [indexOf] a besoin.
      if (i + 1 < scenario.steps.length) {
        final next = scenario.steps[i + 1].start;
        final gapStart = step.end.add(const Duration(days: 1));
        for (final date in _daysBetween(gapStart, next)) {
          if (!date.isBefore(dateOnly(next))) break;
          days.add(
            ForesightDay(
              date: date,
              stepIndex: i,
              price: days.last.price,
              capital: capital,
              withdrawn: withdrawnTotal,
              taxPaid: taxTotal,
              sheltered: shelteredTotal,
            ),
          );
        }
      }
    }
  }

  double get finalCapital => steps.last.capitalAfter;
  double get totalTax => steps.fold(0, (sum, s) => sum + s.tax);
  double get totalWithdrawn => steps.fold(0, (sum, s) => sum + s.withdrawn);
  double get totalSheltered => steps.fold(0, (sum, s) => sum + s.sheltered);

  /// Patrimoine final : capital restant + mis à l'abri + retiré pour vivre.
  double get totalWealth => finalCapital + totalSheltered + totalWithdrawn;

  /// Performance du capital restant (sans compter l'argent retiré).
  double get performance =>
      gain(invested: scenario.initialCapital, finalValue: finalCapital) /
      scenario.initialCapital;

  /// Pire chute du capital subie en chemin.
  /// Plus forte baisse du patrimoine : mettre de l'argent à l'abri n'en est
  /// pas une, seules les vraies pertes (cours, impôts) comptent.
  Drawdown get drawdown => maxDrawdown([for (final d in days) d.wealth]);

  /// Position d'une date dans [days] (les jours se suivent sans trou).
  int indexOf(DateTime date) =>
      dateOnly(date)
          .difference(days.first.date)
          .inDays
          .clamp(0, days.length - 1);

  static Iterable<DateTime> _daysBetween(DateTime from, DateTime to) sync* {
    for (
      var d = dateOnly(from);
      !d.isAfter(to);
      d = DateTime.utc(d.year, d.month, d.day + 1)
    ) {
      yield d;
    }
  }
}

/// Le parcours tel qu'il aurait été vécu : impôts à chaque vente, retraits
/// mensuels pour vivre et réserve réinvestie plafonnée.
ForesightRun livedRun(
  ForesightScenario scenario, {
  double Function(int holdingDays)? taxRate,
  bool sellOneDayLater = false,
}) => ForesightRun(
  scenario,
  taxRate: taxRate,
  withdrawals: WithdrawalPlan.lifestyle,
  useReserveCaps: true,
  sellOneDayLater: sellOneDayLater,
);

/// « Et si chaque vente avait eu lieu au jour de cotation suivant ? »
/// Montre à quel point le résultat dépend d'un timing parfait.
double finalCapitalIfSoldOneDayLater(ForesightScenario scenario) {
  var capital = scenario.initialCapital;
  for (final step in scenario.assetSteps) {
    final series = PriceSeries(step.prices);
    final buy = series.lastOnOrBefore(step.buy)!.close;
    final nextDay = series.firstOnOrAfter(
      step.sell.add(const Duration(days: 1)),
    );
    final sell = (nextDay ?? series.lastOnOrBefore(step.sell)!).close;
    capital = capital / buy * sell;
  }
  return capital;
}

/// Lecture automatique : chaque étape reçoit un temps d'écran selon sa
/// durée, pour qu'une étape de trois semaines ne passe pas en un éclair au
/// milieu d'un parcours de 40 ans.
///
/// Au moins 4 s par étape, plus 2,5 s par année détenue, au plus 15 s. À
/// l'intérieur d'une étape, la date avance à vitesse constante.
class PlaybackTimeline {
  /// Premier et dernier jour (positions dans [ForesightRun.days]) de chaque
  /// étape, et son temps d'écran en millisecondes.
  final List<({int first, int last, int ms})> _segments = [];

  PlaybackTimeline(ForesightRun run) {
    final days = run.days;
    var first = 0;
    for (var i = 1; i <= days.length; i++) {
      // Fin d'une étape : dernier jour, ou changement d'étape au jour suivant.
      if (i == days.length || days[i].stepIndex != days[first].stepIndex) {
        final last = i - 1;
        _segments.add((first: first, last: last, ms: stepMillis(last - first)));
        first = i;
      }
    }
  }

  /// Temps d'écran d'une étape de [days] jours.
  static int stepMillis(int days) =>
      ((4 + 2.5 * days / 365).clamp(4, 15) * 1000).round();

  Duration get total =>
      Duration(milliseconds: _segments.fold(0, (sum, s) => sum + s.ms));

  /// Jour affiché après [elapsed] de lecture.
  int dayAt(Duration elapsed) {
    var ms = elapsed.inMilliseconds;
    for (final s in _segments) {
      if (ms <= s.ms) {
        return s.first + ((s.last - s.first) * ms / s.ms).round();
      }
      ms -= s.ms;
    }
    return _segments.last.last;
  }

  /// Moment de la lecture où l'on montre le jour [index] (pour reprendre).
  Duration timeOf(int index) {
    var ms = 0;
    for (final s in _segments) {
      if (index <= s.last) {
        final span = s.last - s.first;
        final part = span == 0 ? 0 : (index - s.first) / span;
        return Duration(milliseconds: ms + (s.ms * part).round());
      }
      ms += s.ms;
    }
    return total;
  }
}
