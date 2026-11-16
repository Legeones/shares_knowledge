import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:shares_knowledge/widgets/progress/medal_widgets.dart';
import 'package:shares_knowledge/widgets/glass.dart';
import 'package:shares_knowledge/app.dart';
import 'package:shares_knowledge/core/sections.dart';
import 'package:shares_knowledge/data/past_trader/news_source.dart';
import 'package:shares_knowledge/data/foresight/foresight_loader.dart';
import 'package:shares_knowledge/logic/past_trader/news_feed.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';
import 'package:shares_knowledge/models/past_trader/past_trader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shares_knowledge/providers/connectivity_provider.dart';
import 'package:shares_knowledge/providers/learn/lesson_progress_provider.dart';
import 'package:shares_knowledge/providers/playground/saves_provider.dart';
import 'package:shares_knowledge/providers/settings_provider.dart';
import 'package:shares_knowledge/providers/past_trader/trader_attempts_provider.dart';
import 'package:shares_knowledge/providers/past_trader/trader_save_provider.dart';
import 'package:shares_knowledge/widgets/section_card.dart';

import 'fakes.dart';

/// Les vrais parcours embarqués, lus directement depuis les fichiers.
final foresightCatalog = ForesightCatalog([
  for (final decade in foresightDecades)
    ForesightScenario.fromJson(
      jsonDecode(File(foresightAsset(decade)).readAsStringSync())
          as Map<String, dynamic>,
    ),
]);

/// La vraie partie Past Trader embarquée.
final pastTraderData = TraderGameData.fromJson(
  jsonDecode(
    File('assets/scenarios/past_trader_2018_2020.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

/// On simule un écran de téléphone (le défaut des tests est 800 x 600).
/// [online] simule l'état du réseau (pas de vrai réseau dans les tests).
/// [prefs] : préférences de départ (par défaut, introduction déjà vue).
/// [attempts] : parties Past Trader déjà jouées.
Future<void> pumpApp(
  WidgetTester tester, {
  bool online = true,
  Map<String, Object> prefs = const {'intro_seen': true},
  FakeTraderAttemptDao? attempts,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  // Fausses préférences en mémoire, fournies par shared_preferences.
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await SharedPreferences.getInstance();
  final settings = SettingsProvider(storage);
  final saves = SavesProvider(FakeSavedSimulationDao());
  await saves.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: foresightCatalog),
        Provider.value(value: pastTraderData),
        Provider.value(
          value: NewsFeed(
            parseNews(
              File('assets/scenarios/past_trader_news.json').readAsStringSync(),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ConnectivityProvider(statusStream: Stream.value(online)),
        ),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => LessonProgressProvider(storage)),
        ChangeNotifierProvider.value(value: saves),
        ChangeNotifierProvider(
          create: (_) =>
              TraderAttemptsProvider(attempts ?? FakeTraderAttemptDao())
                ..load(),
        ),
        ChangeNotifierProvider(create: (_) => TraderSaveProvider(storage)),
      ],
      child: const SharesKnowledgeApp(),
    ),
  );
  await tester.pump(); // laisse le temps au flux de livrer son état
}

/// La barre des onglets du bas.
final tabBar = find.byKey(const ValueKey('tab-bar'));

void main() {
  testWidgets('L’accueil affiche les quatre rubriques', (tester) async {
    await pumpApp(tester);

    for (final section in [
      learnSection,
      foresightSection,
      pastTraderSection,
      playgroundSection,
    ]) {
      // Dans les tests, la police remplace chaque lettre par un carré : les
      // cartes sont très hautes, il faut donc faire défiler pour les trouver.
      // (Une ListView ne construit que les éléments proches de l'écran.)
      final card = find.widgetWithText(SectionCard, section.title);
      await tester.scrollUntilVisible(card, 200);
      expect(card, findsOneWidget);
      // L'icône, toujours visible (les libellés se cachent en défilant).
      expect(
        find.descendant(of: tabBar, matching: find.byIcon(section.icon)),
        findsOneWidget,
      );
    }
    // Pas de carte pour l'accueil lui-même.
    expect(find.widgetWithText(SectionCard, homeSection.title), findsNothing);
  });

  testWidgets('Toucher une carte ouvre la rubrique correspondante', (
    tester,
  ) async {
    await pumpApp(tester);

    final card = find.widgetWithText(SectionCard, 'Playground');
    await tester.scrollUntilVisible(card, 200);
    // La barre du bas flotte par-dessus la liste : on remonte encore un peu
    // la carte pour qu'elle ne soit pas cachée dessous.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Le titre de la barre du haut a changé.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Playground'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Le bouton profil ouvre le profil, retour possible', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageTitle, 'Profil'), findsOneWidget);

    await tester.tap(find.byType(BackButton)); // flèche retour de l'AppBar
    await tester.pumpAndSettle();
    expect(find.text('SharesKnowledge'), findsOneWidget);
  });

  testWidgets('Bandeau hors connexion affiché sans réseau', (tester) async {
    await pumpApp(tester, online: false);
    expect(find.textContaining('Hors connexion'), findsOneWidget);
  });

  testWidgets('Pas de bandeau avec réseau', (tester) async {
    await pumpApp(tester, online: true);
    expect(find.textContaining('Hors connexion'), findsNothing);
  });

  testWidgets('Première ouverture : questions, Perfect Foresight, puis '
      'l’introduction', (tester) async {
    await pumpApp(tester, prefs: {});
    await tester.pumpAndSettle();
    expect(find.text('Faisons connaissance'), findsOneWidget);

    // Une année invalide bloque ; une année valide est enregistrée.
    await tester.enterText(find.byType(TextFormField), '1800');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Choisis une année'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '1985');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    final storage = await SharedPreferences.getInstance();
    expect(storage.getInt('birth_year'), 1985);
    expect(storage.containsKey('tax_country'), isTrue);

    expect(find.textContaining('Et si tu avais investi'), findsOneWidget);

    await tester.tap(find.text('Passer')); // passe la démonstration
    await tester.pumpAndSettle();
    expect(find.text('Apprendre en manipulant'), findsOneWidget);

    await tester.tap(find.text('Passer')); // passe l'introduction
    await tester.pumpAndSettle();
    expect(find.text('SharesKnowledge'), findsOneWidget);
  });

  testWidgets('Pas de carte « Reprendre » sans simulation précédente', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Reprendre ma dernière simulation'), findsNothing);
  });

  testWidgets('Carte « Reprendre » avec la dernière simulation', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {
        'intro_seen': true,
        'last_simulation':
            '{"asset":{"symbol":"AAPL","name":"Apple","currency":"USD",'
            '"type":"stock"},"amount":1000,"start":"2021-10-05",'
            '"end":"2026-10-02"}',
      },
    );
    expect(find.text('Reprendre ma dernière simulation'), findsOneWidget);
    expect(find.textContaining('Apple'), findsWidgets);
  });

  testWidgets('Profil : pseudo modifiable et affiché sur l’accueil', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sans pseudonyme'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Théo');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Théo'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bonjour Théo'), findsOneWidget);
  });

  testWidgets('Médaille obtenue : annoncée une seule fois', (tester) async {
    await pumpApp(
      tester,
      prefs: {'intro_seen': true, 'lesson.return.completed': true},
    );
    await tester.pump(); // annonce après l'affichage
    await tester.pump(); // enregistrement puis message
    expect(find.text('Médaille obtenue'), findsOneWidget);
    expect(find.text('Premier pas'), findsOneWidget);

    final storage = await SharedPreferences.getInstance();
    expect(storage.getStringList('announced_medals'), ['first_lesson:1']);

    // L'annonce disparaît seule au bout de quelques secondes.
    // Le minuteur démarre une fois la carte entrée à l'écran.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(MedalToast), findsNothing);
  });

  testWidgets('Ma progression : médailles et statistiques Past Trader', (
    tester,
  ) async {
    final dao = FakeTraderAttemptDao();
    // Meilleur écart avec le S&P 500 : +20 points (Efficience record, Cuivre).
    for (final (perf, early) in [(0.5, false), (0.1, true)]) {
      await dao.insert(
        gameId: pastTraderData.id,
        playedAt: DateTime(2026, 10, 6),
        endDate: DateTime(2020, 12, 31),
        finalValue: 10000 * (1 + perf),
        performance: perf,
        spyPerformance: 0.3,
        maxDrawdown: 0.3,
        tradesCount: 3,
        stoppedEarly: early,
      );
    }
    await pumpApp(
      tester,
      attempts: dao,
      prefs: {
        'intro_seen': true,
        'lesson.return.completed': true,
        // Déjà annoncées : pas de message par-dessus l'écran.
        'announced_medals': [
          'first_lesson:1',
          'trader:1',
          'persistent:1',
          'to_the_end:1',
          'efficiency:1',
          'efficiency:2',
        ],
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Médailles et statistiques'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageTitle, 'Ma progression'), findsOneWidget);
    expect(find.text('5 / 12'), findsOneWidget); // médailles obtenues
    expect(find.text('Cuivre'), findsOneWidget); // Efficience record
    expect(find.text('Premier pas'), findsOneWidget);

    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Mieux que le S&P 500'),
      300,
      scrollable: list,
    );
    expect(find.text(pastTraderData.title), findsOneWidget);
    expect(find.text('2 (dont 1 rejouée(s))'), findsOneWidget);
    expect(find.text('1 fois sur 2'), findsOneWidget);
  });

  testWidgets('Les libellés de la barre se cachent en descendant et '
      'reviennent quand on touche un onglet', (tester) async {
    await pumpApp(tester);
    final label = find.descendant(of: tabBar, matching: find.text('Learn'));
    expect(label, findsOneWidget);

    // Défiler vers le bas : les libellés disparaissent.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(label, findsNothing);

    // Toucher un onglet : ils reviennent.
    await tester.tap(
      find.descendant(of: tabBar, matching: find.byIcon(learnSection.icon)),
    );
    await tester.pumpAndSettle();
    expect(label, findsOneWidget);
  });

  testWidgets('Les libellés reviennent en revenant d’une page empilée', (
    tester,
  ) async {
    await pumpApp(tester);
    final label = find.descendant(of: tabBar, matching: find.text('Learn'));

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(label, findsNothing); // cachés en descendant

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(label, findsOneWidget); // revenus au retour
  });

  testWidgets('Pastille AI sur Foresight et Past Trader, pas sur Learn', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(
      find.descendant(of: tabBar, matching: find.byIcon(learnSection.icon)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AiBadge), findsNothing);

    await tester.tap(
      find.descendant(of: tabBar, matching: find.byIcon(foresightSection.icon)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AiBadge), findsOneWidget);

    await tester.tap(find.byType(AiBadge));
    await tester.pumpAndSettle();
    expect(find.textContaining('proposés par une IA'), findsOneWidget);
  });
}
