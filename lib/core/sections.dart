import 'package:flutter/material.dart';

/// Description d'une rubrique de l'application.
///
/// Une seule liste sert à la fois à la barre de navigation et aux cartes de
/// l'accueil : si on renomme une rubrique, on ne le fait qu'à un endroit.
class Section {
  final String title;
  final String question;
  final String description;
  final IconData icon;

  /// Contenu produit avec une IA : la pastille « AI » du titre l'explique.
  /// null = pas de pastille.
  final String? aiNote;

  const Section({
    required this.title,
    required this.question,
    required this.description,
    required this.icon,
    this.aiNote,
  });
}

const homeSection = Section(
  title: 'Home',
  question: 'Comprenez-vous les bases ?',
  description: '',
  icon: Icons.home_outlined,
);

const learnSection = Section(
  title: 'Learn',
  question: 'Comment fonctionne cette notion ?',
  description: 'Des leçons courtes où tu modifies les paramètres et observes le résultat.',
  icon: Icons.school_outlined,
);

const foresightSection = Section(
  title: 'Foresight',
  question: 'Que pourrait-on obtenir en connaissant le futur ?',
  description: 'Une démonstration idéale, pour comprendre pourquoi elle est impossible à reproduire.',
  icon: Icons.visibility_outlined,
  aiNote:
      'Les parcours de chaque décennie ont été proposés par une IA (GPT), '
      'puis vérifiés un par un avec les vrais cours de Twelve Data.',
);

const pastTraderSection = Section(
  title: 'Past Trader',
  question: 'Qu’aurais-je décidé sans connaître la suite ?',
  description:
      'Replonge dans le passé et décide jour après jour, sans voir l’avenir.',
  icon: Icons.history_edu_outlined,
  aiNote:
      'Les actualités ont été rédigées avec une IA à partir d’événements '
      'réels, à relire avec un œil critique. Les cours, eux, sont réels.',
);

const playgroundSection = Section(
  title: 'Playground',
  question: 'Que se serait-il passé avec mes paramètres ?',
  description:
      'Choisis un actif, une somme et une période, puis observe le résultat.',
  icon: Icons.science_outlined,
);

/// Ordre des rubriques, identique dans la barre du bas et sur l'accueil.
const sections = [
  homeSection,
  learnSection,
  foresightSection,
  pastTraderSection,
  playgroundSection,
];
