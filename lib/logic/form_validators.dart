import '../models/price_point.dart';

/// Règles de validation du formulaire du Playground.

const maxAmount = 10000000.0;

/// Date la plus ancienne proposée (les historiques remontent rarement avant).
final earliestDate = DateTime.utc(1990, 1, 1);

double? parseAmount(String? text) {
  if (text == null) return null;
  final cleaned = text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  return double.tryParse(cleaned);
}

String? validateAmount(String? text) {
  if (text == null || text.trim().isEmpty) return 'Indique un montant.';
  final amount = parseAmount(text);
  if (amount == null) return 'Ce n’est pas un nombre valide.';
  if (amount <= 0) return 'Le montant doit être supérieur à 0.';
  if (amount > maxAmount) return 'Maximum : 10 000 000.';
  return null;
}

String? validateStartDate(DateTime? start, {required DateTime? end}) {
  if (start == null) return 'Choisis une date de début.';
  if (start.isBefore(earliestDate)) return 'Date antérieure à 1990.';
  if (end != null && !start.isBefore(end)) {
    return 'Le début doit être avant la fin.';
  }
  return null;
}

/// [today] est passé en paramètre pour pouvoir tester avec une date fixe.
String? validateEndDate(DateTime? end, {required DateTime today}) {
  if (end == null) return 'Choisis une date de fin.';
  // Les cours ne sont définitifs qu'à la clôture : on s'arrête à hier.
  if (!dateOnly(end).isBefore(dateOnly(today))) {
    return 'La fin doit être au plus tard hier.';
  }
  return null;
}
