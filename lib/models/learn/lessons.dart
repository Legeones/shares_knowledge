/// Une leçon du catalogue Learn.
class LessonInfo {
  final String id;
  final String title;
  final String description;
  final int minutes;

  /// Faux = annoncée dans le catalogue mais pas encore écrite.
  final bool available;

  const LessonInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.minutes,
    this.available = true,
  });
}

const returnLesson = LessonInfo(
  id: 'return',
  title: 'Rendement et gain',
  description: 'Gagner 100 €, est-ce beaucoup ? La différence entre euros et pourcentage.',
  minutes: 3,
);

const compoundLesson = LessonInfo(
  id: 'compound',
  title: 'Rendement composé',
  description: 'Pourquoi le temps et le réinvestissement changent tout.',
  minutes: 4,
);

/// Identifiants des leçons déjà écrites.
Iterable<String> get availableLessonIds =>
    lessons.where((l) => l.available).map((l) => l.id);

const volatilityLesson = LessonInfo(
  id: 'volatility',
  title: 'Volatilité',
  description: 'Même résultat final, parcours très différents.',
  minutes: 4,
);

const drawdownLesson = LessonInfo(
  id: 'drawdown',
  title: 'Baisse maximale',
  description: 'Les pertes temporaires subies en chemin.',
  minutes: 4,
);

const dcaLesson = LessonInfo(
  id: 'dca',
  title: 'Investir régulièrement (DCA)',
  description: 'Un gros versement ou de petits versements réguliers ?',
  minutes: 4,
);

const diversificationLesson = LessonInfo(
  id: 'diversification',
  title: 'Diversification',
  description: 'Ne pas mettre tous ses œufs dans le même panier.',
  minutes: 5,
);

/// Leçons sur le risque (médaille « Regard sur le risque »).
const riskLessonIds = ['volatility', 'drawdown'];

/// Ordre d'affichage du catalogue.
const lessons = [
  returnLesson,
  compoundLesson,
  dcaLesson,
  volatilityLesson,
  drawdownLesson,
  diversificationLesson,
];
