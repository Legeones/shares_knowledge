import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/learn/lessons.dart';
import '../../core/theme.dart';
import '../../data/repositories/price_repository.dart';
import '../../logic/returns.dart';
import '../../logic/risk.dart';
import '../../models/simulation.dart';
import '../../providers/playground/playground_provider.dart';
import '../../providers/playground/saves_provider.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/glass.dart';
import '../../widgets/playground/value_chart.dart';
import '../learn/learn_screen.dart';
import 'replay_screen.dart';

/// Relance une simulation déjà connue (sauvegarde, « Reprendre ») et ouvre
/// l'écran de résultat.
void openSimulation(BuildContext context, SimulationParams params) {
  context.read<PlaygroundProvider>().simulate(params, isNewRun: false);
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const SimulationResultScreen()));
}

/// Résultat d'une simulation du Playground.
class SimulationResultScreen extends StatelessWidget {
  const SimulationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlaygroundProvider>().state;

    return LargeTitleScaffold(
      title: 'Résultat',
      actions: [
        if (state is PlaygroundSuccess)
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Sauvegarder',
            onPressed: () => _save(context, state.result),
          ),
      ],
      body: switch (state) {
        PlaygroundIdle() => const SizedBox.shrink(),
        PlaygroundLoading(:final params) => _Loading(params: params),
        PlaygroundFailure(:final message) => _Failure(message: message),
        PlaygroundSuccess(:final result, :final data) => _Success(
          result: result,
          data: data,
        ),
      },
    );
  }
}

Future<void> _save(BuildContext context, SimulationResult result) async {
  final p = result.params;
  final name = await askText(
    context,
    title: 'Sauvegarder la simulation',
    label: 'Nom',
    // Nom proposé par défaut : actif, montant et années.
    initialValue:
        '${p.asset.name} · ${formatMoney(p.amount, p.asset.currency)}'
        '${p.isMonthly ? '/mois' : ''} · '
        '${result.actualStart.year} → ${result.actualEnd.year}',
  );
  if (name == null || !context.mounted) return; // annulé, ou écran fermé
  await context.read<SavesProvider>().save(name, result);
  if (!context.mounted) return;
  showGlassMessage(
    ScaffoldMessenger.of(context),
    '« $name » sauvegardée.',
    icon: Icons.bookmark_added_rounded,
    color: AppColors.blue,
  );
}

class _Loading extends StatelessWidget {
  final SimulationParams params;
  const _Loading({required this.params});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Récupération des cours de ${params.asset.name}…'),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  final String message;
  const _Failure({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<PlaygroundProvider>().retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Modifier les paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  final SimulationResult result;
  final PriceData data;
  const _Success({required this.result, required this.data});

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    final asset = result.params.asset;
    final cur = asset.currency;
    final textTheme = Theme.of(context).textTheme;
    final isGain = result.gain >= 0;
    final gainColor = isGain ? AppColors.gain : AppColors.loss;
    final monthly = result.params.isMonthly;

    return ListView(
      padding: pagePadding(context, top: 4),
      children: [
        const PageTitle('Résultat'),
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${asset.name} (${asset.symbol})', style: hero.titleMedium),
              Text(
                'Du ${formatDate(result.actualStart)} au '
                '${formatDate(result.actualEnd)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (monthly)
                Text(
                  '${formatMoney(result.params.amount, cur)} par mois · '
                  '${result.payments} versements',
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(result.finalValue, cur),
                  style: hero.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              HeroPill(
                child: Text(
                  '${formatSignedMoney(result.gain, cur)} · '
                  '${formatPercent(result.performance)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (result.periodWasAdjusted)
          _Notice(
            icon: Icons.info_outline,
            text:
                'Dates ajustées aux jours de bourse : demandé du '
                '${formatDate(result.params.start)} au '
                '${formatDate(result.params.end)}.',
          ),
        if (data.isFallback)
          _Notice(
            icon: Icons.cloud_off,
            text:
                'Données incomplètes : ${data.fallbackReason?.message} '
                'Résultat calculé avec les cours déjà enregistrés.',
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Row(
                  monthly ? 'Total versé' : 'Montant investi',
                  formatMoney(result.totalInvested, cur),
                ),
                _Row('Valeur finale', formatMoney(result.finalValue, cur)),
                const Divider(),
                _Row(
                  isGain ? 'Gain' : 'Perte',
                  formatSignedMoney(result.gain, cur),
                  color: gainColor,
                  bold: true,
                ),
                _Row(
                  'Performance',
                  formatPercent(result.performance),
                  color: gainColor,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ValueChart(result: result),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReplayScreen(result: result)),
          ),
          icon: const Icon(Icons.wb_sunny_outlined),
          label: const Text('Rejouer dans le temps'),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (monthly) ...[
                  _Row('Versements', '${result.payments}'),
                  _Row(
                    'Premier cours',
                    formatMoney(result.history.first.price, cur),
                  ),
                  _Row(
                    'Prix moyen d’achat',
                    formatMoney(result.averageCost, cur),
                  ),
                ] else
                  _Row(
                    'Prix d’achat',
                    formatMoney(result.history.first.price, cur),
                  ),
                _Row('Quantité achetée', formatUnits(result.units)),
                _Row('Prix final', formatMoney(result.history.last.price, cur)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const GroupTitle('Comprendre ce résultat'),
        _Insights(result: result),
        const SizedBox(height: 16),
        Text(
          'Cours de clôture quotidiens réels (Twelve Data), en $cur. '
          'Données téléchargées le ${formatDate(data.updatedAt)}. '
          'Sans frais, dividendes ni fiscalité. '
          'Un résultat passé ne prédit pas l’avenir.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Les notions des leçons appliquées à ce résultat, chacune avec un lien
/// vers sa leçon.
class _Insights extends StatelessWidget {
  final SimulationResult result;
  const _Insights({required this.result});

  @override
  Widget build(BuildContext context) {
    final cur = result.params.asset.currency;
    final monthly = result.params.isMonthly;
    String money(double v) => formatMoney(v, cur);
    String pct(double r) => formatPercent(r, signed: false);

    final days = result.actualEnd.difference(result.actualStart).inDays;
    // En mensuel, l'argent n'est pas resté investi toute la période : un
    // taux « par an » sur le total serait trompeur.
    final annual = monthly
        ? null
        : annualizedReturn(
            invested: result.totalInvested,
            finalValue: result.finalValue,
            days: days,
          );
    final yearly = yearlyValues(
      [for (final p in result.history) p.date],
      [for (final p in result.history) p.price],
    );
    final dd = result.maxDrawdown;
    final years = (days / 365.25).toStringAsFixed(1).replaceAll('.', ',');

    final insights = [
      _Insight(
        label: 'Performance',
        value: formatPercent(result.performance),
        note:
            'Le gain (${formatSignedMoney(result.gain, cur)}) rapporté à la '
            'somme versée : c’est ce qui permet de comparer des placements de '
            'tailles différentes.',
        lesson: returnLesson,
      ),
      if (annual != null)
        _Insight(
          label: 'Rendement annualisé',
          value: '${formatPercent(annual)} par an',
          note:
              'Le taux qui, composé chaque année, mène de '
              '${money(result.totalInvested)} à ${money(result.finalValue)} '
              'en $years ans.',
          lesson: compoundLesson,
        ),
      if (monthly)
        _Insight(
          label: 'En une fois, le premier jour',
          value: money(result.lumpSumFinalValue),
          note: result.lumpSumFinalValue > result.finalValue
              ? 'Placer les ${money(result.totalInvested)} dès le premier '
                    'jour aurait rapporté plus : le cours a surtout monté.'
              : 'Les versements mensuels ont rapporté plus : ils ont acheté '
                    'des parts moins chères pendant les baisses (prix moyen '
                    '${money(result.averageCost)}).',
          lesson: dcaLesson,
        ),
      // Au moins deux années complètes pour mesurer un écart type.
      if (yearly.length >= 3)
        _Insight(
          label: 'Volatilité du cours',
          value: '${pct(volatility(yearly))} par an',
          note:
              'Écart type des rendements de l’actif d’une année à l’autre, '
              'sur ${yearly.length - 1} années complètes. Pire année : '
              '${formatPercent(worstReturn(yearly))}.',
          lesson: volatilityLesson,
        ),
      _Insight(
        label: monthly ? 'Baisse maximale du cours' : 'Baisse maximale',
        value: dd == 0 ? 'aucune' : '−${pct(dd)}',
        valueColor: dd == 0 ? null : AppColors.loss,
        note: dd == 0
            ? 'Le cours n’a jamais baissé sous son dernier sommet.'
            : dd >= 1
            ? 'Le cours est tombé à zéro.'
            : 'La pire chute entre un sommet et le creux suivant. Pour la '
                  'rattraper, il fallait ensuite '
                  '${formatPercent(recoveryGain(dd))}.',
        lesson: drawdownLesson,
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (final (i, insight) in insights.indexed) ...[
            if (i > 0) const Divider(height: 1),
            insight,
          ],
        ],
      ),
    );
  }
}

/// Une notion : sa valeur, une phrase d'explication et un lien vers la leçon.
class _Insight extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final LessonInfo lesson;
  final Color? valueColor;

  const _Insight({
    required this.label,
    required this.value,
    required this.note,
    required this.lesson,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: textTheme.titleSmall)),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(color: valueColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => openLesson(context, lesson),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: Text('Leçon « ${lesson.title} »'),
          ),
        ],
      ),
    );
  }
}

/// Une ligne « libellé ……… valeur ».
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _Row(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontWeight: bold ? FontWeight.bold : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Encadré d'information (dates ajustées, données de secours).
class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
