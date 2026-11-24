import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/foresight/foresight.dart';
import '../../models/foresight/foresight.dart';

/// Fenêtre « chapitre » montrée à chaque transition du parcours :
/// pourquoi on quitte l'étape précédente, ce qui se passe dans le monde,
/// pourquoi on entre dans la suivante, et la leçon à en retenir.
///
/// [leaving] : l'étape qu'on quitte (null au tout début).
/// [entering] : l'étape suivante (null pour l'épilogue).
Future<void> showChapterSheet(
  BuildContext context, {
  required DateTime date,
  StepResult? leaving,
  ForesightStep? entering,
  required int number,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => _ChapterContent(
        scroll: scroll,
        date: date,
        leaving: leaving,
        entering: entering,
        number: number,
      ),
    ),
  );
}

String _name(ForesightStep step) => switch (step) {
  AssetStep(:final name) => name,
  CashStep() => 'Pause en cash',
};

class _ChapterContent extends StatelessWidget {
  final ScrollController scroll;
  final DateTime date;
  final StepResult? leaving;
  final ForesightStep? entering;
  final int number;

  const _ChapterContent({
    required this.scroll,
    required this.date,
    required this.leaving,
    required this.entering,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entering = this.entering;
    final leaving = this.leaving;

    // Le texte défile ; le bouton reste épinglé en bas, toujours visible.
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text(
                entering == null ? 'Épilogue' : 'Chapitre $number',
                style: textTheme.labelLarge?.copyWith(color: AppColors.blue),
              ),
              Text(
                entering == null ? 'La dernière vente' : _name(entering),
                style: textTheme.headlineSmall,
              ),
              Text(formatDateWithWeekday(date), style: textTheme.bodySmall),
              const SizedBox(height: 16),

              if (leaving != null)
                _Section(
                  icon: Icons.logout,
                  title: switch (leaving.step) {
                    AssetStep(:final name) =>
                      'Pourquoi vendre $name maintenant ?',
                    CashStep() => 'Pourquoi arrêter d’attendre ?',
                  },
                  text: leaving.step.chapter.whyLeave,
                  footer: leaving.step is AssetStep
                      ? 'Résultat de l’étape : ×${_x(leaving.multiplier)}'
                      : null,
                ),

              if (entering != null) ...[
                _Section(
                  icon: Icons.public,
                  title: 'Ce qui se passe dans le monde',
                  text: entering.chapter.context,
                ),
                _Section(
                  icon: Icons.login,
                  title: switch (entering) {
                    AssetStep(:final name) => 'Pourquoi acheter $name ?',
                    CashStep() => 'Pourquoi tout garder en cash ?',
                  },
                  text: entering.chapter.whyEnter,
                ),
                _LessonCard(
                  title: entering.chapter.lessonTitle,
                  text: entering.chapter.lesson,
                ),
              ] else
                const _Section(
                  icon: Icons.flag_outlined,
                  title: 'Fin du parcours',
                  text:
                      'Cinq achats, cinq ventes, chacun au jour près. Avant de '
                      'regarder le résultat de trop près, demande-toi : qu’aurais-tu '
                      'pu savoir, toi, à chacune de ces dates ?',
                ),

              const SizedBox(height: 8),
              Text(
                'Rappel : ces choix ne sont possibles qu’en connaissant la suite. '
                'Sur le moment, rien de tout cela n’était certain.',
                style: textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: Text(
                entering == null ? 'Voir le résultat' : 'Continuer l’histoire',
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _x(double m) => m.toStringAsFixed(1).replaceAll('.', ',');
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? footer;

  const _Section({
    required this.icon,
    required this.title,
    required this.text,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(text),
                if (footer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    footer!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La leçon du chapitre, mise en avant.
class _LessonCard extends StatelessWidget {
  final String title;
  final String text;
  const _LessonCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leçon : $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}
