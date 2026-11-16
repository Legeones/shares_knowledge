import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../logic/playground/replay.dart';
import '../../logic/time_cursor.dart';
import '../../models/simulation.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/playground/animated_money.dart';
import '../../widgets/sky_header.dart';
import '../../widgets/playground/value_chart.dart';
import '../../widgets/glass.dart';

/// Rejeu d'une simulation : on avance dans le temps et on voit la date,
/// le graphique et la valeur évoluer ensemble.
class ReplayScreen extends StatefulWidget {
  final SimulationResult result;
  const ReplayScreen({super.key, required this.result});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

/// `TickerProviderStateMixin` fournit le « vsync » des AnimationController :
/// un signal à chaque image de l'écran (≈ 60 par seconde), coupé
/// automatiquement quand l'écran n'est pas visible (économie de batterie).
class _ReplayScreenState extends State<ReplayScreen>
    with TickerProviderStateMixin {
  late final Replay _replay = Replay(widget.result);

  /// Animation 1 (programmée) : un tour du cycle soleil / lune.
  late final AnimationController _sky = AnimationController(vsync: this);

  /// Animation 2 (programmée) : révélation progressive des points du graphique.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    value: 1, // au départ, rien à animer
  );

  /// Nombre de points affichés : animé de [begin] (avant le saut) à [end].
  late Tween<double> _revealCount = Tween(
    begin: 1,
    end: _replay.visibleCount.toDouble(),
  );

  /// Nombre de jours de la période rejouée.
  late final int _totalDays = widget.result.actualEnd
      .difference(widget.result.actualStart)
      .inDays;

  /// Lecture automatique fluide : un troisième AnimationController dont la
  /// valeur (0 → 1) est la **position dans la période**. À chaque image, on
  /// en déduit la date à afficher : les jours défilent en continu, sans à-coups.
  /// Sa durée = temps pour parcourir toute la période (voir autoPlayDuration).
  late final AnimationController _playback =
      AnimationController(vsync: this, duration: autoPlayDuration(_totalDays))
        ..addListener(_onPlaybackFrame)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _pause(); // fin atteinte
        });

  bool get _isPlaying => _playback.isAnimating;

  /// Durée d'un tour de ciel pendant la lecture : un cycle doux et régulier,
  /// indépendant de la vitesse (sinon 46 nuits par seconde clignoteraient).
  static const _skyLoop = Duration(seconds: 2);

  void _play() {
    if (_replay.isAtEnd) _move(_replay.reset); // relire depuis le début
    final elapsed = _replay.currentDate
        .difference(widget.result.actualStart)
        .inDays;
    // Reprend là où on en est : forward(from:) part de la position actuelle.
    _playback.forward(from: _totalDays == 0 ? 1 : elapsed / _totalDays);
    if (!_reduceMotion) {
      _sky.duration = _skyLoop;
      _sky.repeat(); // le ciel tourne en boucle pendant la lecture
    }
    setState(() {}); // le bouton passe en « Pause »
  }

  /// Appelée à chaque image (≈ 60 fois par seconde) pendant la lecture.
  void _onPlaybackFrame() {
    final day = (_playback.value * _totalDays).floor();
    final date = widget.result.actualStart.add(Duration(days: day));
    if (date == _replay.currentDate) return; // même jour : rien à redessiner
    setState(() => _replay.jumpTo(date));
    // Le graphique suit directement la date, sans animation de révélation.
    final count = _replay.visibleCount.toDouble();
    _revealCount = Tween(begin: count, end: count);
    _reveal.value = 1;
  }

  void _pause() {
    _playback.stop();
    // Le ciel termine son tour et s'arrête à midi (pas figé en pleine nuit).
    if (_sky.isAnimating) _sky.forward();
    setState(() {}); // le bouton repasse en « Lecture »
  }

  @override
  void dispose() {
    // Un contrôleur non libéré continuerait de tourner après la fermeture
    // de l'écran : fuite de mémoire.
    _playback.dispose();
    _sky.dispose();
    _reveal.dispose();
    super.dispose();
  }

  /// Durée d'une avancée : un saut plus long est un peu plus lent, mais
  /// « +1 mois » reste un seul cycle (on ne regarde pas 30 nuits défiler).
  static const _durations = {
    TimeStep.day: Duration(milliseconds: 600),
    TimeStep.week: Duration(milliseconds: 900),
    TimeStep.month: Duration(milliseconds: 1200),
  };

  /// Le réglage « Supprimer les animations » du téléphone est respecté.
  /// ou l'interrupteur du profil (SettingsProvider).
  /// `SettingsProvider?` : null si absent (tests de cet écran seul).
  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations ||
      (context.read<SettingsProvider?>()?.reduceAnimations ?? false);

  void _move(void Function() change, {Duration? duration}) {
    // Le graphique repart du nombre de points actuellement affiché, même si
    // l'animation précédente n'était pas finie (appuis rapides).
    final shownNow = _revealCount.evaluate(_reveal);
    setState(change);
    _revealCount = Tween(begin: shownNow, end: _replay.visibleCount.toDouble());

    if (duration == null || _reduceMotion) {
      _reveal.value = 1; // saut immédiat
      return;
    }
    _sky.duration = duration;
    _reveal.duration = duration;
    _sky.forward(from: 0);
    _reveal.forward(from: 0);
  }

  /// Appui sur +1 jour / +7 jours / +1 mois : reprend la main, donc pause.
  void _advance(TimeStep step) {
    if (_isPlaying) _pause();
    _move(() => _replay.advance(step), duration: _durations[step]);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final currency = result.params.asset.currency;
    // Pendant la lecture, la valeur suit la date image par image : pas de
    // délai d'animation supplémentaire sur le compteur.
    final duration = _reduceMotion || _isPlaying
        ? Duration.zero
        : _durations[TimeStep.week]!;
    final isGain = _replay.currentGain >= 0;
    final textTheme = Theme.of(context).textTheme;

    final totalDays = result.actualEnd.difference(result.actualStart).inDays;
    final elapsed = _replay.currentDate.difference(result.actualStart).inDays;

    return LargeTitleScaffold(
      title: 'Rejeu',
      body: ListView(
        padding: pagePadding(context, horizontal: 0, top: 4, bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PageTitle('Rejeu — ${result.params.asset.name}'),
          ),
          SkyHeader(
            cycle: _sky,
            child: _DateLabel(
              date: _replay.currentDate,
              marketOpen: _replay.isMarketOpen,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LinearProgressIndicator(
              value: totalDays == 0 ? 1 : elapsed / totalDays,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: 'Avancement dans la période',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Expanded : le libellé passe à la ligne si la place manque.
                    const Expanded(child: Text('Valeur de l’investissement')),
                    // Animation 3 (implicite) : le montant défile.
                    AnimatedMoney(
                      value: _replay.currentValue,
                      currency: currency,
                      duration: duration,
                      style: textTheme.titleLarge,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isGain ? 'Gain' : 'Perte'),
                    AnimatedMoney(
                      value: _replay.currentGain,
                      currency: currency,
                      duration: duration,
                      signed: true,
                      style: TextStyle(
                        color: isGain ? AppColors.gain : AppColors.loss,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatPercent(_replay.currentPerformance)} · '
                  'cours ${formatMoney(_replay.currentPoint.price, currency)} '
                  '(clôture du ${formatDate(_replay.currentPoint.date)})',
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                // AnimatedBuilder reconstruit seulement le graphique à chaque
                // image de l'animation, pas tout l'écran.
                AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) => ValueChart(
                    result: result,
                    revealCount: _revealCount.evaluate(_reveal).round(),
                  ),
                ),
                const SizedBox(height: 16),
                _PlayButton(
                  isPlaying: _isPlaying,
                  totalDuration: _playback.duration!,
                  onPressed: _isPlaying ? _pause : _play,
                ),
                const SizedBox(height: 8),
                _TimeControls(canAdvance: !_replay.isAtEnd, onStep: _advance),
                const SizedBox(height: 8),
                // Wrap : les boutons passent à la ligne sur un écran étroit.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _replay.isAtStart
                          ? null
                          : () {
                              if (_isPlaying) _pause();
                              _move(_replay.reset);
                            },
                      icon: const Icon(Icons.replay),
                      label: const Text('Recommencer'),
                    ),
                    TextButton.icon(
                      onPressed: _replay.isAtEnd
                          ? null
                          : () {
                              if (_isPlaying) _pause();
                              _move(_replay.jumpToEnd);
                            },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Aller à la fin'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La date courante, posée sur le ciel.
class _DateLabel extends StatelessWidget {
  final DateTime date;
  final bool marketOpen;
  const _DateLabel({required this.date, required this.marketOpen});

  @override
  Widget build(BuildContext context) {
    // Ombre portée : le texte blanc reste lisible sur le ciel clair ou sombre.
    const shadow = [Shadow(blurRadius: 6, color: Colors.black54)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatDateWithWeekday(date),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: shadow,
          ),
        ),
        if (!marketOpen)
          const Text(
            'Marché fermé · dernier cours connu',
            style: TextStyle(color: Colors.white, shadows: shadow),
          ),
      ],
    );
  }
}

/// Les trois boutons d'avancée du temps.
class _TimeControls extends StatelessWidget {
  final bool canAdvance;
  final ValueChanged<TimeStep> onStep;
  const _TimeControls({required this.canAdvance, required this.onStep});

  static const _labels = {
    TimeStep.day: '+1 jour',
    TimeStep.week: '+7 jours',
    TimeStep.month: '+1 mois',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final step in TimeStep.values) ...[
          if (step != TimeStep.day) const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonal(
              // null = bouton désactivé (on est à la fin de la période).
              onPressed: canAdvance ? () => onStep(step) : null,
              child: Text(_labels[step]!),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton Lecture / Pause de la lecture automatique.
class _PlayButton extends StatelessWidget {
  final bool isPlaying;

  /// Durée de la lecture de toute la période.
  final Duration totalDuration;
  final VoidCallback onPressed;

  const _PlayButton({
    required this.isPlaying,
    required this.totalDuration,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = (totalDuration.inMilliseconds / 1000).round();
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(isPlaying ? 'Pause' : 'Lecture automatique · $seconds s'),
    );
  }
}
