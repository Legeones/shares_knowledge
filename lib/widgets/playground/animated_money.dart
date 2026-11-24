import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// Montant qui défile jusqu'à sa nouvelle valeur.
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
