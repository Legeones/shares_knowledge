import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/learn/lessons.dart';
import '../../core/sections.dart';
import '../../core/theme.dart';
import '../../providers/learn/lesson_progress_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/section_card.dart';
import 'lessons/compound_lesson_screen.dart';
import 'lessons/dca_lesson_screen.dart';
import 'lessons/diversification_lesson_screen.dart';
import 'lessons/drawdown_lesson_screen.dart';
import 'lessons/return_lesson_screen.dart';
import 'lessons/volatility_lesson_screen.dart';

/// Ouvre l'écran d'une leçon disponible.
void openLesson(BuildContext context, LessonInfo lesson) {
  final Widget screen = switch (lesson.id) {
    'return' => const ReturnLessonScreen(),
    'compound' => const CompoundLessonScreen(),
    'volatility' => const VolatilityLessonScreen(),
    'drawdown' => const DrawdownLessonScreen(),
    'dca' => const DcaLessonScreen(),
    'diversification' => const DiversificationLessonScreen(),
    _ => throw ArgumentError('Leçon inconnue : ${lesson.id}'),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// Catalogue des leçons, avec l'état de chacune.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<LessonProgressProvider>();
    final available = lessons.where((l) => l.available);
    final done = progress.completedCount(available.map((l) => l.id));

    return ListView(
      padding: tabListPadding(context),
      children: [
        SectionHero(
          section: learnSection,
          children: [
            const Text(
              'Des leçons courtes : une situation, des curseurs à manipuler, '
              'un graphique qui réagit, puis une question.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            HeroPill(
              child: Text(
                '$done leçon${done > 1 ? 's' : ''} terminée'
                '${done > 1 ? 's' : ''} sur ${available.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const GroupTitle('Leçons'),
        for (final lesson in lessons) ...[
          _LessonCard(lesson: lesson, status: progress.statusOf(lesson.id)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonInfo lesson;
  final LessonStatus status;
  const _LessonCard({required this.lesson, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = !lesson.available
        ? ('Bientôt', AppColors.muted, Icons.lock_clock_rounded)
        : switch (status) {
            LessonStatus.notStarted => (
              'Non commencée',
              AppColors.blue,
              Icons.play_arrow_rounded,
            ),
            LessonStatus.inProgress => (
              'En cours',
              Colors.orange.shade800,
              Icons.pending_rounded,
            ),
            LessonStatus.completed => (
              'Terminée',
              AppColors.gain,
              Icons.check_rounded,
            ),
          };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: lesson.available,
        contentPadding: const EdgeInsets.all(14),
        leading: IconTile(
          icon,
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
        ),
        title: Text(
          lesson.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text('${lesson.description}\n≈ ${lesson.minutes} min'),
        isThreeLine: true,
        // Le statut est écrit, pas seulement suggéré par la couleur.
        trailing: _StatusPill(label: label, color: color),
        onTap: lesson.available ? () => openLesson(context, lesson) : null,
      ),
    );
  }
}

/// Petite étiquette colorée : « Terminée », « En cours »…
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
