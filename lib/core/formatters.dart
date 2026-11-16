import 'package:intl/intl.dart';

/// Mise en forme des nombres et dates pour l'affichage, en français.
///
/// Les calculs manipulent des nombres bruts (0.25) ; seul l'affichage
/// les transforme en texte (+25,00 %).

const _currencySymbols = {'USD': r'$', 'EUR': '€'};

/// 1234.5, "USD" → "1 234,50 $"
String formatMoney(double value, String currency) {
  return NumberFormat.currency(
    locale: 'fr_FR',
    symbol: _currencySymbols[currency] ?? currency,
  ).format(value);
}

/// Comme formatMoney, mais avec toujours un signe : "+250,00 $" / "−300,00 $".
/// Le signe accompagne la couleur : un gain ne se lit pas qu'à la couleur.
String formatSignedMoney(double value, String currency) {
  final cents = (value * 100).round();
  final sign = cents > 0 ? '+' : (cents < 0 ? '−' : '');
  return '$sign${formatMoney(value.abs(), currency)}';
}

/// 0.2534 → "+25,34 %" (avec signe) ou "25,34 %" (sans).
String formatPercent(double fraction, {bool signed = true}) {
  final text = NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 2,
  ).format((fraction * 100).abs());
  final hundredths = (fraction * 10000).round(); // même règle d'arrondi
  if (!signed || hundredths == 0) return '$text %';
  return '${fraction > 0 ? '+' : '−'}$text %';
}

/// Quantité d'actions, jusqu'à 4 décimales : 10.123456 → "10,1235".
String formatUnits(double units) {
  return NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 4,
  ).format(units).replaceFirst(RegExp(r',?0+$'), '');
}

/// 2024-01-05 → "05/01/2024"
String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

const _weekdays = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// 2024-01-06 → "samedi 06/01/2024" (DateTime.weekday : 1 = lundi … 7 = dimanche)
String formatDateWithWeekday(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${formatDate(date)}';
