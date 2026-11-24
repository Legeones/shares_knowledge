import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/widgets/sky_header.dart';

void main() {
  const size = Size(300, 150);

  test('à midi, le soleil est au sommet de son arc, au centre', () {
    final noon = celestialPosition(dayPhase(0), size);
    expect(noon.dx, closeTo(150, 1e-9));
    expect(noon.dy, closeTo(150 * 0.15, 1e-9));
  });

  test('au lever et au coucher, l’astre est au ras de l’horizon', () {
    expect(celestialPosition(0, size).dy, closeTo(150 * 0.9, 1e-9));
    expect(celestialPosition(0.5, size).dx, closeTo(30, 1e-9)); // lune à gauche
  });

  test('couleurs du ciel : jour clair, nuit sombre', () {
    final (dayTop, _) = skyColors(1);
    final (nightTop, _) = skyColors(-1);
    expect(dayTop.computeLuminance(), greaterThan(nightTop.computeLuminance()));
  });

  test('lumière dorée le jour, bleutée la nuit', () {
    final day = lightColor(1);
    final night = lightColor(-1);
    expect(day.r, greaterThan(day.b)); // plus de rouge que de bleu
    expect(night.b, greaterThan(night.r)); // plus de bleu que de rouge
  });

  testWidgets('le halo déborde de la carte sans gêner les touchers', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SkyHeader(
                cycle: const AlwaysStoppedAnimation(0),
                child: const Text('date'),
              ),
              TextButton(
                onPressed: () => tapped = true,
                child: const Text('Sous le ciel'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    // Le bouton est sous la zone du halo : il reste cliquable.
    await tester.tap(find.text('Sous le ciel'));
    expect(tapped, isTrue);
  });
}
