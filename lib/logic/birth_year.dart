/// Année de naissance (facultative) : validation et décennie proposée.
library;

/// Champ vide = non renseignée, c'est permis.
String? validateBirthYear(String? text, {required int currentYear}) {
  final t = text?.trim() ?? '';
  if (t.isEmpty) return null;
  final year = int.tryParse(t);
  if (year == null) return 'Écris une année, par exemple 1985.';
  final (min, max) = (currentYear - 110, currentYear - 10);
  if (year < min || year > max) return 'Choisis une année entre $min et $max.';
  return null;
}

/// null si le champ est vide.
int? parseBirthYear(String? text) => int.tryParse(text?.trim() ?? '');

/// Décennie proposée : celle de tes 25 ans, l'âge où l'on commence souvent
/// à pouvoir épargner. [decades] : premières années disponibles (1970, 1980…).
/// Sans année de naissance : la plus récente.
int suggestedDecade(int? birthYear, List<int> decades) {
  final sorted = [...decades]..sort();
  if (birthYear == null) return sorted.last;
  final target = (birthYear + 25) ~/ 10 * 10; // 1985 + 25 = 2010 → 2010
  // La dernière décennie disponible qui ne dépasse pas la cible ; si la cible
  // est avant la première, la première.
  final before = sorted.where((d) => d <= target);
  return before.isEmpty ? sorted.first : before.last;
}
