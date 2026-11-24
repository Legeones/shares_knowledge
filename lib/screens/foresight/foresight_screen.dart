import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/sections.dart';
import '../../core/theme.dart';
import '../../logic/birth_year.dart';
import '../../models/foresight/foresight.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/section_card.dart';
import 'foresight_player_screen.dart';

/// Ouvre le lecteur d'une décennie.
void openForesight(BuildContext context, ForesightScenario scenario) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForesightPlayerScreen(scenario: scenario),
      ),
    );

/// Le parcours proposé : la décennie des 25 ans de l'utilisateur.
ForesightScenario suggestedScenario(ForesightCatalog catalog, int? birthYear) =>
    catalog.byDecade(suggestedDecade(birthYear, catalog.decades));

/// Onglet Perfect Foresight : un parcours idéal par décennie.
class ForesightScreen extends StatelessWidget {
  const ForesightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Chargé une fois au démarrage (main.dart), partagé par provider.
    final catalog = context.watch<ForesightCatalog>();
    final settings = context.watch<SettingsProvider>();
    final suggested = suggestedScenario(catalog, settings.birthYear).decade;
    final seen = settings.foresightDecadesSeen;

    return ListView(
      padding: tabListPadding(context),
      children: [
        SectionHero(
          section: foresightSection,
          children: [
            const Text(
              'Une démonstration idéale : 1 000 \$ investis au début d’une '
              'décennie, puis déplacés pendant 40 ans (jusqu’en 2026 au plus) '
              'vers les bons actifs aux bons jours, comme si on connaissait '
              'le futur.',
            ),
            const SizedBox(height: 8),
            Text(
              'Avec tes impôts (${settings.taxProfile().summary}) et des '
              'retraits chaque mois pour mieux vivre. Tu n’y prends aucune '
              'décision : tu découvres ce qui aurait été possible… et '
              'pourquoi c’est impossible à reproduire.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const GroupTitle('Choisis ta décennie'),
        for (final scenario in catalog.scenarios.reversed) ...[
          _DecadeCard(
            scenario: scenario,
            suggested: scenario.decade == suggested,
            seen: seen.contains(scenario.decade),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          'La décennie proposée est celle de tes 25 ans '
          '(année de naissance modifiable dans ton profil).',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DecadeCard extends StatelessWidget {
  final ForesightScenario scenario;
  final bool suggested;
  final bool seen;

  const _DecadeCard({
    required this.scenario,
    required this.suggested,
    required this.seen,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // ’70, ’80… ’00 : les deux derniers chiffres de la décennie.
    final short = '’${(scenario.decade % 100).toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openForesight(context, scenario),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  short,
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.decadeLabel, style: textTheme.titleMedium),
                    Text(
                      'Du ${formatDate(scenario.start)} au '
                      '${formatDate(scenario.end)} · '
                      '${scenario.assetSteps.length} placements',
                      style: textTheme.bodySmall,
                    ),
                    if (suggested || seen) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (suggested)
                            const _Tag('Ta décennie', AppColors.blue),
                          if (seen) const _Tag('Vue', AppColors.gain),
                        ],
                      ),
                    ],
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
