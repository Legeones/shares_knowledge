import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/screens/playground/playground_screen.dart';

Future<void> pumpPlayground(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: PlaygroundScreen())),
  );
}

void main() {
  testWidgets('envoyer sans actif ni montant affiche les erreurs', (
    tester,
  ) async {
    await pumpPlayground(tester);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('Lancer la simulation'));
    await tester.pump();

    expect(find.text('Choisis un actif.'), findsOneWidget);
    expect(find.text('Indique un montant.'), findsOneWidget);
  });

  testWidgets('l’erreur disparaît dès que la saisie est corrigée', (
    tester,
  ) async {
    await pumpPlayground(tester);

    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('Lancer la simulation'));
    await tester.pump();
    expect(find.text('Le montant doit être supérieur à 0.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '500');
    await tester.pump();
    expect(find.text('Le montant doit être supérieur à 0.'), findsNothing);
  });

  testWidgets('choisir un actif dans la liste filtrée remplit le champ', (
    tester,
  ) async {
    await pumpPlayground(tester);

    await tester.tap(find.text('Toucher pour choisir'));
    await tester.pumpAndSettle(); // ouverture + lecture du catalogue

    await tester.enterText(find.byType(TextField), 'bitc');
    await tester.pump();
    // On cherche dans les lignes de la liste (le texte d'aide du champ de
    // recherche contient lui aussi le mot « Bitcoin »).
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Bitcoin (BTC/USD)'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle(); // retour au formulaire

    expect(find.text('Bitcoin (BTC/USD)'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget); // devise à côté du montant
  });

  testWidgets('« Chaque mois » : le montant devient mensuel', (tester) async {
    await pumpPlayground(tester);
    expect(find.text('Montant investi'), findsOneWidget);

    await tester.tap(find.text('Chaque mois'));
    await tester.pump();
    expect(find.text('Montant versé chaque mois'), findsOneWidget);
    expect(find.text('Premier versement'), findsOneWidget);
  });
}
