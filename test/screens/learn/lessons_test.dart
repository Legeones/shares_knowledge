import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shares_knowledge/providers/learn/lesson_progress_provider.dart';
import 'package:shares_knowledge/screens/learn/learn_screen.dart';
import 'package:shares_knowledge/core/formatters.dart';
import 'package:shares_knowledge/screens/learn/lessons/compound_lesson_screen.dart';
import 'package:shares_knowledge/screens/learn/lessons/dca_lesson_screen.dart';
import 'package:shares_knowledge/screens/learn/lessons/diversification_lesson_screen.dart';
import 'package:shares_knowledge/screens/learn/lessons/drawdown_lesson_screen.dart';
import 'package:shares_knowledge/screens/learn/lessons/volatility_lesson_screen.dart';
import 'package:shares_knowledge/screens/learn/lessons/return_lesson_screen.dart';

late LessonProgressProvider progress;

Future<void> pumpWith(
  WidgetTester tester,
  Widget screen, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  progress = LessonProgressProvider(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: progress,
      child: MaterialApp(home: screen),
    ),
  );
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

void main() {
  group('LessonProgressProvider', () {
    test('non commencée → en cours → terminée', () async {
      SharedPreferences.setMockInitialValues({});
      final p = LessonProgressProvider(await SharedPreferences.getInstance());
      expect(p.statusOf('return'), LessonStatus.notStarted);

      await p.saveStep('return', 2);
      expect(p.statusOf('return'), LessonStatus.inProgress);
      expect(p.stepOf('return'), 2);

      await p.complete('return');
      expect(p.statusOf('return'), LessonStatus.completed);
      expect(p.stepOf('return'), 0); // la prochaine fois : depuis le début
    });

    test('recommencer une leçon terminée ne retire pas le statut', () async {
      SharedPreferences.setMockInitialValues({});
      final p = LessonProgressProvider(await SharedPreferences.getInstance());
      await p.complete('return');
      await p.saveStep('return', 1);
      expect(p.statusOf('return'), LessonStatus.completed);
    });

    test('remise à zéro', () async {
      SharedPreferences.setMockInitialValues({});
      final p = LessonProgressProvider(await SharedPreferences.getInstance());
      await p.complete('return');
      await p.reset(['return']);
      expect(p.statusOf('return'), LessonStatus.notStarted);
    });
  });

  testWidgets('catalogue : statut écrit, toutes les leçons ouvertes', (
    tester,
  ) async {
    await pumpWith(
      tester,
      const Scaffold(body: LearnScreen()),
      prefs: {'lesson.return.completed': true, 'lesson.compound.step': 1},
    );
    expect(find.text('Terminée'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('1 leçon terminée sur 6'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Bientôt'), findsNothing); // toutes écrites
  });

  testWidgets('leçon rendement : parcours complet jusqu’à « terminée »', (
    tester,
  ) async {
    await pumpWith(tester, const ReturnLessonScreen());
    expect(find.text('La situation'), findsOneWidget);

    await next(tester);
    expect(find.text('À toi de manipuler'), findsOneWidget);
    expect(find.text('+20,00 %'), findsOneWidget); // 50 € → 60 €

    await next(tester);
    await next(tester);

    // Quiz : « Terminer » est bloqué tant qu'on n'a pas répondu.
    final finish = find.widgetWithText(FilledButton, 'Terminer la leçon');
    expect(tester.widget<FilledButton>(finish).onPressed, isNull);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text('Pas tout à fait.'), findsOneWidget);
    expect(tester.widget<FilledButton>(finish).onPressed, isNotNull);

    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(progress.statusOf('return'), LessonStatus.completed);
  });

  testWidgets('l’avancement est enregistré et repris', (tester) async {
    await pumpWith(
      tester,
      const CompoundLessonScreen(),
      prefs: {'lesson.compound.step': 2},
    );
    expect(find.text('Ce qu’il faut retenir'), findsOneWidget);

    await tester.tap(find.text('Précédent'));
    await tester.pumpAndSettle();
    expect(progress.stepOf('compound'), 1);
  });

  testWidgets('leçon composée : un mot du glossaire s’explique au toucher', (
    tester,
  ) async {
    await pumpWith(tester, const CompoundLessonScreen());
    await tester.tap(find.text('rendement composé'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('rapportent à leur tour'),
      ),
      findsOneWidget,
    );
  });

  /// Parcourt une leçon jusqu'au bout en répondant [answer] au quiz.
  Future<void> completeLesson(
    WidgetTester tester,
    Widget screen,
    String id,
    String answer,
  ) async {
    await pumpWith(tester, screen);
    await next(tester);
    await next(tester);
    await next(tester);
    await tester.tap(find.text(answer));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Terminer la leçon'));
    await tester.pumpAndSettle();
    expect(progress.statusOf(id), LessonStatus.completed);
  }

  testWidgets('leçon volatilité : même résultat, risques différents', (
    tester,
  ) async {
    await pumpWith(tester, const VolatilityLessonScreen());
    await next(tester);
    // Même résultat final pour Anna et Bruno.
    expect(find.text(formatMoney(1500, 'EUR')), findsNWidgets(2));
    expect(find.text('Baisse maximale'), findsOneWidget);
  });

  testWidgets('leçon volatilité : parcours complet', (tester) async {
    await completeLesson(
      tester,
      const VolatilityLessonScreen(),
      'volatility',
      'Celui qui a perdu 40 %',
    );
  });

  testWidgets('leçon baisse maximale : −50 % demande +100 %', (tester) async {
    await pumpWith(tester, const DrawdownLessonScreen());
    await next(tester);
    expect(find.text('+100,00 %'), findsOneWidget); // perte de 50 % par défaut
  });

  testWidgets('leçon baisse maximale : parcours complet', (tester) async {
    await completeLesson(
      tester,
      const DrawdownLessonScreen(),
      'drawdown',
      '+100 %',
    );
  });

  testWidgets('leçon DCA : le krach favorise les versements réguliers', (
    tester,
  ) async {
    await pumpWith(tester, const DcaLessonScreen());
    await next(tester);
    expect(find.textContaining('verser chaque mois rapporte plus'), findsOne);
    await tester.tap(find.text('Hausse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tout placer d’un coup'), findsOne);
  });

  testWidgets('leçon DCA : parcours complet', (tester) async {
    await completeLesson(
      tester,
      const DcaLessonScreen(),
      'dca',
      'On achète plus de parts quand le prix est bas',
    );
  });

  testWidgets(
    'leçon diversification : une seule entreprise, la ruine possible',
    (tester) async {
      await pumpWith(tester, const DiversificationLessonScreen());
      await next(tester);
      expect(find.text(formatMoney(0, 'EUR')), findsOneWidget); // la faillite
    },
  );

  testWidgets('leçon diversification : parcours complet', (tester) async {
    await completeLesson(
      tester,
      const DiversificationLessonScreen(),
      'diversification',
      'L’écart entre le meilleur et le pire résultat se réduit',
    );
  });
}
