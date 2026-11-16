import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// Animation 3 — le montant défile jusqu'à sa nouvelle valeur.
///
/// `TweenAnimationBuilder` est une animation **implicite** : on lui donne
/// seulement la valeur d'arrivée. Quand elle change, Flutter anime tout seul
/// depuis l'ancienne valeur. Pas de contrôleur à créer ni à libérer.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final String currency;
  final Duration duration;
  final TextStyle? style;

  /// Affiche le signe + / − (pour un gain ou une perte).
  final bool signed;

  const AnimatedMoney({
    super.key,
    required this.value,
    required this.currency,
    required this.duration,
    this.style,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: duration,
      curve: Curves.easeOut,
      // Appelé à chaque image avec la valeur intermédiaire.
      builder: (context, shown, _) => Text(
        signed
            ? formatSignedMoney(shown, currency)
            : formatMoney(shown, currency),
        style: style,
      ),
    );
  }
}
