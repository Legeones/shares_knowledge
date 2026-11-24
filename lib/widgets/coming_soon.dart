import 'package:flutter/material.dart';

import '../core/sections.dart';

/// Contenu temporaire pour une rubrique pas encore développée.
class ComingSoon extends StatelessWidget {
  final Section section;

  const ComingSoon({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              section.icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              section.question,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(section.description, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Chip(label: Text('Bientôt disponible')),
          ],
        ),
      ),
    );
  }
}
