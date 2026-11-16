import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/past_trader/news_feed.dart';
import '../../logic/taxes.dart';
import '../../logic/past_trader/trading.dart';
import '../../providers/settings_provider.dart';
import '../../providers/past_trader/trader_attempts_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/tax_profile_picker.dart';
import 'trader_game_screen.dart';

/// Bilan d'une partie Past Trader terminée.
class TraderDebriefScreen extends StatefulWidget {
  final TraderGame game;
  final NewsFeed news;

  const TraderDebriefScreen({
    super.key,
    required this.game,
    required this.news,
  });

  @override
  State<TraderDebriefScreen> createState() => _TraderDebriefScreenState();
}

class _TraderDebriefScreenState extends State<TraderDebriefScreen> {
  late TaxProfile _tax =
      context.read<SettingsProvider?>()?.taxProfile(
        defaultCountryCode:
            WidgetsBinding.instance.platformDispatcher.locale.countryCode,
      ) ??
      TaxProfile(taxCountryFor('FR'));

  /// Première partie de ce jeu, ou répétition ? (lu avant d'enregistrer)
  late final bool _isRepeat;

  TraderGame get _game => widget.game;

  @override
  void initState() {
    super.initState();
    final attempts = context.read<TraderAttemptsProvider?>();
    _isRepeat = attempts?.items.any((a) => a.gameId == _game.data.id) ?? false;
    attempts?.record(_game); // la partie est enregistrée une seule fois
  }

  void _setTax(TaxProfile profile) {
    setState(() => _tax = profile);
    context.read<SettingsProvider?>()?.setTaxProfile(profile);
  }

  void _replay() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TraderGameScreen(data: _game.data, news: widget.news),
      ),
    );
  }

  String _usd(double v) => formatMoney(v, 'USD');

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    final textTheme = Theme.of(context).textTheme;
    final initial = _game.data.initialCash;
    final spy = _game.buyAndHoldSpy;
    final spyPerf = spy / initial - 1;
    final dd = _game.drawdown;
    final history = _game.history;
    final assets = _game.buyAndHoldPerformances().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final taxes = computeAnnualTaxes(_game.taxableGains(), _tax);
    final beatSpy = _game.performance > spyPerf;

    return LargeTitleScaffold(
      title: 'Bilan de ta partie',
      body: ListView(
        padding: pagePadding(context, top: 4),
        children: [
          const PageTitle('Bilan de ta partie'),
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HeroPill(
                      child: Text(
                        _isRepeat ? 'Partie rejouée' : 'Première partie',
                      ),
                    ),
                    if (_game.stoppedEarly)
                      HeroPill(
                        child: Text('Arrêtée le ${formatDate(_game.current)}'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Du ${formatDate(_game.data.start)} au '
                  '${formatDate(_game.current)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(_usd(_game.totalValue), style: hero.displaySmall),
                ),
                Text(
                  '${formatSignedMoney(_game.gain, 'USD')} '
                  '(${formatPercent(_game.performance)}) avant impôts',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Comparaison --------------------------------------------------
          _Section(
            title: 'Face à des stratégies simples',
            children: [
              _CompareRow('Toi', _game.performance, highlight: true),
              _CompareRow('Tout en S&P 500 dès le départ', spyPerf),
              const _CompareRow('Tout garder en cash', 0),
              const SizedBox(height: 8),
              Text(
                beatSpy
                    ? 'Tu as fait mieux que l’indice. Un bon résultat isolé ne '
                          'prouve pas une maîtrise : rejoue et vois si tu fais '
                          'pareil.'
                    : 'Battre un simple achat de l’indice est difficile : sur '
                          'la durée, la plupart des investisseurs, même '
                          'professionnels, n’y arrivent pas.',
              ),
            ],
          ),

          // --- Courbe -------------------------------------------------------
          _Section(
            title: 'Ton parcours',
            children: [
              _DebriefChart(game: _game),
              const SizedBox(height: 4),
              const Wrap(
                spacing: 12,
                children: [
                  _Legend(AppColors.blue, 'Ton portefeuille'),
                  _Legend(AppColors.turquoise, 'S&P 500 gardé'),
                  _Legend(Colors.green, 'Achat'),
                  _Legend(Colors.orange, 'Vente'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dd.depth == 0
                    ? 'Ton portefeuille n’a jamais baissé.'
                    : 'Pire chute : −${formatPercent(dd.depth, signed: false)} '
                          'entre le ${formatDate(history[dd.peakIndex].date)} '
                          'et le ${formatDate(history[dd.troughIndex].date)}.',
              ),
              Text(
                '${_game.trades.length} ordre(s) passé(s) · plus-values '
                'réalisées : ${formatSignedMoney(_game.realizedGains, 'USD')}',
              ),
            ],
          ),

          // --- Révélation ---------------------------------------------------
          _Section(
            title: 'Ce que chaque actif a fait',
            children: [
              Text(
                'Acheté le premier jour et gardé jusqu’au '
                '${formatDate(_game.current)} :',
                style: textTheme.bodySmall,
              ),
              for (final e in assets)
                _CompareRow(_game.data.asset(e.key).name, e.value),
            ],
          ),

          // --- Impôts -------------------------------------------------------
          _Section(
            title: 'Et les impôts ?',
            children: [
              TaxProfilePicker(profile: _tax, onChanged: _setTax),
              const SizedBox(height: 12),
              for (final y in taxes.years)
                Text(
                  '${y.year} : gains nets ${formatSignedMoney(y.netGain, 'USD')}'
                  ' → impôt ${_usd(y.tax)}',
                ),
              const SizedBox(height: 4),
              Text(
                'Après impôts : ${_usd(_game.totalValue - taxes.totalTax)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Impôts au total : ${_usd(taxes.totalTax)}'),
              if (taxes.lossCarriedForward < 0)
                Text(
                  'Pertes reportables sur les années suivantes : '
                  '${_usd(-taxes.lossCarriedForward)}',
                ),
              const SizedBox(height: 8),
              Text(_tax.explanation),
              const SizedBox(height: 8),
              Text(
                'Les positions encore ouvertes sont considérées comme vendues '
                'le ${formatDate(_game.current)}. Les pertes d’une année '
                'compensent ses gains ; l’excédent est reporté. Règles très '
                'simplifiées, à titre d’illustration : ce n’est pas un '
                'conseil fiscal.',
                style: textTheme.bodySmall,
              ),
            ],
          ),

          FilledButton.icon(
            onPressed: _replay,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            icon: const Icon(Icons.replay),
            label: const Text('Rejouer la partie'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Une ligne « libellé ……… +12,34 % ».
class _CompareRow extends StatelessWidget {
  final String label;
  final double performance;
  final bool highlight;
  const _CompareRow(this.label, this.performance, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: highlight
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          Text(
            formatPercent(performance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: performance >= 0 ? AppColors.gain : AppColors.loss,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Valeur du portefeuille, S&P 500 gardé, et les ordres marqués d'un point.
class _DebriefChart extends StatelessWidget {
  final TraderGame game;
  const _DebriefChart({required this.game});

  @override
  Widget build(BuildContext context) {
    final history = game.history;
    final start = history.first.date;
    double x(DateTime d) => d.difference(start).inDays.toDouble();

    // S&P 500 : même somme placée le premier jour.
    final spyPrices = game.visiblePrices('SPY');
    final spyStart = spyPrices.firstWhere((p) => !p.date.isBefore(start));
    final spyLine = [
      for (final p in spyPrices)
        if (!p.date.isBefore(start))
          FlSpot(x(p.date), game.data.initialCash / spyStart.close * p.close),
    ];
    final portfolio = [for (final p in history) FlSpot(x(p.date), p.value)];

    // Un point par ordre, posé sur la courbe du portefeuille ce jour-là.
    final trades = game.trades;
    final tradeSpots = [
      for (final t in trades)
        // L'historique a une valeur par jour : son indice = jours écoulés.
        FlSpot(
          x(t.date),
          history[x(t.date).toInt().clamp(0, history.length - 1)].value,
        ),
    ];

    final values = [...portfolio.map((s) => s.y), ...spyLine.map((s) => s.y)];
    final low = values.reduce(min);
    final high = values.reduce(max);
    final compact = NumberFormat.compact(locale: 'fr_FR');

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: max(0, low * 0.95),
            maxY: high * 1.05,
            lineBarsData: [
              LineChartBarData(
                spots: spyLine,
                color: AppColors.turquoise,
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: portfolio,
                color: AppColors.blue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
              // Courbe invisible : seuls ses points (les ordres) sont dessinés.
              LineChartBarData(
                spots: tradeSpots,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                    radius: 3.5,
                    color: trades[i].side == TradeSide.buy
                        ? Colors.green
                        : Colors.orange,
                    strokeWidth: 0,
                  ),
                ),
              ),
            ],
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                      ? const SizedBox.shrink()
                      : SideTitleWidget(
                          meta: meta,
                          child: Text(
                            compact.format(v),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  // ≈ 4 dates sous l'axe, quelle que soit la durée jouée.
                  interval: max(30, x(history.last.date) / 4),
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DateFormat('MM/yy')
                                .format(start.add(Duration(days: v.round()))),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                ),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}
