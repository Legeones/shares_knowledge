import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';
import 'package:shares_knowledge/widgets/playground/value_chart.dart';

import '../../logic/helpers.dart';

void main() {
  // Résultat réel calculé sur la semaine fictive des tests de logique.
  final result = simulateLumpSum(
    SimulationParams(
      asset: const Asset(
        symbol: 'TEST',
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

  Future<void> pumpChart(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: ValueChart(result: result)),
      ),
    ),
  );

  testWidgets('affiche la courbe, l’investi et la baisse maximale', (
    tester,
  ) async {
    await pumpChart(tester);

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Valeur'), findsOneWidget);
    expect(find.text('Montant investi'), findsOneWidget);
    expect(find.textContaining('Baisse maximale'), findsOneWidget);
  });

  testWidgets('bascule vers le cours : la ligne « investi » disparaît', (
    tester,
  ) async {
    await pumpChart(tester);

    await tester.tap(find.text('Cours'));
    await tester.pumpAndSettle();

    expect(find.text('Cours de clôture'), findsOneWidget);
    expect(find.text('Montant investi'), findsNothing);
  });

  testWidgets('versements mensuels : la somme versée monte par marches', (
    tester,
  ) async {
    final monthly = simulateMonthly(
      SimulationParams(
        asset: result.params.asset,
        amount: 100,
        start: d(2024, 1, 1),
        end: d(2024, 1, 8),
        mode: InvestMode.monthly,
      ),
      weekSeries,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ValueChart(result: monthly)),
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.any((b) => b.isStepLineChart), isTrue);
    expect(chart.data.extraLinesData.horizontalLines, isEmpty);
  });
}
