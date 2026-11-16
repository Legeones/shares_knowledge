import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/learn/lessons.dart';
import '../../core/sections.dart';
import '../../models/simulation.dart';
import '../../providers/learn/lesson_progress_provider.dart';
import '../../providers/progress/progress.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/section_card.dart';
import '../learn/learn_screen.dart';
import '../progress/progress_screen.dart';
import '../playground/simulation_result_screen.dart';

/// Écran d'accueil : présentation, « reprendre », rubriques, progression.
class HomeScreen extends StatelessWidget {
  /// Fonction fournie par MainShell pour changer d'onglet.
  /// L'accueil ne connaît pas la barre de navigation : il demande juste
  /// « ouvre l'onglet n° X ».
  final void Function(int tabIndex) onOpenSection;

  const HomeScreen({super.key, required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    final last = context.watch<SettingsProvider>().lastSimulation;
    final progress = context.watch<LessonProgressProvider>();
    final lessonInProgress = lessons
        .where((l) => l.available)
        .where((l) => progress.statusOf(l.id) == LessonStatus.inProgress)
        .firstOrNull;

    return ListView(
      padding: tabListPadding(context),
      children: [
        const _WelcomeCard(),
        const SizedBox(height: 20),
        // Affichées seulement s'il y a quelque chose à reprendre.
        if (lessonInProgress != null || last != null)
          const GroupTitle('Reprendre'),
        if (lessonInProgress != null) ...[
          _ResumeTile(
            icon: Icons.school_rounded,
            title: 'Reprendre ma leçon',
            subtitle: lessonInProgress.title,
            onTap: () => openLesson(context, lessonInProgress),
          ),
          const SizedBox(height: 10),
        ],
        if (last != null) ...[
          _ResumeTile(
            icon: Icons.play_arrow_rounded,
            title: 'Reprendre ma dernière simulation',
            subtitle: _describe(last),
            onTap: () => openSimulation(context, last),
          ),
          const SizedBox(height: 10),
        ],
        const GroupTitle('Rubriques'),
        // `indexed` donne à la fois la position (i) et la rubrique : la
        // rubrique n° i est l'onglet n° i. On saute l'accueil (n° 0).
        for (final (i, section) in sections.indexed)
          if (section != homeSection) ...[
            SectionCard(section: section, onTap: () => onOpenSection(i)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  static String _describe(SimulationParams p) =>
      '${p.asset.name} · ${formatMoney(p.amount, p.asset.currency)} · '
      '${formatDate(p.start)} → ${formatDate(p.end)}';
}

/// Carte d'accueil en dégradé bleu : salutation et progression.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    final pseudo = context.watch<SettingsProvider>().pseudo;
    final runs = context.watch<SettingsProvider>().playgroundRuns;
    final medalsEarned = earnedMedalsCount(watchProgress(context));
    final lessonsDone = context.watch<LessonProgressProvider>().completedCount(
      availableLessonIds,
    );

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Le logo sur une tuile blanche, comme une icône d'application.
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset('assets/images/logo_sk.png', height: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pseudo.isEmpty ? 'Bienvenue' : 'Bonjour $pseudo',
                  style: hero.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Apprends l’investissement en manipulant de vraies données '
            'historiques.',
            style: hero.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Aucune transaction réelle, aucun compte bancaire : uniquement '
            'pour comprendre.',
            style: hero.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          // La progression ouvre l'écran « Ma progression ».
          GestureDetector(
            onTap: () => openProgress(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ma progression', style: hero.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stat(value: lessonsDone, label: 'leçons\nterminées'),
                    const SizedBox(width: 8),
                    _Stat(value: runs, label: 'simulations\nlancées'),
                    const SizedBox(width: 8),
                    _Stat(value: medalsEarned, label: 'médailles\nobtenues'),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Voir ma progression ›',
                    style: hero.labelLarge?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = heroText(context);
    return Expanded(
      child: HeroPill(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: textTheme.headlineMedium),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « Reprendre… ».
class _ResumeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResumeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: IconTile(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
