import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/playground/replay.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/logic/time_cursor.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';

import '../helpers.dart';

/// 1000 investis le lundi 1er janvier (cours 100) → 10 parts.
/// Cours : 100, 110, 90, 95, 120 (ven. 5), puis 130 (lun. 8).
Replay newReplay() => Replay(
  simulateLumpSum(
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
  ),
);

void main() {
  test('démarre au jour d’achat : valeur = montant investi', () {
    final r = newReplay();
    expect(r.currentDate, d(2024, 1, 1));
    expect(r.visibleCount, 1);
    expect(r.currentValue, 1000);
    expect(r.currentGain, 0);
    expect(r.isAtStart, isTrue);
  });

  test('+1 jour : un point de plus, valeur du jour', () {
    final r = newReplay()..advance(TimeStep.day);
    expect(r.visibleCount, 2);
    expect(r.currentValue, 1100);
    expect(r.currentGain, 100);
    expect(r.currentPerformance, closeTo(0.10, 1e-9));
  });

  test('une perte temporaire est visible en cours de route', () {
    final r = newReplay()
      ..advance(TimeStep.day)
      ..advance(TimeStep.day); // mercredi 3 : cours 90
    expect(r.currentGain, -100);
  });

  test('le week-end : marché fermé, valeur du vendredi', () {
    final r = newReplay();
    for (var i = 0; i < 5; i++) {
      r.advance(TimeStep.day); // → samedi 6
    }
    expect(r.isMarketOpen, isFalse);
    expect(r.currentPoint.date, d(2024, 1, 5));
    expect(r.currentValue, 1200);
    expect(r.visibleCount, 5); // pas de point inventé pour le samedi
  });

  test('+7 jours : arrive à la fin, valeur finale du résultat', () {
    final r = newReplay()..advance(TimeStep.week);
    expect(r.isAtEnd, isTrue);
    expect(r.currentValue, r.result.finalValue);
    expect(r.visibleCount, r.result.history.length);
  });

  test('aller à la fin puis recommencer', () {
    final r = newReplay()..jumpToEnd();
    expect(r.isAtEnd, isTrue);
    r.reset();
    expect(r.isAtStart, isTrue);
    expect(r.visibleCount, 1);
  });
}
