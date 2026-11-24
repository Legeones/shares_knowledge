/// Médailles, déduites de la progression (rien n'est enregistré).
library;

/// Ce que l'utilisateur a accompli, rassemblé depuis les différents providers.
class ProgressSnapshot {
  final int lessonsCompleted;
  final int lessonsAvailable;

  /// Leçons sur le risque terminées (volatilité, baisse maximale).
  final int riskLessonsCompleted;
  final int playgroundRuns;

  /// Simulations Playground en versements mensuels (DCA).
  final int monthlyRuns;

  /// Nombre d'actifs différents simulés dans le Playground.
  final int distinctAssets;
  final int savedSimulations;

  /// Décennies Perfect Foresight dont le bilan a été vu.
  final int foresightDecadesSeen;

  /// Parties Past Trader terminées (bilan atteint), dont rejouées et menées
  /// jusqu'à la dernière date.
  final int traderGames;
  final int traderRepeats;
  final int traderFullGames;

  /// Meilleur écart de performance avec le S&P 500 sur une partie
  /// (+0,12 = 12 points de mieux). null : aucune partie.
  final double? bestExcessReturn;

  const ProgressSnapshot({
    this.lessonsCompleted = 0,
    this.lessonsAvailable = 0,
    this.riskLessonsCompleted = 0,
    this.playgroundRuns = 0,
    this.monthlyRuns = 0,
    this.distinctAssets = 0,
    this.savedSimulations = 0,
    this.foresightDecadesSeen = 0,
    this.traderGames = 0,
    this.traderRepeats = 0,
    this.traderFullGames = 0,
    this.bestExcessReturn,
  });
}

/// Les quatre paliers d'une médaille à niveaux.
enum MedalTier {
  iron('Fer'),
  copper('Cuivre'),
  gold('Or'),
  diamond('Diamant');

  final String label;
  const MedalTier(this.label);
}

class Medal {
  final String id;
  final String title;

  /// La valeur mesurée (null : médaille annoncée, liée à une fonction pas
  /// encore disponible).
  final double Function(ProgressSnapshot)? measure;

  /// Seuils à atteindre : un seul pour une médaille simple, quatre pour une
  /// médaille à niveaux (Fer, Cuivre, Or, Diamant).
  final List<double> thresholds;

  /// Condition affichée pour un seuil : « Lancer 5 simulations… ».
  final String Function(double threshold) condition;

  /// Écriture d'une valeur : « 5 », « +12 pts »…
  final String Function(double value) format;

  const Medal({
    required this.id,
    required this.title,
    required this.condition,
    this.measure,
    this.thresholds = const [1],
    this.format = _count,
  });

  bool get comingSoon => measure == null;
  bool get isTiered => thresholds.length == MedalTier.values.length;

  static String _count(double v) => '${v.round()}';
}

/// Une médaille et où en est l'utilisateur.
class MedalStatus {
  final Medal medal;
  final double value;

  const MedalStatus(this.medal, this.value);

  /// Nombre de seuils atteints (0 = pas encore obtenue).
  int get level => medal.comingSoon
      ? 0
      : medal.thresholds.where((t) => value >= t - 1e-9).length;

  bool get earned => level > 0;
  bool get maxed => level == medal.thresholds.length;

  /// Palier atteint (médailles à niveaux seulement).
  MedalTier? get tier =>
      medal.isTiered && earned ? MedalTier.values[level - 1] : null;

  /// Prochain seuil à atteindre, null si tout est obtenu.
  double? get next => maxed ? null : medal.thresholds[level];

  /// Avancement vers le prochain seuil, entre 0 et 1.
  double get ratio {
    final target = next;
    if (target == null) return 1;
    if (target <= 0) return value >= target ? 1 : 0;
    return (value / target).clamp(0, 1);
  }

  /// Ce qu'il reste à faire, ou la dernière condition remplie.
  String get condition => medal.condition(next ?? medal.thresholds.last);
}

String _plural(double n, String word) =>
    '${n.round()} $word${n >= 2 ? 's' : ''}';

String _points(double v) {
  final pts = (v * 100).toStringAsFixed(1).replaceAll('.', ',');
  return v >= 0 ? '+$pts pts' : '$pts pts';
}

/// Catalogue (plan fonctionnel §8.2).
final medals = <Medal>[
  Medal(
    id: 'first_lesson',
    title: 'Premier pas',
    condition: (_) => 'Terminer une première leçon.',
    measure: (s) => s.lessonsCompleted.toDouble(),
  ),
  Medal(
    id: 'all_lessons',
    title: 'Bon élève',
    condition: (_) => 'Terminer toutes les leçons disponibles.',
    // Part des leçons terminées : 1 = toutes.
    measure: (s) =>
        s.lessonsAvailable == 0 ? 0 : s.lessonsCompleted / s.lessonsAvailable,
    format: (v) => '${(v * 100).round()} %',
  ),
  Medal(
    id: 'simulator',
    title: 'Simulateur',
    condition: (t) => 'Lancer ${_plural(t, 'simulation')} dans le Playground.',
    measure: (s) => s.playgroundRuns.toDouble(),
    thresholds: const [1, 5, 15, 40],
  ),
  Medal(
    id: 'explorer',
    title: 'Explorateur',
    condition: (t) => 'Simuler ${_plural(t, 'actif')} différents.',
    measure: (s) => s.distinctAssets.toDouble(),
    thresholds: const [2, 4, 8, 15],
  ),
  Medal(
    id: 'archivist',
    title: 'Archiviste',
    condition: (t) => 'Sauvegarder ${_plural(t, 'simulation')}.',
    measure: (s) => s.savedSimulations.toDouble(),
    thresholds: const [1, 3, 10, 25],
  ),
  Medal(
    id: 'time_traveler',
    title: 'Voyageur du temps',
    condition: (t) =>
        'Voir le bilan de ${_plural(t, 'décennie')} dans Perfect Foresight.',
    measure: (s) => s.foresightDecadesSeen.toDouble(),
    thresholds: const [1, 2, 4, 6],
  ),
  Medal(
    id: 'trader',
    title: 'Trader',
    condition: (t) => 'Terminer ${_plural(t, 'partie')} Past Trader.',
    measure: (s) => s.traderGames.toDouble(),
    thresholds: const [1, 3, 10, 25],
  ),
  Medal(
    id: 'persistent',
    title: 'Persévérant',
    condition: (t) => 'Rejouer ${_plural(t, 'partie')} déjà jouée(s).',
    measure: (s) => s.traderRepeats.toDouble(),
    thresholds: const [1, 3, 10, 20],
  ),
  Medal(
    id: 'to_the_end',
    title: 'Jusqu’au bout',
    condition: (_) => 'Mener une partie Past Trader jusqu’à sa dernière date.',
    measure: (s) => s.traderFullGames.toDouble(),
  ),
  Medal(
    id: 'efficiency',
    title: 'Efficience record',
    condition: (t) => t <= 0.001
        ? 'Faire mieux que le S&P 500 sur une partie Past Trader.'
        : 'Battre le S&P 500 de ${_points(t)} sur une partie Past Trader.',
    // Sans partie, -1 : très loin du premier seuil.
    measure: (s) => s.bestExcessReturn ?? -1,
    thresholds: const [0.001, 0.10, 0.25, 0.50],
    format: _points,
  ),
  Medal(
    id: 'regular',
    title: 'Investissement régulier',
    condition: (_) =>
        'Lancer une simulation en versements mensuels dans le Playground.',
    measure: (s) => s.monthlyRuns.toDouble(),
  ),
  // Liées aux enrichissements de la phase 5 (bientôt disponibles).
  Medal(
    id: 'comparator',
    title: 'Comparateur',
    condition: (_) => 'Comparer deux stratégies.',
  ),
  Medal(
    id: 'risk',
    title: 'Regard sur le risque',
    condition: (_) =>
        'Terminer la leçon sur la volatilité ou la baisse maximale.',
    measure: (s) => s.riskLessonsCompleted.toDouble(),
  ),
  Medal(
    id: 'blind',
    title: 'Sans boule de cristal',
    condition: (_) => 'Terminer un scénario Blind.',
  ),
];

/// État de chaque médaille du catalogue pour cette progression.
List<MedalStatus> evaluateMedals(ProgressSnapshot s) => [
  for (final medal in medals) MedalStatus(medal, medal.measure?.call(s) ?? 0),
];

/// Un palier obtenu : « Explorateur, niveau 3 (Or) ».
typedef MedalAward = ({Medal medal, int level});

/// Clé enregistrée pour un palier déjà annoncé : « explorer:3 ».
String awardKey(Medal medal, int level) => '${medal.id}:$level';

/// Paliers obtenus mais pas encore annoncés (le plus haut de chaque médaille).
List<MedalAward> newlyEarned(
  List<MedalStatus> statuses,
  Set<String> announced,
) => [
  for (final s in statuses)
    if (s.earned && !announced.contains(awardKey(s.medal, s.level)))
      (medal: s.medal, level: s.level),
];

/// Toutes les clés des paliers atteints (pour les marquer comme annoncés).
Iterable<String> earnedKeys(MedalStatus s) => [
  for (var level = 1; level <= s.level; level++) awardKey(s.medal, level),
];

/// « Explorateur (Or) » ou « Premier pas ».
String awardLabel(MedalAward award) => award.medal.isTiered
    ? '${award.medal.title} (${MedalTier.values[award.level - 1].label})'
    : award.medal.title;
