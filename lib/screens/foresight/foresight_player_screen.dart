import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/foresight/foresight.dart';
import '../../logic/taxes.dart';
import '../../logic/time_cursor.dart';
import '../../models/foresight/foresight.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/foresight/foresight_charts.dart';
import '../../widgets/glass.dart';
import '../../widgets/sky_header.dart';
import '../home/intro_screen.dart';
import 'chapter_sheet.dart';
import 'foresight_debrief_screen.dart';

/// Rejeu du parcours « clairvoyant » : lecture automatique, pause, saut
/// d'étape, +1 jour / +7 jours / +1 mois.
///
/// [firstLaunch] : ouvert automatiquement au premier démarrage ; « Passer »
/// mène alors à l'introduction de l'application.
class ForesightPlayerScreen extends StatefulWidget {
  final ForesightScenario scenario;
  final bool firstLaunch;

  const ForesightPlayerScreen({
    super.key,
    required this.scenario,
    this.firstLaunch = false,
  });

  @override
  State<ForesightPlayerScreen> createState() => _ForesightPlayerScreenState();
}

class _ForesightPlayerScreenState extends State<ForesightPlayerScreen>
    with TickerProviderStateMixin {
  /// Situation fiscale du profil (`?` : absente dans certains tests).
  late final TaxProfile? _tax = context.read<SettingsProvider?>()?.taxProfile();

  /// Le parcours tel qu'il aurait été vécu : impôts du profil, retraits
  /// pour vivre et réserve plafonnée.
  late final ForesightRun _run = livedRun(
    widget.scenario,
    taxRate: _tax?.rateFor,
  );
  int _dayIndex = 0;
  bool _started = false;

  late final int _lastIndex = _run.days.length - 1;

  /// Temps d'écran de chaque étape, selon sa durée.
  late final PlaybackTimeline _timeline = PlaybackTimeline(_run);

  /// Avancement de la lecture automatique (0 → 1 = tout le parcours).
  late final AnimationController _playback =
      AnimationController(vsync: this, duration: _timeline.total)
        ..addListener(_onFrame)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            _pause();
            _showChapter(widget.scenario.steps.length); // épilogue
          }
        });

  /// Chapitres déjà racontés : n° i = entrée dans l'étape i,
  /// n° steps.length = épilogue. Chacun n'interrompt la lecture qu'une fois.
  final Set<int> _toldChapters = {};

  /// Vrai pendant qu'un chapitre est affiché.
  bool _telling = false;

  late final AnimationController _sky = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  bool get _isPlaying => _playback.isAnimating;
  bool get _atEnd => _dayIndex == _lastIndex;
  ForesightDay get _day => _run.days[_dayIndex];

  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations ||
      (context.read<SettingsProvider?>()?.reduceAnimations ?? false);

  @override
  void dispose() {
    _playback.dispose();
    _sky.dispose();
    super.dispose();
  }

  void _onFrame() {
    final index = _timeline.dayAt(_timeline.total * _playback.value);
    if (index == _dayIndex) return;
    final step = _run.days[index].stepIndex;
    // On entre dans une nouvelle étape : pause sur son premier jour pour
    // raconter le chapitre.
    if (step != _day.stepIndex && !_toldChapters.contains(step)) {
      _showChapter(step, resumeAfter: true);
      return;
    }
    setState(() => _dayIndex = index);
  }

  void _play() {
    setState(() => _started = true);
    if (_atEnd) _dayIndex = 0;
    // Tout premier lancement : le chapitre 1 avant de démarrer.
    if (_dayIndex == 0 && !_toldChapters.contains(0)) {
      _showChapter(0, resumeAfter: true);
      return;
    }
    _resume();
  }

  void _resume() {
    final total = _timeline.total.inMilliseconds;
    _playback.forward(from: _timeline.timeOf(_dayIndex).inMilliseconds / total);
    if (!_reduceMotion) _sky.repeat();
    setState(() {});
  }

  /// Affiche le chapitre [number] (entrée dans l'étape [number], ou
  /// épilogue), puis reprend la lecture si [resumeAfter].
  /// [moveToStart] : place d'abord la date au début de l'étape.
  Future<void> _showChapter(
    int number, {
    bool resumeAfter = false,
    bool moveToStart = true,
  }) async {
    if (_telling) return;
    _telling = true;
    _toldChapters.add(number);
    final steps = widget.scenario.steps;
    final isEpilogue = number >= steps.length;

    if (_isPlaying) _pause();
    if (moveToStart) {
      setState(() {
        _dayIndex = isEpilogue ? _lastIndex : _run.indexOf(steps[number].start);
      });
    }

    await showChapterSheet(
      context,
      date: _day.date,
      number: number + 1,
      leaving: number > 0 ? _run.steps[number - 1] : null,
      entering: isEpilogue ? null : steps[number],
    );
    _telling = false;
    if (mounted && resumeAfter && !isEpilogue) _resume();
  }

  void _pause() {
    _playback.stop();
    if (_sky.isAnimating) _sky.forward(); // finit le tour, s'arrête à midi
    setState(() {});
  }

  void _goTo(int index) {
    if (_isPlaying) _pause();
    final from = _day.stepIndex;
    setState(() {
      _started = true;
      _dayIndex = index.clamp(0, _lastIndex);
    });
    // Arrivée dans une étape dont l'histoire n'a pas encore été racontée.
    final to = _day.stepIndex;
    if (to != from && !_toldChapters.contains(to)) {
      _showChapter(to, moveToStart: false);
    }
  }

  void _step(TimeStep step) => _goTo(_run.indexOf(addStep(_day.date, step)));

  void _openDebrief() {
    if (_isPlaying) _pause();
    final route = MaterialPageRoute<void>(
      builder: (_) => ForesightDebriefScreen(
        scenario: widget.scenario,
        firstLaunch: widget.firstLaunch,
      ),
    );
    if (widget.firstLaunch) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  void _skipToIntro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const IntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.scenario.currency;
    final step = widget.scenario.steps[_day.stepIndex];
    final multiple = _day.wealth / widget.scenario.initialCapital;

    return LargeTitleScaffold(
      title: 'Perfect Foresight',
      // Au premier démarrage, pas de retour possible : on « passe ».
      automaticallyImplyLeading: !widget.firstLaunch,
      actions: [
        if (widget.firstLaunch)
          TextButton(
            onPressed: _skipToIntro,
            // Pilule blanche : lisible sur l'accroche bleue comme sur la page.
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.75),
            ),
            child: const Text('Passer'),
          ),
      ],
      body: Stack(
        children: [
          ListView(
            padding: pagePadding(context, horizontal: 0, top: 4, bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PageTitle(
                  'Perfect Foresight',
                  subtitle: widget.scenario.decadeLabel,
                ),
              ),
              SkyHeader(
                cycle: _sky,
                child: _Header(
                  date: _day.date,
                  label: switch (step) {
                    AssetStep(:final name) => 'Tu détiens : $name',
                    CashStep() => 'En attente, en cash',
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: LinearProgressIndicator(
                  value: _dayIndex / _lastIndex,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CapitalCard(
                      day: _day,
                      initial: widget.scenario.initialCapital,
                      multiple: multiple,
                      currency: cur,
                    ),
                    // Fin du parcours : l'explication juste sous le résultat.
                    if (_atEnd) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.loss,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _openDebrief,
                        child: const Text(
                          'Trop beau pour être vrai ? Voir pourquoi →',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _StepChips(
                      run: _run,
                      current: _day.stepIndex,
                      currentDate: _day.date,
                      onSelect: (i) =>
                          _goTo(_run.indexOf(widget.scenario.steps[i].start)),
                    ),
                    const SizedBox(height: 12),
                    _StepCard(
                      step: step,
                      result: _run.steps[_day.stepIndex],
                      currentDate: _day.date,
                      currency: cur,
                      onReadChapter: () =>
                          _showChapter(_day.stepIndex, moveToStart: false),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Évolution du patrimoine en dollars (×10 à chaque ligne)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    WealthLogChart(
                      days: _run.days,
                      visibleCount: _dayIndex + 1,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isPlaying ? _pause : _play,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Pause' : 'Lecture automatique'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final (s, label) in const [
                          (TimeStep.day, '+1 jour'),
                          (TimeStep.week, '+7 jours'),
                          (TimeStep.month, '+1 mois'),
                        ]) ...[
                          if (s != TimeStep.day) const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: _atEnd ? null : () => _step(s),
                              child: Text(label),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _dayIndex == 0 ? null : () => _goTo(0),
                          icon: const Icon(Icons.replay),
                          label: const Text('Recommencer'),
                        ),
                        TextButton.icon(
                          onPressed: _openDebrief,
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Pourquoi c’est impossible'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Hypotheses(scenario: widget.scenario, tax: _tax),
                  ],
                ),
              ),
            ],
          ),
          if (!_started) _Splash(scenario: widget.scenario, onStart: _play),
        ],
      ),
    );
  }
}

/// Écran d'accroche avant le lancement.
class _Splash extends StatelessWidget {
  final ForesightScenario scenario;
  final VoidCallback onStart;
  const _Splash({required this.scenario, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Perfect Foresight',
                  style: textTheme.displaySmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Et si tu avais investi '
                  '${formatMoney(scenario.initialCapital, scenario.currency)} '
                  'le ${formatDate(scenario.start)}…',
                  style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '… en connaissant parfaitement le futur : les bons actifs, '
                  'les bons jours pour acheter, les bons jours pour vendre ?',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Voir ce qui se serait passé'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime date;
  final String label;
  const _Header({required this.date, required this.label});

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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: shadow,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, shadows: shadow),
        ),
      ],
    );
  }
}

class _CapitalCard extends StatelessWidget {
  final ForesightDay day;
  final double initial;
  final double multiple;
  final String currency;

  const _CapitalCard({
    required this.day,
    required this.initial,
    required this.multiple,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    String money(double v) => formatMoney(v, currency);
    return HeroCard(
      child: Column(
        children: [
          // Patrimoine = investi + mis à l'abri + retiré pour vivre.
          Text('Patrimoine', style: hero.labelLarge),
          FittedBox(child: Text(money(day.wealth), style: hero.displaySmall)),
          const SizedBox(height: 8),
          HeroPill(
            child: Text(
              'Départ : ${money(initial)} · ×${_multiple(multiple)}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          HeroPill(
            child: Text(
              'Investi : ${money(day.capital)} · '
              'mis à l’abri : ${money(day.sheltered)}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Ce que la vie et l'État ont pris en chemin.
          HeroPill(
            child: Text(
              'Retiré pour vivre : ${money(day.withdrawn)} · '
              'impôts : ${money(day.taxPaid)}',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static String _multiple(double m) => m < 100
      ? m.toStringAsFixed(1).replaceAll('.', ',')
      : formatUnits(m.roundToDouble());
}

/// Chronologie du parcours : une puce par étape.
class _StepChips extends StatelessWidget {
  final ForesightRun run;
  final int current;
  final DateTime currentDate;
  final ValueChanged<int> onSelect;

  const _StepChips({
    required this.run,
    required this.current,
    required this.currentDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, r) in run.steps.indexed) ...[
            ChoiceChip(
              selected: i == current,
              onSelected: (_) => onSelect(i),
              label: Text(switch (r.step) {
                // Le multiplicateur n'est révélé qu'une fois l'étape vécue.
                AssetStep(:final name, :final sell) =>
                  currentDate.isAfter(sell) || currentDate == sell
                      ? '$name ×${r.multiplier.toStringAsFixed(1).replaceAll('.', ',')}'
                      : name,
                CashStep() => 'Cash',
              }),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// L'étape en cours : actif, dates prévues, histoire, graphique du cours.
class _StepCard extends StatelessWidget {
  final ForesightStep step;
  final StepResult result;
  final DateTime currentDate;
  final String currency;

  final VoidCallback onReadChapter;

  const _StepCard({
    required this.onReadChapter,
    required this.step,
    required this.result,
    required this.currentDate,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: switch (step) {
            AssetStep() && final s => [
              Text(s.name, style: textTheme.titleLarge),
              Text(
                'Achat le ${formatDate(s.buy)} à '
                '${_price(result.buyPrice!)} · '
                'vente prévue le ${formatDate(s.sell)} à '
                '${_price(result.sellPrice!)}',
              ),
              const SizedBox(height: 8),
              Text(s.story, style: textTheme.bodySmall),
              TextButton.icon(
                onPressed: onReadChapter,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Lire l’histoire de cette étape'),
              ),
              const SizedBox(height: 8),
              StepPriceChart(
                prices: s.prices,
                buy: s.buy,
                sell: s.sell,
                current: currentDate,
              ),
            ],
            CashStep() && final s => [
              Text('Pause en cash', style: textTheme.titleLarge),
              Text('Du ${formatDate(s.from)} au ${formatDate(s.to)}'),
              const SizedBox(height: 8),
              Text(s.story, style: textTheme.bodySmall),
              TextButton.icon(
                onPressed: onReadChapter,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Lire l’histoire de cette étape'),
              ),
            ],
          },
        ),
      ),
    );
  }

  String _price(double v) => v < 1
      ? '${v.toStringAsFixed(4).replaceAll('.', ',')} \$'
      : formatMoney(v, currency);
}

class _Hypotheses extends StatelessWidget {
  final ForesightScenario scenario;
  final TaxProfile? tax;
  const _Hypotheses({required this.scenario, required this.tax});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Démonstration scénarisée, pas une stratégie reproductible. '
      'Hypothèses : achat et vente aux cours de clôture, parts '
      'fractionnaires, sans frais, montants en dollars de l’époque. '
      'Chaque mois, 4 % par an du capital sont retirés pour vivre, au plus '
      'l’équivalent de 3 000 \$ d’aujourd’hui. À chaque achat, on ne '
      'réinvestit qu’une réserve plafonnée (10 000 \$ avant 1990, 1 million '
      'ensuite, 100 000 \$ pour Dogecoin) : le surplus est mis à l’abri, car '
      'un montant énorme ferait bouger les prix. '
      '${tax == null ? 'Sans impôts.' : 'Impôts : ${tax!.summary}, règles actuelles simplifiées appliquées à toute la période.'} '
      'Source : ${scenario.source}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
