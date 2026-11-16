import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';
import 'package:shares_knowledge/screens/playground/replay_screen.dart';
import 'package:shares_knowledge/widgets/sky_header.dart';

import '../../logic/helpers.dart';

/// Les montants contiennent des espaces insécables : « 1 000,00 ».
/// Le point d'une RegExp accepte n'importe quel caractère à cet endroit.
Finder money(String pattern) => find.textContaining(RegExp(pattern));

final result = simulateLumpSum(
  SimulationParams(
    asset: const Asset(
      symbol: 'T',
      name: 'Test',
      currency: 'USD',
      type: AssetType.stock,
    ),
    amount: 1000,
    start: d(2024, 1, 1),
    end: d(2024, 1, 8),
  ),
  weekSeries,
);

Future<void> pumpReplay(WidgetTester tester, {bool reduceMotion = false}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      // Simule le réglage « Supprimer les animations » du téléphone.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: ReplayScreen(result: result),
    ),
  );
}

void main() {
  group('cycle soleil / lune', () {
    test('au repos il fait jour (midi)', () {
      expect(dayPhase(0), 0.25);
      expect(skyBrightness(dayPhase(0)), closeTo(1, 1e-9));
    });

    test('au milieu du cycle il fait nuit (minuit)', () {
      expect(dayPhase(0.5), 0.75);
      expect(skyBrightness(dayPhase(0.5)), closeTo(-1, 1e-9));
    });

    test('un cycle complet revient à midi', () {
      expect(dayPhase(1), dayPhase(0));
    });
  });

  testWidgets('affiche la date de départ et la valeur investie', (
    tester,
  ) async {
    await pumpReplay(tester);
    expect(find.text('lundi 01/01/2024'), findsOneWidget);
    expect(money('1.000,00'), findsOneWidget);
  });

  testWidgets('+1 jour : date, valeur et animations avancent ensemble', (
    tester,
  ) async {
    await pumpReplay(tester);

    await tester.tap(find.text('+1 jour'));
    await tester.pump(const Duration(milliseconds: 300)); // mi-animation
    // Le compteur défile : ni l'ancienne ni encore tout à fait la nouvelle.
    expect(money('1.100,00'), findsNothing);

    await tester.pumpAndSettle(); // fin des animations
    expect(find.text('mardi 02/01/2024'), findsOneWidget);
    expect(money('1.100,00'), findsOneWidget);
    expect(find.textContaining('+100,00'), findsOneWidget);
  });

  testWidgets('le week-end : marché fermé signalé', (tester) async {
    await pumpReplay(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('+1 jour'));
      await tester.pumpAndSettle();
    }
    expect(find.text('samedi 06/01/2024'), findsOneWidget);
    expect(find.textContaining('Marché fermé'), findsOneWidget);
  });

  testWidgets('à la fin, les boutons d’avancée sont désactivés', (
    tester,
  ) async {
    await pumpReplay(tester);
    // Plus bas que le grand titre et le ciel : on fait défiler jusqu'au bouton.
    await tester.ensureVisible(find.text('Aller à la fin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aller à la fin'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '+1 jour'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('animations réduites : la nouvelle valeur est immédiate', (
    tester,
  ) async {
    await pumpReplay(tester, reduceMotion: true);

    await tester.tap(find.text('+1 jour'));
    await tester.pump(); // une seule image, sans attendre

    expect(money('1.100,00'), findsOneWidget);
  });

  group('lecture automatique', () {
    // Période d'une semaine (7 jours) → lecture en 15 s (durée minimale) :
    // un nouveau jour environ toutes les 2,14 s.
    testWidgets('les jours défilent en continu', (tester) async {
      await pumpReplay(tester);
      expect(find.textContaining('Lecture automatique · 15 s'), findsOneWidget);

      await tester.tap(find.textContaining('Lecture automatique'));
      await tester.pump(); // démarrage
      await tester.pump(const Duration(milliseconds: 2200)); // > 1 jour
      expect(find.text('mardi 02/01/2024'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2200)); // > 2 jours
      expect(find.text('mercredi 03/01/2024'), findsOneWidget);
    });

    testWidgets('s’arrête seule à la fin de la période', (tester) async {
      await pumpReplay(tester);
      await tester.tap(find.textContaining('Lecture automatique'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();

      expect(find.text('lundi 08/01/2024'), findsOneWidget);
      expect(find.text('Pause'), findsNothing); // revenu en « Lecture »
    });

    testWidgets('Pause arrête l’avancée, Lecture reprend au même endroit', (
      tester,
    ) async {
      await pumpReplay(tester);
      await tester.tap(find.textContaining('Lecture automatique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('mardi 02/01/2024'), findsOneWidget); // pas plus loin

      await tester.tap(find.textContaining('Lecture automatique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.text('mercredi 03/01/2024'), findsOneWidget);
    });

    testWidgets('un appui sur +1 jour met la lecture en pause', (tester) async {
      await pumpReplay(tester);
      await tester.tap(find.textContaining('Lecture automatique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.tap(find.text('+1 jour'));
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsNothing);
      expect(find.text('mercredi 03/01/2024'), findsOneWidget);
    });
  });
}
