import 'package:flutter/widgets.dart';

/// Icônes de SharesKnowledge issues du dessin de lingots fourni.
@staticIconProvider
abstract final class IngotIcons {
  static const String fontFamily = 'SharesKnowledgeIcons';

  static const IconData ingot = IconData(
    0xe900,
    fontFamily: fontFamily,
    matchTextDirection: false,
  );

  /// Diamant dessiné dans le même style que le lingot (tool/add_diamond_glyph.py).
  static const IconData diamond = IconData(
    0xe901,
    fontFamily: fontFamily,
    matchTextDirection: false,
  );
}
