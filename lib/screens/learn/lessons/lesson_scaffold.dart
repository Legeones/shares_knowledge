import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/learn/lessons.dart';
import '../../../providers/learn/lesson_progress_provider.dart';
import '../../../widgets/glass.dart';

/// Une étape de leçon : un titre et un contenu.
class LessonStep {
  final String title;
  final Widget content;

  /// Faux tant que l'utilisateur n'a pas répondu (ex. le quiz) :
  /// le bouton « Suivant » reste désactivé.
  final bool canContinue;

  const LessonStep({
    required this.title,
    required this.content,
    this.canContinue = true,
  });
}

/// Squelette commun à toutes les leçons : barre de progression, étape
/// affichée, boutons Précédent / Suivant, enregistrement de l'avancement.
class LessonScaffold extends StatefulWidget {
  final LessonInfo lesson;
  final List<LessonStep> steps;

  const LessonScaffold({super.key, required this.lesson, required this.steps});

  @override
  State<LessonScaffold> createState() => _LessonScaffoldState();
}

class _LessonScaffoldState extends State<LessonScaffold> {
  // Reprend à l'étape enregistrée.
  late int _step = context
      .read<LessonProgressProvider>()
      .stepOf(widget.lesson.id)
      .clamp(0, widget.steps.length - 1);

  bool get _isLast => _step == widget.steps.length - 1;

  void _goTo(int step) {
    setState(() => _step = step);
    context.read<LessonProgressProvider>().saveStep(widget.lesson.id, step);
  }

  Future<void> _finish() async {
    // Récupéré avant de fermer l'écran : après pop, son context n'est plus valide.
    final messenger = ScaffoldMessenger.of(context);
    await context.read<LessonProgressProvider>().complete(widget.lesson.id);
    if (!mounted) return;
    Navigator.pop(context);
    showGlassMessage(
      messenger,
      'Leçon « ${widget.lesson.title} » terminée !',
      icon: Icons.school_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_step];

    return LargeTitleScaffold(
      title: widget.lesson.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: glassBarInset(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_step + 1) / widget.steps.length,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              // La clé change à chaque étape : on repart en haut de la page.
              key: ValueKey(_step),
              padding: const EdgeInsets.all(16),
              children: [
                PageTitle(widget.lesson.title),
                Text(
                  'Étape ${_step + 1} sur ${widget.steps.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(step.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                step.content,
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton.icon(
                      onPressed: () => _goTo(_step - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: !step.canContinue
                            ? null
                            : _isLast
                            ? _finish
                            : () => _goTo(_step + 1),
                        child: Text(_isLast ? 'Terminer la leçon' : 'Suivant'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
