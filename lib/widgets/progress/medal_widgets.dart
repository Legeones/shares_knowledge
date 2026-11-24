import 'package:flutter/material.dart';

import 'ingot_icons.dart';
import 'ingot_metal.dart';
import '../../core/theme.dart';
import '../../logic/progress/medals.dart';
import '../glass.dart';

/// Icône de chaque médaille (l'interface choisit les icônes, pas la logique).
const _icons = <String, IconData>{
  'first_lesson': Icons.school_rounded,
  'all_lessons': Icons.workspace_premium_rounded,
  'simulator': Icons.science_rounded,
  'explorer': Icons.explore_rounded,
  'archivist': Icons.bookmark_rounded,
  'time_traveler': Icons.hourglass_bottom_rounded,
  'trader': Icons.flag_rounded,
  'persistent': Icons.replay_rounded,
  'to_the_end': Icons.sports_score_rounded,
  'efficiency': Icons.trending_up_rounded,
  'regular': Icons.calendar_month_rounded,
  'comparator': Icons.compare_arrows_rounded,
  'risk': Icons.shield_rounded,
  'blind': Icons.visibility_off_rounded,
};

IconData medalIcon(Medal medal) => _icons[medal.id] ?? Icons.star_rounded;

/// Métal de chaque palier (même ordre : Fer, Cuivre, Or, Diamant). Les
/// couleurs se modifient dans core/ingot_metal.dart.
IngotMetal metalOf(MedalTier tier) => IngotMetal.values[tier.index];

/// Dégradé d'un palier : une version claire du métal, puis le métal.
List<Color> _colorsFor(MedalStatus s) {
  final metal = metalOf(s.tier ?? MedalTier.gold).color;
  return [Color.lerp(Colors.white, metal, 0.55)!, metal];
}

/// Couleur principale d'un palier (texte de l'étiquette, ombre).
Color tierColor(MedalStatus s) => _colorsFor(s).last;

/// Disque de la médaille : couleur du palier si obtenue, gris sinon.
class MedalDisc extends StatelessWidget {
  final MedalStatus status;
  final double size;

  const MedalDisc({super.key, required this.status, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final earned = status.earned;
    final colors = _colorsFor(status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        color: earned ? null : AppColors.line,
        boxShadow: earned
            ? [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        status.medal.comingSoon
            ? Icons.lock_clock_rounded
            : medalIcon(status.medal),
        color: earned ? Colors.white : AppColors.muted,
        size: size * 0.5,
      ),
    );
  }
}

/// Ligne d'une médaille : disque, titre, palier, condition, avancement.
class MedalCard extends StatelessWidget {
  final MedalStatus status;
  const MedalCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medal = status.medal;
    final next = status.next;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MedalDisc(status: status),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medal.title, style: textTheme.titleSmall),
                  if (medal.isTiered) ...[
                    const SizedBox(height: 6),
                    _TierDots(level: status.level),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    status.maxed && medal.isTiered
                        ? 'Niveau maximal atteint !'
                        : status.condition,
                    style: textTheme.bodySmall,
                  ),
                  // Un objectif restant : on montre le chemin parcouru.
                  if (next != null && !medal.comingSoon) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: status.ratio,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medal.format(status.value)} / ${medal.format(next)}',
                      style: textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (status.earned)
              _Tag(status.tier?.label ?? 'Obtenue', tierColor(status))
            else if (medal.comingSoon)
              const _Tag('Bientôt', AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Quatre lingots : les paliers Fer, Cuivre, Or, Diamant atteints.
class _TierDots extends StatelessWidget {
  final int level;
  const _TierDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tier in MedalTier.values)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              // Le dernier palier est un diamant, les autres des lingots.
              tier == MedalTier.diamond ? IngotIcons.diamond : IngotIcons.ingot,
              color: tier.index < level
                  ? metalOf(tier).color
                  : AppColors.muted.withValues(alpha: 0.35),
              size: 20,
            ),
          ),
      ],
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
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
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

/// Annonce d'une ou plusieurs médailles : carte en verre posée dans une
/// SnackBar.
class MedalToast extends StatelessWidget {
  final List<MedalAward> awards;
  final Duration duration;
  final VoidCallback onTap;

  const MedalToast({
    super.key,
    required this.awards,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = awards.first;
    // Couleur du palier obtenu (or pour une médaille simple).
    final metal = metalOf(
      first.medal.isTiered ? MedalTier.values[first.level - 1] : MedalTier.gold,
    ).color;

    return Glass(
      opacity: 0.85,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(Colors.white, metal, 0.55)!, metal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: metal.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      medalIcon(first.medal),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          awards.length == 1
                              ? 'Médaille obtenue'
                              : '${awards.length} médailles obtenues',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          awards.map(awardLabel).join(', '),
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            // Temps restant : la barre passe de pleine à vide.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: duration,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                color: metal,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
