/// Impôts simplifiés sur les plus-values d'un particulier, pour illustrer
/// leur effet. Taux de la période 2018-2025. Ce n'est pas un conseil fiscal.
library;

/// Une plus-value (ou moins-value) à déclarer.
typedef TaxableGain = ({DateTime date, double gain, int holdingDays});

/// Les revenus du foyer, qui fixent le taux marginal dans certains pays.
enum IncomeLevel {
  modest('Modestes'),
  middle('Moyens'),
  high('Élevés');

  final String label;
  const IncomeLevel(this.label);
}

/// Un État américain : taux sur les plus-values selon les revenus
/// (modestes, moyens, élevés). Le Massachusetts taxe différemment les
/// gains à long terme.
class UsState {
  final String name;
  final List<double> rates;
  final double? longTermRate;

  const UsState(this.name, this.rates, {this.longTermRate});

  double rateFor(IncomeLevel income, {required bool longTerm}) =>
      longTerm && longTermRate != null ? longTermRate! : rates[income.index];
}

const usStates = [
  UsState('Californie', [0.04, 0.093, 0.133]),
  UsState('New York', [0.059, 0.0633, 0.0882]),
  UsState('New Jersey', [0.05525, 0.0637, 0.1075]),
  UsState('Massachusetts', [0.12, 0.12, 0.12], longTermRate: 0.05),
  UsState('Illinois', [0.0495, 0.0495, 0.0495]),
  UsState('Texas', [0, 0, 0]),
  UsState('Floride', [0, 0, 0]),
  UsState('Washington', [0, 0, 0]),
];

class TaxCountry {
  final String name;
  final String code; // code ISO, pour présélectionner le pays du téléphone
  final bool dependsOnIncome;
  final bool hasStates;

  const TaxCountry(
    this.name,
    this.code, {
    this.dependsOnIncome = false,
    this.hasStates = false,
  });
}

const taxCountries = [
  TaxCountry('France', 'FR'),
  TaxCountry('Belgique', 'BE'),
  TaxCountry('Suisse', 'CH'),
  TaxCountry('Canada', 'CA', dependsOnIncome: true),
  TaxCountry('États-Unis', 'US', dependsOnIncome: true, hasStates: true),
];

/// Pays de [code], ou la France par défaut.
TaxCountry taxCountryFor(String? code) => taxCountries.firstWhere(
  (c) => c.code == code,
  orElse: () => taxCountries.first,
);

/// Situation fiscale : pays, État (États-Unis) et revenus.
class TaxProfile {
  final TaxCountry country;
  final UsState? state;
  final IncomeLevel income;

  const TaxProfile(
    this.country, {
    this.state,
    this.income = IncomeLevel.middle,
  });

  /// Plus d'un an de détention = « long terme » (taux réduit aux États-Unis).
  static bool isLongTerm(int holdingDays) => holdingDays > 365;

  /// Taux appliqué au gain d'une vente.
  double rateFor(int holdingDays) {
    final longTerm = isLongTerm(holdingDays);
    return switch (country.code) {
      'FR' => 0.30,
      'BE' || 'CH' => 0,
      // La moitié du gain est imposée au taux marginal (≈ 20 / 30 / 53 %).
      'CA' => const [0.10, 0.15, 0.267][income.index],
      'US' =>
        (longTerm
                ? const [0.0, 0.15, 0.238]
                : const [0.12, 0.22, 0.408])[income.index] +
            (state?.rateFor(income, longTerm: longTerm) ?? 0),
      _ => 0,
    };
  }

  /// Résumé en une ligne : « États-Unis · Californie · revenus moyens ».
  String get summary => [
    country.name,
    if (state != null) state!.name,
    if (country.dependsOnIncome) 'revenus ${income.label.toLowerCase()}',
  ].join(' · ');

  String get explanation => switch (country.code) {
    'FR' =>
      'Prélèvement forfaitaire unique de 30 % sur les gains nets de l’année '
          '(12,8 % d’impôt + 17,2 % de prélèvements sociaux).',
    'BE' =>
      'Plus-values d’un particulier non imposées en « gestion normale » du '
          'patrimoine. Des achats-ventes très spéculatifs peuvent toutefois être '
          'taxés jusqu’à 33 %.',
    'CH' =>
      'Plus-values privées non imposées. Une activité très intense peut faire '
          'qualifier l’investisseur de « commerçant professionnel », imposé sur '
          'le revenu.',
    'CA' =>
      'La moitié du gain est ajoutée au revenu, imposée au taux marginal '
          '(fédéral + province) : environ ${_pct(rateFor(0))} du gain avec des '
          'revenus ${income.label.toLowerCase()}.',
    'US' =>
      'Impôt fédéral : ${_pct(rateFor(0) - _state(false))} si l’actif est gardé '
          'un an ou moins, ${_pct(rateFor(400) - _state(true))} au-delà, avec des '
          'revenus ${income.label.toLowerCase()}'
          '${state == null ? '' : ', plus ${state!.name} : ${_pct(_state(false))}'
                    '${state!.longTermRate != null ? ' (${_pct(_state(true))} à long terme)' : ''}'}.',
    _ => '',
  };

  double _state(bool longTerm) =>
      state?.rateFor(income, longTerm: longTerm) ?? 0;

  static String _pct(double r) =>
      '${(r * 100).toStringAsFixed(r * 100 % 1 == 0 ? 0 : 1).replaceAll('.', ',')} %';
}

/// Gain après impôt : seul un gain positif est taxé.
double gainAfterTax(double gain, double rate) =>
    gain > 0 ? gain * (1 - rate) : gain;

/// Bilan fiscal d'une année.
class TaxYear {
  final int year;
  final double netGain; // gains − pertes de l'année
  final double taxable; // après compensation et report des pertes passées
  final double tax;

  const TaxYear(this.year, this.netGain, this.taxable, this.tax);
}

class TaxReport {
  final List<TaxYear> years;

  /// Pertes non encore compensées à la fin (reportables sur les années futures).
  final double lossCarriedForward;

  const TaxReport(this.years, this.lossCarriedForward);

  double get totalTax => years.fold(0, (s, y) => s + y.tax);
}

/// Impôt année par année :
/// - dans une année, pertes et gains se compensent ;
/// - une perte nette est reportée sur les années suivantes ;
/// - court terme et long terme gardent leur propre taux (États-Unis).
TaxReport computeAnnualTaxes(List<TaxableGain> gains, TaxProfile profile) {
  final years = <int, ({double short, double long})>{};
  for (final g in gains) {
    final y = years[g.date.year] ?? (short: 0.0, long: 0.0);
    years[g.date.year] = TaxProfile.isLongTerm(g.holdingDays)
        ? (short: y.short, long: y.long + g.gain)
        : (short: y.short + g.gain, long: y.long);
  }

  var carried = 0.0; // pertes reportées (≤ 0)
  final out = <TaxYear>[];
  for (final year in years.keys.toList()..sort()) {
    var (short: st, long: lt) = years[year]!;
    final net = st + lt;
    if (net + carried <= 0) {
      // Rien à taxer : la perte (ou ce qu'il en reste) est reportée.
      carried = net + carried < 0 ? net + carried : 0;
      out.add(TaxYear(year, net, 0, 0));
      continue;
    }
    // Compensation à l'intérieur de l'année, puis avec les pertes passées.
    if (st < 0) (lt, st) = (lt + st, 0);
    if (lt < 0) (st, lt) = (st + lt, 0);
    st += carried;
    if (st < 0) (lt, st) = (lt + st, 0);
    carried = 0;
    final tax = st * profile.rateFor(0) + lt * profile.rateFor(400);
    out.add(TaxYear(year, net, st + lt, tax));
  }
  return TaxReport(out, carried);
}
