import 'package:flutter/material.dart';

import '../core/sections.dart';
import '../core/theme.dart';
import 'glass.dart';

/// Carte cliquable présentant une rubrique sur l'accueil.
class SectionCard extends StatelessWidget {
  final Section section;
  final VoidCallback onTap;

  const SectionCard({super.key, required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // clipBehavior : l'effet d'appui (InkWell) respecte les coins arrondis.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconTile(section.icon, size: 48),
              const SizedBox(width: 14),
              // Expanded : le texte prend toute la place restante et passe
              // à la ligne au lieu de déborder.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      section.question,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(section.description, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête en dégradé d'un onglet : icône, question de la rubrique et
/// quelques lignes de présentation.
class SectionHero extends StatelessWidget {
  final Section section;
  final List<Widget> children;

  const SectionHero({
    super.key,
    required this.section,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroPill(child: Icon(section.icon, size: 28)),
          const SizedBox(height: 14),
          Text(section.question, style: hero.headlineSmall),
          if (children.isNotEmpty) const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
