import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/time_cursor.dart';

import 'helpers.dart';

void main() {
  group('addStep', () {
    test('+1 jour, +7 jours, +1 mois classiques', () {
      expect(addStep(d(2024, 3, 10), TimeStep.day), d(2024, 3, 11));
      expect(addStep(d(2024, 3, 10), TimeStep.week), d(2024, 3, 17));
      expect(addStep(d(2024, 3, 10), TimeStep.month), d(2024, 4, 10));
    });

    test('passage d’un mois et d’une année', () {
      expect(addStep(d(2024, 1, 31), TimeStep.day), d(2024, 2, 1));
      expect(addStep(d(2024, 12, 28), TimeStep.week), d(2025, 1, 4));
      expect(addStep(d(2024, 12, 15), TimeStep.month), d(2025, 1, 15));
    });

    test('31 janvier + 1 mois = dernier jour de février', () {
      expect(
        addStep(d(2024, 1, 31), TimeStep.month),
        d(2024, 2, 29),
      ); // bissextile
      expect(addStep(d(2023, 1, 31), TimeStep.month), d(2023, 2, 28));
    });

    test('31 mars + 1 mois = 30 avril', () {
      expect(addStep(d(2024, 3, 31), TimeStep.month), d(2024, 4, 30));
    });
  });

  group('TimeCursor', () {
    TimeCursor cursor() => TimeCursor(
      series: weekSeries,
      start: d(2024, 1, 1),
      end: d(2024, 1, 8),
    );

    test('démarre au début avec le cours du jour', () {
      final c = cursor();
      expect(c.current, d(2024, 1, 1));
      expect(c.currentPrice!.close, 100);
      expect(c.isMarketOpen, isTrue);
    });

    test('le week-end : marché fermé, dernier cours connu', () {
      final c = cursor();
      for (var i = 0; i < 5; i++) {
        c.advance(TimeStep.day);
      }
      expect(c.current, d(2024, 1, 6));
      expect(c.isMarketOpen, isFalse);
      expect(c.currentPrice!.close, 120); // celui du vendredi
    });

    test('ne dépasse jamais la date de fin', () {
      final c = cursor();
      c.advance(TimeStep.month);
      expect(c.current, d(2024, 1, 8));
      expect(c.isAtEnd, isTrue);
    });

    test('reset revient au début', () {
      final c = cursor()..advance(TimeStep.week);
      c.reset();
      expect(c.current, d(2024, 1, 1));
    });
  });

  group('autoPlayDuration', () {
    test('période courte : 15 s minimum', () {
      expect(autoPlayDuration(7), const Duration(seconds: 15));
    });

    test('la durée grandit avec la période', () {
      expect(autoPlayDuration(365).inMilliseconds, closeTo(16083, 1));
      expect(autoPlayDuration(5 * 365).inMilliseconds, closeTo(40417, 1));
    });

    test('très longue période : 60 s maximum', () {
      expect(autoPlayDuration(20 * 365), const Duration(seconds: 60));
    });
  });

  group('jumpTo', () {
    TimeCursor cursor() => TimeCursor(
      series: weekSeries,
      start: d(2024, 1, 1),
      end: d(2024, 1, 8),
    );

    test('va à la date demandée', () {
      expect((cursor()..jumpTo(d(2024, 1, 4))).current, d(2024, 1, 4));
    });

    test('reste dans la période', () {
      expect((cursor()..jumpTo(d(2023, 1, 1))).current, d(2024, 1, 1));
      expect((cursor()..jumpTo(d(2025, 1, 1))).current, d(2024, 1, 8));
    });
  });
}
