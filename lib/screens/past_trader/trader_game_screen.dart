import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/past_trader/news_feed.dart';
import '../../logic/time_cursor.dart';
import '../../logic/past_trader/trading.dart';
import '../../models/asset.dart';
import '../../models/past_trader/news.dart';
import '../../models/past_trader/past_trader.dart';
import '../../models/past_trader/trader_save.dart';
import '../../providers/settings_provider.dart';
import '../../providers/past_trader/trader_game_controller.dart';
import '../../providers/past_trader/trader_save_provider.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/past_trader/news_widgets.dart';
import '../../widgets/simple_line_chart.dart';
import '../../widgets/glass.dart';
import '../../widgets/sky_header.dart';
import 'asset_detail_screen.dart';
import 'trader_debrief_screen.dart';

/// Une partie Past Trader. Crée le contrôleur de la partie et le partage
/// avec les écrans ouverts depuis celui-ci (fiche d'un actif, ordres).
class TraderGameScreen extends StatelessWidget {
  final TraderGameData data;
  final NewsFeed news;

  /// Partie quittée à reprendre ; null = nouvelle partie.
  final TraderSave? resume;

  const TraderGameScreen({
    super.key,
    required this.data,
    required this.news,
    this.resume,
  });

  @override
  Widget build(BuildContext context) {
    final save = resume;
    return ChangeNotifierProvider(
      create: (_) => save == null
          ? TraderGameController(data, news)
          : TraderGameController.resume(data, news, save),
      child: const _GameView(),
    );
  }
}

/// Vitesses de la lecture automatique, en jours par seconde.
const _speeds = [
  (label: 'Lent', daysPerSecond: 3.0),
  (label: 'Moyen', daysPerSecond: 10.0),
  (label: 'Rapide', daysPerSecond: 30.0),
];

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> with TickerProviderStateMixin {
  late final AnimationController _sky = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  /// Lecture automatique : la valeur 0 → 1 parcourt les jours restants.
  late final AnimationController _playback = AnimationController(vsync: this)
    ..addListener(_onFrame)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _pause();
    });

  /// Onglets : 0 Marché, 1 Portefeuille, 2 Ordres, 3 Actualités.
  late final TabController _tabs = TabController(length: 4, vsync: this)
    ..addListener(() {
      if (_tabs.index == 3) _controller.markNewsRead();
    });

  DateTime _playFrom = DateTime.utc(2000);
  int _playDays = 0;
  int _speed = 1;

  TraderGameController get _controller => context.read<TraderGameController>();
  bool get _isPlaying => _playback.isAnimating;

  /// L'application passe en arrière-plan (ou est fermée) : on enregistre,
  /// la partie pourra être reprise même si le système arrête l'application.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: _save,
  );

  /// Vrai une fois le bilan ouvert : il n'y a plus rien à reprendre.
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _lifecycle; // crée l'écouteur
  }

  Future<void> _save() async {
    if (_ended) return;
    await context.read<TraderSaveProvider?>()?.save(
      _controller.snapshot(DateTime.now()),
    );
  }

  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations ||
      (context.read<SettingsProvider?>()?.reduceAnimations ?? false);

  @override
  void dispose() {
    _lifecycle.dispose();
    _playback.dispose();
    _sky.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onFrame() {
    final day = (_playback.value * _playDays).floor();
    _controller.advanceTo(_playFrom.add(Duration(days: day)));
    _showFlashes(resumeAfter: true);
  }

  /// Actualité majeure tombée : pause, « flash info », puis reprise.
  Future<void> _showFlashes({bool resumeAfter = false}) async {
    if (!_controller.hasFlash) return;
    final wasPlaying = _isPlaying;
    if (wasPlaying) _pause();
    await showFlashNews(context, _controller.takeFlashes());
    if (!mounted) return;
    if (_tabs.index == 3) _controller.markNewsRead();
    if (resumeAfter && wasPlaying) _play();
  }

  void _play() {
    final game = _controller.game;
    _playFrom = game.current;
    _playDays = game.data.end.difference(game.current).inDays;
    if (_playDays <= 0) return;
    _playback.duration = Duration(
      milliseconds: (_playDays / _speeds[_speed].daysPerSecond * 1000).round(),
    );
    _playback.forward(from: 0);
    if (!_reduceMotion) _sky.repeat();
    setState(() {});
  }

  void _pause() {
    _playback.stop();
    if (_sky.isAnimating) _sky.forward();
    if (mounted) setState(() {});
  }

  void _step(TimeStep step) {
    if (_isPlaying) _pause();
    _controller.advance(step);
    _showFlashes();
  }

  void _openAsset(String symbol) {
    if (_isPlaying) _pause(); // on ne laisse pas filer le temps en coulisses
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Le même contrôleur est transmis à la fiche de l'actif.
        builder: (_) => ChangeNotifierProvider.value(
          value: _controller,
          child: AssetDetailScreen(symbol: symbol),
        ),
      ),
    );
  }

  /// Remplace la partie par son bilan (la partie n'est plus jouable).
  void _openDebrief() {
    if (_isPlaying) _pause();
    _ended = true;
    context.read<TraderSaveProvider?>()?.clear();
    final controller = _controller;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            TraderDebriefScreen(game: controller.game, news: controller.news),
      ),
    );
  }

  Future<void> _confirmStop() async {
    if (_isPlaying) _pause();
    final stop = await confirmAction(
      context,
      title: 'Arrêter la partie ?',
      message:
          'Le bilan sera fait à la date d’aujourd’hui dans le jeu. Tu ne '
          'pourras plus passer d’ordre.',
      confirmLabel: 'Voir le bilan',
    );
    if (!stop || !mounted) return;
    _controller.stop();
    _openDebrief();
  }

  /// Quitter : la partie est enregistrée, on la reprendra depuis l'onglet.
  Future<void> _quit() async {
    if (_isPlaying) _pause();
    final messenger = ScaffoldMessenger.of(context);
    await _save();
    if (!mounted) return;
    Navigator.of(context).pop();
    showGlassMessage(
      messenger,
      'Partie sauvegardée : reprends-la depuis Past Trader.',
      icon: Icons.bookmark_added_rounded,
      color: AppColors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TraderGameController>();
    final game = controller.game;
    final weekend = !game.isMarketOpen('SPY');

    // PopScope : le retour arrière enregistre la partie avant de partir.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quit();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text('Past Trader'),
          actions: [
            IconButton(
              tooltip: 'Arrêter et voir le bilan',
              icon: const Icon(Icons.flag_outlined),
              onPressed: game.isFinished ? _openDebrief : _confirmStop,
            ),
          ],
        ),
        body: Column(
          children: [
            // Le ciel commence juste sous la barre : sa lumière la traverse.
            SizedBox(height: glassBarInset(context)),
            SkyHeader(
              height: 90,
              cycle: _sky,
              child: _DateLabel(date: game.current, weekend: weekend),
            ),
            _Summary(game: game),
            _Headline(
              item: controller.knownNews.firstOrNull,
              onTap: () => _tabs.animateTo(3),
            ),
            // Onglets en « segmented control » : une pilule blanche glisse
            // sur un fond gris (voir tabBarTheme dans core/theme.dart).
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabs,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  const Tab(height: 36, text: 'Marché'),
                  const Tab(height: 36, text: 'Portefeuille'),
                  const Tab(height: 36, text: 'Ordres'),
                  Tab(
                    height: 36,
                    // Badge : nombre d'actualités pas encore lues.
                    child: Badge(
                      isLabelVisible: controller.unreadCount > 0,
                      label: Text('${controller.unreadCount}'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Actus'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MarketTab(game: game, onOpen: _openAsset),
                  _PortfolioTab(game: game, onOpen: _openAsset),
                  _TradesTab(game: game),
                  _NewsTab(items: controller.knownNews),
                ],
              ),
            ),
            if (game.isFinished)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FilledButton.icon(
                  onPressed: _openDebrief,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Partie terminée : voir le bilan'),
                ),
              ),
            _TimeBar(
              finished: game.isFinished,
              playing: _isPlaying,
              speed: _speed,
              onStep: _step,
              onPlay: _isPlaying ? _pause : _play,
              onSpeed: (i) => setState(() => _speed = i),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau du dernier titre de l'actualité.
class _Headline extends StatelessWidget {
  final NewsItem? item;
  final VoidCallback onTap;
  const _Headline({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            const Icon(Icons.newspaper, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${formatDate(item.date)} · ${item.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  final List<NewsItem> items;
  const _NewsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => NewsTile(item: items[i]),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  final bool weekend;
  const _DateLabel({required this.date, required this.weekend});

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(blurRadius: 6, color: Colors.black54)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatDateWithWeekday(date),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: shadow,
          ),
        ),
        if (weekend)
          const Text(
            'Bourse fermée · cryptos ouvertes',
            style: TextStyle(color: Colors.white, shadows: shadow),
          ),
      ],
    );
  }
}

/// Valeur totale, cash, gain : toujours visibles en haut.
class _Summary extends StatelessWidget {
  final TraderGame game;
  const _Summary({required this.game});

  @override
  Widget build(BuildContext context) {
    final isGain = game.gain >= 0;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valeur totale', style: textTheme.labelMedium),
                  Text(
                    formatMoney(game.totalValue, 'USD'),
                    style: textTheme.headlineSmall,
                  ),
                  Text(
                    '${formatSignedMoney(game.gain, 'USD')} '
                    '(${formatPercent(game.performance)})',
                    style: TextStyle(
                      color: isGain ? AppColors.gain : AppColors.loss,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Cash', style: textTheme.labelMedium),
                Text(
                  formatMoney(game.cash, 'USD'),
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _typeIcons = {
  AssetType.stock: Icons.business_outlined,
  AssetType.etf: Icons.pie_chart_outline,
  AssetType.crypto: Icons.currency_bitcoin,
};

class _MarketTab extends StatelessWidget {
  final TraderGame game;
  final ValueChanged<String> onOpen;
  const _MarketTab({required this.game, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: game.data.assets.length,
      itemBuilder: (context, i) {
        final asset = game.data.assets[i];
        final price = game.priceOf(asset.symbol);
        final change = game.changeOver(asset.symbol, 30);
        final held = game.positions.containsKey(asset.symbol);
        return ListTile(
          leading: IconTile(_typeIcons[asset.type]!, size: 38),
          title: Text(
            asset.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            held ? '${asset.symbol} · en portefeuille' : asset.symbol,
          ),
          trailing: price == null
              ? const Text('pas encore coté')
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatMoney(price, 'USD')),
                    if (change != null)
                      Text(
                        '${formatPercent(change)} sur 1 mois',
                        style: TextStyle(
                          fontSize: 12,
                          color: change >= 0 ? AppColors.gain : AppColors.loss,
                        ),
                      ),
                  ],
                ),
          onTap: () => onOpen(asset.symbol),
        );
      },
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  final TraderGame game;
  final ValueChanged<String> onOpen;
  const _PortfolioTab({required this.game, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final total = game.totalValue;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Évolution de mon portefeuille',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SimpleLineChart(points: game.history, reference: game.data.initialCash),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.savings_outlined),
          title: const Text('Cash'),
          trailing: Text(
            '${formatMoney(game.cash, 'USD')} · '
            '${formatPercent(game.cash / total, signed: false)}',
          ),
        ),
        for (final MapEntry(key: symbol, value: p) in game.positions.entries)
          ListTile(
            leading: Icon(_typeIcons[game.data.asset(symbol).type]),
            title: Text(game.data.asset(symbol).name),
            subtitle: Text(
              'Plus-value latente : '
              '${formatPercent(game.positionValue(symbol) / p.cost - 1)}',
            ),
            trailing: Text(
              '${formatMoney(game.positionValue(symbol), 'USD')} · '
              '${formatPercent(game.positionValue(symbol) / total, signed: false)}',
            ),
            onTap: () => onOpen(symbol),
          ),
        if (game.positions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucune position : tout est en cash. Va dans « Marché » pour '
              'choisir un actif.',
            ),
          ),
      ],
    );
  }
}

class _TradesTab extends StatelessWidget {
  final TraderGame game;
  const _TradesTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final trades = game.trades.reversed.toList();
    if (trades.isEmpty) {
      return const Center(child: Text('Aucun ordre passé pour l’instant.'));
    }
    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (context, i) {
        final t = trades[i];
        final isBuy = t.side == TradeSide.buy;
        return ListTile(
          leading: Icon(
            isBuy ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isBuy ? AppColors.blue : AppColors.turquoise,
          ),
          title: Text(
            '${isBuy ? 'Achat' : 'Vente'} ${game.data.asset(t.symbol).name} · '
            '${formatMoney(t.amount, 'USD')}',
          ),
          subtitle: Text(
            '${formatDate(t.date)} à ${formatMoney(t.price, 'USD')}'
            '${isBuy ? '' : ' · plus-value ${formatSignedMoney(t.realizedGain, 'USD')}'}',
          ),
        );
      },
    );
  }
}

/// Barre d'avancée du temps : +1 jour / +7 jours / +1 mois, lecture, vitesse.
class _TimeBar extends StatelessWidget {
  final bool finished;
  final bool playing;
  final int speed;
  final ValueChanged<TimeStep> onStep;
  final VoidCallback onPlay;
  final ValueChanged<int> onSpeed;

  const _TimeBar({
    required this.finished,
    required this.playing,
    required this.speed,
    required this.onStep,
    required this.onPlay,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    tooltip: playing ? 'Pause' : 'Lecture',
                    onPressed: finished ? null : onPlay,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 4),
                  for (final (s, label) in const [
                    (TimeStep.day, '+1 j'),
                    (TimeStep.week, '+7 j'),
                    (TimeStep.month, '+1 mois'),
                  ]) ...[
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: finished ? null : () => onStep(s),
                        child: Text(label),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  for (final (i, s) in _speeds.indexed)
                    ButtonSegment(
                      value: i,
                      label: Text(
                        '${s.label} · ${s.daysPerSecond.round()} j/s',
                      ),
                    ),
                ],
                selected: {speed},
                onSelectionChanged: (s) => onSpeed(s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
