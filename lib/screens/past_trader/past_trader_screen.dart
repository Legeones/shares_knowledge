import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/sections.dart';
import '../../core/theme.dart';
import '../../logic/past_trader/news_feed.dart';
import '../../models/past_trader/past_trader.dart';
import '../../widgets/glass.dart';
import '../../widgets/section_card.dart';
import '../../providers/past_trader/trader_attempts_provider.dart';
import '../../providers/past_trader/trader_save_provider.dart';
import '../../widgets/dialogs.dart';
import 'trader_game_screen.dart';

/// Onglet Past Trader : présentation, règles et nouvelle partie.
class PastTraderScreen extends StatelessWidget {
  const PastTraderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<TraderGameData>();
    final news = context.watch<NewsFeed>();
    // `?` : absent dans certains tests de cet onglet seul.
    final attempts =
        context.watch<TraderAttemptsProvider?>()?.items ?? const [];
    final textTheme = Theme.of(context).textTheme;
    final saved = context.watch<TraderSaveProvider?>()?.saveFor(data.id);

    void open({bool resume = false}) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TraderGameScreen(
          data: data,
          news: news,
          resume: resume ? saved : null,
        ),
      ),
    );

    Future<void> newGame() async {
      // Une seule partie en cours : en commencer une autre l'efface.
      if (saved != null) {
        final ok = await confirmAction(
          context,
          title: 'Nouvelle partie ?',
          message:
              'Ta partie en cours (au ${formatDate(saved.current)}) sera '
              'effacée.',
          confirmLabel: 'Recommencer',
        );
        if (!ok || !context.mounted) return;
        await context.read<TraderSaveProvider>().clear();
        if (!context.mounted) return;
      }
      open();
    }

    return ListView(
      padding: tabListPadding(context),
      children: [
        SectionHero(
          section: pastTraderSection,
          children: [
            Text(data.title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(data.intro, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 20),
        const GroupTitle('Les règles'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final rule in [
                  '${formatMoney(data.initialCash, 'USD')} de départ, du '
                      '${formatDate(data.start)} au ${formatDate(data.end)}.',
                  '${data.assets.length} actifs : indices, actions, or, obligations, '
                      'cryptomonnaies. Achète-en un ou plusieurs, vends quand tu veux.',
                  'Tu ne vois que le passé : aucun cours futur n’est jamais affiché.',
                  'Le temps n’avance que vers l’avant : impossible d’annuler une '
                      'décision après avoir vu la suite.',
                  'Ordres au cours de clôture du jour, sans frais. Bourse fermée le '
                      'week-end, cryptos ouvertes tous les jours.',
                  'L’actualité tombe au jour le jour ; les grandes nouvelles mettent '
                      'la lecture en pause.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 10),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.blue,
                          ),
                        ),
                        Expanded(child: Text(rule)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (saved != null) ...[
          const GroupTitle('Partie en cours'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const IconTile(Icons.pause_circle_outline_rounded),
              title: Text(
                'Au ${formatDate(saved.current)}',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Portefeuille : ${formatMoney(saved.totalValue, 'USD')} · '
                'quittée le ${formatDate(saved.savedAt)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => open(resume: true),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => open(resume: true),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Reprendre la partie'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: newGame,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Nouvelle partie'),
          ),
        ] else
          FilledButton.icon(
            onPressed: newGame,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Nouvelle partie'),
          ),
        const SizedBox(height: 8),
        Text(
          'Source : ${data.source}',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (attempts.isNotEmpty) ...[
          const SizedBox(height: 20),
          const GroupTitle('Mes parties'),
          Card(
            child: Column(
              children: [
                for (final a in attempts.take(10))
                  ListTile(
                    leading: IconTile(
                      a.isRepeat ? Icons.replay_rounded : Icons.flag_rounded,
                      size: 38,
                    ),
                    title: Text(
                      '${formatPercent(a.performance)} · S&P 500 '
                      '${formatPercent(a.spyPerformance)}',
                      style: textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      '${a.isRepeat ? 'Rejouée' : 'Première partie'} · jouée le '
                      '${formatDate(a.playedAt)} · ${a.tradesCount} ordre(s)'
                      '${a.stoppedEarly ? ' · arrêtée le ${formatDate(a.endDate)}' : ''}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
