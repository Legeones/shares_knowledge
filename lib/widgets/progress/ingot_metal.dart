import 'package:flutter/painting.dart';

/// Couleurs proposées, modifiables selon le thème de l'application.
/// Une par palier de médaille, dans l'ordre : Fer, Cuivre, Or, Diamant.
enum IngotMetal {
  iron(Color(0xFF78909C)),
  copper(Color(0xFFB87333)),
  gold(Color(0xFFD4AF37)),
  // Ajouté pour le 4e palier des médailles.
  diamond(Color(0xFF3FA9F5));

  const IngotMetal(this.color);
  final Color color;
}
