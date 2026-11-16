import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/widgets/glass.dart';

void main() {
  /// Visibilité du titre dans la barre du haut.
  double barTitleOpacity(WidgetTester tester) {
    final inBar = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Profil'),
    );
    return tester
        .widget<Opacity>(
          find.ancestor(of: inBar, matching: find.byType(Opacity)).first,
        )
        .opacity;
  }

  testWidgets('la barre n’apparaît qu’après avoir dépassé le grand titre', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LargeTitleScaffold(
          title: 'Profil',
          body: ListView(
            children: [
              const PageTitle('Profil'),
              for (var i = 0; i < 40; i++) ListTile(title: Text('Ligne $i')),
            ],
          ),
        ),
      ),
    );
    // En haut de la page : grand titre visible, barre invisible.
    expect(find.widgetWithText(PageTitle, 'Profil'), findsOneWidget);
    expect(barTitleOpacity(tester), 0);

    // Un peu de défilement : la barre commence à apparaître.
    await tester.drag(find.byType(ListView), const Offset(0, -40));
    await tester.pump();
    expect(barTitleOpacity(tester), inExclusiveRange(0, 1));

    // Au-delà du grand titre : barre entièrement visible.
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(barTitleOpacity(tester), 1);
  });
}
