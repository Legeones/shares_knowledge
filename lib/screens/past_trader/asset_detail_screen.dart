import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/past_trader/trading.dart';
import '../../providers/past_trader/trader_game_controller.dart';
import '../../widgets/past_trader/news_widgets.dart';
import '../../widgets/simple_line_chart.dart';
import 'order_sheet.dart';
import '../../widgets/glass.dart';
import '../../widgets/rule_sheet.dart';
import '../../models/position_rule.dart';

/// Fiche d'un actif : description, cours passés, position, ordres.
class AssetDetailScreen extends StatelessWidget {
  final String symbol;
  const AssetDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TraderGameController>();
    final game = controller.game;
    final asset = game.data.asset(symbol);
    final price = game.priceOf(symbol);
    final position = game.positions[symbol];
    final textTheme = Theme.of(context).textTheme;
    final related = controller.news.forSymbol(symbol, game.current);

    Future<void> order(TradeSide side) => showOrderSheet(
      context,
      controller: controller,
      symbol: symbol,
      name: asset.name,
      side: side,
    );

    final canTrade =
        !game.isFinished && game.isListed(symbol) && game.isMarketOpen(symbol);

    return LargeTitleScaffold(
      title: asset.name,
      body: ListView(
        padding: pagePadding(context, top: 4),
        children: [
          PageTitle(asset.name),
          Text(asset.description),
          const SizedBox(height: 12),
          if (price == null)
            const Text('Cet actif n’est pas encore coté à cette date.')
          else ...[
            Text(
              formatMoney(price, 'USD'),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Cours de clôture au ${formatDate(game.current)}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                for (final (label, days) in const [
                  ('1 mois', 30),
                  ('6 mois', 182),
                  ('1 an', 365),
                ])
                  _Change(label: label, change: game.changeOver(symbol, days)),
              ],
            ),
            const SizedBox(height: 8),
            // Seulement le passé : de juillet 2017 au jour courant.
            SimpleLineChart(
              points: [
                for (final p in game.visiblePrices(symbol))
                  (date: p.date, value: p.close),
              ],
              color: AppColors.turquoise,
            ),
          ],
          if (position != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ma position', style: textTheme.titleMedium),
                    Text('${formatUnits(position.units)} part(s)'),
                    Text(
                      'Valeur : ${formatMoney(game.positionValue(symbol), 'USD')}',
                    ),
                    Text(
                      'Prix moyen d’achat : '
                      '${formatMoney(position.averagePrice, 'USD')}',
                    ),
                    _Change(
                      label: 'Plus-value latente',
                      change: game.positionValue(symbol) / position.cost - 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ruleText(game.rules[symbol]) ??
                          'Aucune vente automatique.',
                      style: textTheme.bodySmall,
                    ),
                    if (!game.isFinished)
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () async {
                          final rule = await showRuleSheet(
                            context,
                            rule:
                                game.rules[symbol] ??
                                PositionRule(symbol: symbol),
                            assetName: asset.name,
                            averagePrice: position.averagePrice,
                          );
                          if (rule != null) controller.setRule(rule);
                        },
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Stop-loss et objectif'),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (price != null && !canTrade && !game.isFinished)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Marché fermé aujourd’hui (week-end ou jour férié) : '
                'avance le temps pour passer un ordre.',
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: canTrade && game.cash > 0.01
                      ? () => order(TradeSide.buy)
                      : null,
                  child: const Text('Acheter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: canTrade && position != null
                      ? () => order(TradeSide.sell)
                      : null,
                  child: const Text('Vendre'),
                ),
              ),
            ],
          ),
          // Actualités liées à cet actif, connues à la date courante.
          if (related.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Actualités liées', style: textTheme.titleMedium),
            for (final n in related.take(5)) NewsTile(item: n),
          ],
        ],
      ),
    );
  }
}

/// Variation affichée avec son signe et sa couleur.
class _Change extends StatelessWidget {
  final String label;
  final double? change;
  const _Change({required this.label, required this.change});

  @override
  Widget build(BuildContext context) {
    final c = change;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label : '),
          TextSpan(
            text: c == null ? '—' : formatPercent(c),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c == null
                  ? null
                  : c >= 0
                  ? AppColors.gain
                  : AppColors.loss,
            ),
          ),
        ],
      ),
    );
  }
}
