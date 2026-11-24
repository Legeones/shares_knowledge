import 'dart:math';

/// Gain ou perte en monnaie : ce qu'on a à la fin moins ce qu'on a mis.
double gain({required double invested, required double finalValue}) {
  return finalValue - invested;
}

/// Performance en proportion du montant investi : 0.25 signifie +25 %.
double performance({required double invested, required double finalValue}) {
  if (invested <= 0) {
    throw ArgumentError.value(invested, 'invested', 'doit être positif');
  }
  return gain(invested: invested, finalValue: finalValue) / invested;
}

/// Rendement composé : capital × (1 + taux)^années.
double compoundValue({
  required double capital,
  required double annualRate,
  required int years,
}) {
  if (years < 0) {
    throw ArgumentError.value(years, 'years', 'ne peut pas être négatif');
  }
  if (annualRate <= -1) {
    // -100 % ou pire : le capital serait nul ou négatif, ce qui n'a pas de sens.
    throw ArgumentError.value(annualRate, 'annualRate', 'doit être > -100 %');
  }
  return capital * pow(1 + annualRate, years);
}

/// Intérêts simples (sans réinvestissement) : capital × (1 + taux × années).
double simpleValue({
  required double capital,
  required double annualRate,
  required int years,
}) {
  if (years < 0) {
    throw ArgumentError.value(years, 'years', 'ne peut pas être négatif');
  }
  return capital * (1 + annualRate * years);
}

/// Une ligne du tableau de croissance : valeur avec et sans réinvestissement.
typedef GrowthRow = ({int year, double compound, double simple});

/// Valeurs année par année, de 0 à [years] inclus (pour le graphique de la leçon).
List<GrowthRow> growthTable({
  required double capital,
  required double annualRate,
  required int years,
}) {
  return [
    for (var y = 0; y <= years; y++)
      (
        year: y,
        compound: compoundValue(
          capital: capital,
          annualRate: annualRate,
          years: y,
        ),
        simple: simpleValue(capital: capital, annualRate: annualRate, years: y),
      ),
  ];
}

/// Nombre d'années pour doubler un capital à un taux constant.
double? doublingYears(double annualRate) {
  if (annualRate <= 0) return null;
  return log(2) / log(1 + annualRate);
}

/// Rendement annualisé : le taux constant qui, composé chaque année, mène de
/// [invested] à [finalValue] en [days] jours.
double? annualizedReturn({
  required double invested,
  required double finalValue,
  required int days,
}) {
  final years = days / 365.25;
  if (years < 1 || invested <= 0) return null;
  return pow(finalValue / invested, 1 / years) - 1;
}
