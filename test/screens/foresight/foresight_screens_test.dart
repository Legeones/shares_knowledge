import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/core/formatters.dart';
import 'package:shares_knowledge/logic/foresight/foresight.dart';
import 'package:shares_knowledge/logic/taxes.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';
import 'package:shares_knowledge/screens/foresight/foresight_debrief_screen.dart';
import 'package:shares_knowledge/screens/foresight/foresight_player_screen.dart';

final scenario = ForesightScenario.fromJson(
  jsonDecode(
    File('assets/scenarios/foresight/foresight_2020s.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

/// Montants avec espaces insécables : le point accepte n'importe quel caractère.
Finder money(String pattern) => find.textContaining(RegExp(pattern));

/// Fait défiler pour placer le widget au milieu de l'écran : en haut, il
/// serait caché sous la barre en verre, qui flotte au-dessus de la page.
Future<void> centerOnScreen(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
}

/// Fait défiler jusqu'au widget avant de le toucher (la page est longue).
/// `pump()` et non `pumpAndSettle()` : pendant la lecture automatique,
/// « attendre la fin des animations » attendrait toute la lecture.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await centerOnScreen(tester, finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Ferme le chapitre affiché (« Continuer l'histoire »).
Future<void> continueStory(WidgetTester tester) async {
  // La lecture est en pause pendant un chapitre : on peut attendre la fin
  // de l'animation d'ouverture de la fenêtre avant de toucher le bouton.
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuer l’histoire'));
  await tester.pump(const Duration(milliseconds: 500)); // fermeture
}

/// Remonte en haut de la page, où sont affichées la date et l'étape.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 5000));
  await tester.pump();
}

Future<void> pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
}

void main() {
  group('lecteur', () {
    testWidgets('accroche, chapitres à chaque étape, puis résultat final', (
      tester,
    ) async {
      await pump(tester, ForesightPlayerScreen(scenario: scenario));
      expect(find.textContaining('Et si tu avais investi'), findsOneWidget);

      await tester.tap(find.text('Voir ce qui se serait passé'));
      await tester.pump(const Duration(milliseconds: 500));

      // Chapitre 1 avant de démarrer.
      expect(find.text('Chapitre 1'), findsOneWidget);
      // La leçon est plus bas dans la fenêtre : on fait défiler pour la voir.
      final lesson = find.text(
        'Leçon : ${scenario.steps.first.chapter.lessonTitle}',
      );
      await tester.scrollUntilVisible(
        lesson,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(lesson, findsOneWidget);

      // On lit chaque chapitre au fil de la lecture : un par étape.
      var chapters = 0;
      for (
        var i = 0;
        i < 200 && find.text('Épilogue').evaluate().isEmpty;
        i++
      ) {
        if (find.text('Continuer l’histoire').evaluate().isNotEmpty) {
          chapters++;
          await continueStory(tester);
        }
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(chapters, scenario.steps.length);

      // Épilogue, puis le résultat.
      expect(
        find.text(
          'Pourquoi vendre ${scenario.assetSteps.last.name} maintenant ?',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Voir le résultat'));
      await tester.pumpAndSettle();
      expect(find.text(formatDateWithWeekday(scenario.end)), findsWidgets);
      // Sans profil fiscal dans ce test : retraits et réserve seulement.
      final lived = livedRun(scenario);
      expect(find.text(formatMoney(lived.totalWealth, 'USD')), findsOneWidget);
      expect(find.textContaining('Trop beau pour être vrai'), findsOneWidget);
    });

    testWidgets('le chapitre 2 explique la vente de la 1re étape', (
      tester,
    ) async {
      final first = scenario.steps[0] as AssetStep;
      final second = scenario.steps[1] as AssetStep;
      await pump(tester, ForesightPlayerScreen(scenario: scenario));
      await tester.tap(find.text('Voir ce qui se serait passé'));
      await tester.pump(const Duration(milliseconds: 500));
      await continueStory(tester); // chapitre 1
      for (
        var i = 0;
        i < 100 && find.text('Chapitre 2').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        find.text('Pourquoi vendre ${first.name} maintenant ?'),
        findsOneWidget,
      );
      expect(find.text(first.chapter.whyLeave), findsOneWidget);
      expect(find.textContaining('Résultat de l’étape : ×'), findsOneWidget);
      // Plus bas dans la fenêtre : on fait défiler.
      final why = find.text('Pourquoi acheter ${second.name} ?');
      await tester.scrollUntilVisible(
        why,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(why, findsOneWidget);
    });

    testWidgets('+1 mois avance la date, sans lecture automatique', (
      tester,
    ) async {
      await pump(tester, ForesightPlayerScreen(scenario: scenario));
      await tester.tap(find.text('Voir ce qui se serait passé'));
      await tester.pump(const Duration(milliseconds: 500));
      await continueStory(tester);
      await tapVisible(tester, find.text('Pause'));
      await tapVisible(tester, find.text('+1 mois'));
      // Arrivée dans Dogecoin : son chapitre s'ouvre, sans changer la date.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chapitre 2'), findsOneWidget);
      await continueStory(tester);
      await scrollToTop(tester);
      expect(find.text('jeudi 04/02/2021'), findsWidgets);
      expect(find.text('Tu détiens : Dogecoin'), findsOneWidget);
    });

    testWidgets('toucher une étape y saute directement', (tester) async {
      await pump(tester, ForesightPlayerScreen(scenario: scenario));
      await tester.tap(find.text('Voir ce qui se serait passé'));
      await tester.pump(const Duration(milliseconds: 500));
      await continueStory(tester);
      await tapVisible(tester, find.text('Pause'));
      final doge = scenario.assetSteps.firstWhere((s) => s.name == 'Dogecoin');
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Dogecoin'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(doge.chapter.context), findsWidgets); // son chapitre
      await continueStory(tester);
      await scrollToTop(tester);
      expect(find.text(formatDateWithWeekday(doge.buy)), findsWidgets);
      expect(find.text('Tu détiens : Dogecoin'), findsOneWidget);
    });
  });

  group('bilan', () {
    testWidgets('les raisons ; le résultat suit les règles du parcours vécu', (
      tester,
    ) async {
      await pump(tester, ForesightDebriefScreen(scenario: scenario));
      // Le calcul « tout réinvesti, sans plafond » n'est plus affiché.
      expect(
        find.text(formatMoney(ForesightRun(scenario).finalCapital, 'USD')),
        findsNothing,
      );
      expect(
        find.textContaining('impôts et retraits pour vivre compris'),
        findsOneWidget,
      );
      expect(find.text('1. Il fallait connaître le futur'), findsOneWidget);
      expect(
        find.textContaining('un seul jour de bourse trop tard'),
        findsOneWidget,
      );
    });

    testWidgets('changer de pays recalcule l’impôt', (tester) async {
      await pump(tester, ForesightDebriefScreen(scenario: scenario));

      await tester
          .scrollUntilVisible(
            find.byType(DropdownButtonFormField<Object>).hitTestable(),
            300,
            scrollable: find.byType(Scrollable).first,
          )
          .catchError((_) {});
      await centerOnScreen(tester, find.text('Pays de résidence fiscale'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pays de résidence fiscale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suisse').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Aucun impôt dans ce modèle simplifié.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Pays de résidence fiscale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('France').last);
      await tester.pumpAndSettle();
      final france = livedRun(
        scenario,
        taxRate: TaxProfile(taxCountryFor('FR')).rateFor,
      );
      expect(
        find.text(
          'Patrimoine final : ${formatMoney(france.totalWealth, 'USD')}',
        ),
        findsOneWidget,
      );
    });
  });
}
