import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/widgets/progress/ingot_icons.dart';
import 'package:shares_knowledge/widgets/progress/ingot_metal.dart';
import 'package:shares_knowledge/logic/progress/medals.dart';
import 'package:shares_knowledge/widgets/progress/medal_widgets.dart';

void main() {
  test('un métal par palier, dans le même ordre', () {
    expect(MedalTier.values.map(metalOf), IngotMetal.values);
    expect(metalOf(MedalTier.copper), IngotMetal.copper);
  });

  test('l’icône du lingot vient de la police déclarée dans pubspec.yaml', () {
    expect(IngotIcons.ingot.fontFamily, 'SharesKnowledgeIcons');
    expect(IngotIcons.ingot.codePoint, 0xe900);
    expect(IngotIcons.diamond.fontFamily, 'SharesKnowledgeIcons');
    expect(IngotIcons.diamond.codePoint, 0xe901);
    expect(File('assets/fonts/SharesKnowledgeIcons.ttf').existsSync(), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: SharesKnowledgeIcons'));
  });
}
