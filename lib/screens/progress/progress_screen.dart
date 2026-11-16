import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/learn/lessons.dart';
import '../../core/theme.dart';
import '../../logic/progress/medals.dart';
import '../../logic/progress/trader_stats.dart';
import '../../models/foresight/foresight.dart';
import '../../models/past_trader/past_trader.dart';
import '../../models/past_trader/trader_attempt.dart';
import '../../providers/learn/lesson_progress_provider.dart';
import '../../providers/progress/progress.dart';
import '../../providers/past_trader/trader_attempts_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/progress/medal_widgets.dart';
import '../playground/saved_simulations_screen.dart';

/// Ma progression : médailles, puis statistiques rubrique par rubrique.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = watchProgress(context);
    final statuses = evaluateMedals(progress);
    final earned = statuses.where((s) => s.earned).length;
    final obtainable = statuses.where((s) => !s.medal.comingSoon).length;
    final hero = heroText(context);
    // `?` : les parcours peuvent manquer dans certains tests.
    final foresightDecadeCount =
        context.watch<ForesightCatalog?>()?.scenarios.length ?? 6;

    return LargeTitleScaffold(
      title: 'Ma progression',
      body: ListView(
        padding: pagePadding(context, top: 4, bottom: 32),
        children: [
          const PageTitle('Ma progression'),
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Médailles', style: hero.titleMedium),
                Text('$earned / $obtainable', style: hero.displaySmall),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: obtainable == 0 ? 0 : earned / obtainable,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Elles récompensent la curiosité et la régularité, '
                  'jamais le montant des gains.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const GroupTitle('Médailles'),
          // Obtenues d'abord, puis en cours, puis « bientôt ».
          for (final s in _sorted(statuses)) ...[
            MedalCard(status: s),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          const GroupTitle('Leçons'),
          const _LessonsStats(),
          const SizedBox(height: 20),
          const GroupTitle('Playground'),
          CardGroup(
            children: [
              _StatRow('Simulations lancées', '${progress.playgroundRuns}'),
              _StatRow(
                'Actifs différents simulés',
                '${progress.distinctAssets}',
              ),
              _StatRow(
                'Simulations sauvegardées',
                '${progress.savedSimulations}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SavedSimulationsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const GroupTitle('Perfect Foresight'),
          CardGroup(
            children: [
              _StatRow(
                'Décennies dont le bilan a été vu',
                '${progress.foresightDecadesSeen} / $foresightDecadeCount',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const GroupTitle('Past Trader'),
          const _TraderStats(),
        ],
      ),
    );
  }

  static List<MedalStatus> _sorted(List<MedalStatus> all) => [
    ...all.where((s) => s.earned),
    ...all.where((s) => !s.earned && !s.medal.comingSoon),
    ...all.where((s) => s.medal.comingSoon),
  ];
}

class _LessonsStats extends StatelessWidget {
  const _LessonsStats();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<LessonProgressProvider>();
    return CardGroup(
      children: [
        for (final lesson in lessons.where((l) => l.available))
          _StatRow(lesson.title, switch (progress.statusOf(lesson.id)) {
            LessonStatus.notStarted => 'Non commencée',
            LessonStatus.inProgress => 'En cours',
            LessonStatus.completed => 'Terminée',
          }),
      ],
    );
  }
}

/// Statistiques Past Trader, scénario par scénario, puis l'historique.
class _TraderStats extends StatelessWidget {
  const _TraderStats();

  @override
  Widget build(BuildContext context) {
    final attempts = context.watch<TraderAttemptsProvider>().items;
    // `?` : le scénario peut manquer dans certains tests.
    final data = context.watch<TraderGameData?>();
    if (attempts.isEmpty) {
      return const CardGroup(
        children: [_StatRow('Aucune partie terminée pour l’instant', '')],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final stats in statsByScenario(attempts)) ...[
          _ScenarioCard(
            title: stats.gameId == data?.id
                ? data!.title
                : 'Scénario ${stats.gameId}',
            stats: stats,
          ),
          const SizedBox(height: 12),
        ],
        const GroupTitle('Historique des parties'),
        CardGroup(children: [for (final a in attempts) _AttemptRow(a)]),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String title;
  final ScenarioStats stats;
  const _ScenarioCard({required this.title, required this.stats});

  String _perf(TraderAttempt a) =>
      '${formatPercent(a.performance)} (S&P 500 ${formatPercent(a.spyPerformance)})';

  @override
  Widget build(BuildContext context) {
    return CardGroup(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        _StatRow(
          'Parties',
          '${stats.count}'
              '${stats.repeatCount > 0 ? ' (dont ${stats.repeatCount} rejouée(s))' : ''}',
        ),
        // La première partie est la seule jouée sans connaître la suite.
        _StatRow('Première partie', _perf(stats.first)),
        if (stats.count > 1) ...[
          _StatRow('Meilleure partie', _perf(stats.best)),
          _StatRow('Dernière partie', _perf(stats.latest)),
        ],
        _StatRow(
          'Mieux que le S&P 500',
          '${stats.beatSpyCount} fois sur ${stats.count}',
        ),
        _StatRow(
          'Menées jusqu’au bout',
          '${stats.fullCount} sur ${stats.count}',
        ),
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final TraderAttempt a;
  const _AttemptRow(this.a);

  @override
  Widget build(BuildContext context) {
    final isGain = a.performance >= 0;
    return ListTile(
      leading: Icon(a.isRepeat ? Icons.replay_rounded : Icons.flag_rounded),
      title: Text(
        formatPercent(a.performance),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isGain ? AppColors.gain : AppColors.loss,
        ),
      ),
      subtitle: Text(
        '${a.isRepeat ? 'Rejouée' : 'Première partie'} · le '
        '${formatDate(a.playedAt)} · ${a.tradesCount} ordre(s)'
        '${a.stoppedEarly ? ' · arrêtée le ${formatDate(a.endDate)}' : ''}',
      ),
    );
  }
}

/// Une ligne « libellé … valeur ».
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatRow(this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Largeur limitée : une valeur longue passe à la ligne.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Nombre de médailles obtenues, pour l'accueil et le profil.
int earnedMedalsCount(ProgressSnapshot progress) =>
    evaluateMedals(progress).where((s) => s.earned).length;

/// Ouvre l'écran de progression.
void openProgress(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
