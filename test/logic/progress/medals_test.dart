import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/progress/medals.dart';

void main() {
  MedalStatus statusOf(String id, ProgressSnapshot s) =>
      evaluateMedals(s).firstWhere((m) => m.medal.id == id);

  test('au départ, aucune médaille', () {
    final all = evaluateMedals(const ProgressSnapshot(lessonsAvailable: 2));
    expect(all.where((m) => m.earned), isEmpty);
    expect(all.length, medals.length);
  });

  test('médaille simple : premier pas', () {
    final s = statusOf(
      'first_lesson',
      const ProgressSnapshot(lessonsCompleted: 1, lessonsAvailable: 2),
    );
    expect(s.earned, isTrue);
    expect(s.tier, isNull); // pas de palier
    expect(s.maxed, isTrue);
  });

  test('bon élève : toutes les leçons, mais jamais « 0 sur 0 »', () {
    final half = statusOf(
      'all_lessons',
      const ProgressSnapshot(lessonsCompleted: 1, lessonsAvailable: 2),
    );
    expect(half.earned, isFalse);
    expect(half.ratio, 0.5);
    expect(statusOf('all_lessons', const ProgressSnapshot()).earned, isFalse);
  });

  group('médailles à niveaux', () {
    test('Explorateur : Fer, Cuivre, Or, Diamant selon le nombre d’actifs', () {
      MedalStatus at(int n) =>
          statusOf('explorer', ProgressSnapshot(distinctAssets: n));
      expect(at(1).earned, isFalse);
      expect(at(2).tier, MedalTier.iron);
      expect(at(4).tier, MedalTier.copper);
      expect(at(8).tier, MedalTier.gold);
      expect(at(15).tier, MedalTier.diamond);
      expect(at(15).maxed, isTrue);
      expect(at(15).next, isNull);
    });

    test('prochain objectif et avancement', () {
      final s = statusOf(
        'simulator',
        const ProgressSnapshot(playgroundRuns: 3),
      );
      expect(s.tier, MedalTier.iron); // 1 simulation
      expect(s.next, 5); // Cuivre à 5
      expect(s.ratio, closeTo(0.6, 1e-9));
      expect(s.condition, 'Lancer 5 simulations dans le Playground.');
    });

    test('Efficience record : écart avec le S&P 500', () {
      MedalStatus at(double? x) =>
          statusOf('efficiency', ProgressSnapshot(bestExcessReturn: x));
      expect(at(null).earned, isFalse); // aucune partie
      expect(at(-0.05).earned, isFalse); // moins bien que l’indice
      expect(at(0.02).tier, MedalTier.iron); // mieux que l’indice
      expect(at(0.12).tier, MedalTier.copper); // +10 points
      expect(at(0.30).tier, MedalTier.gold); // +25 points
      expect(at(0.80).tier, MedalTier.diamond); // +50 points
      expect(at(0.12).medal.format(0.12), '+12,0 pts');
    });

    test('Voyageur du temps : décennies Perfect Foresight vues', () {
      expect(
        statusOf(
          'time_traveler',
          const ProgressSnapshot(foresightDecadesSeen: 4),
        ).tier,
        MedalTier.gold,
      );
    });
  });

  test('les médailles « bientôt » ne sont jamais obtenues', () {
    const everything = ProgressSnapshot(
      lessonsCompleted: 9,
      lessonsAvailable: 2,
      riskLessonsCompleted: 2,
      playgroundRuns: 99,
      monthlyRuns: 1,
      distinctAssets: 99,
      savedSimulations: 99,
      foresightDecadesSeen: 9,
      traderGames: 99,
      traderRepeats: 99,
      traderFullGames: 99,
      bestExcessReturn: 9,
    );
    for (final m in evaluateMedals(everything)) {
      expect(m.earned, !m.medal.comingSoon, reason: m.medal.id);
    }
  });

  group('annonces', () {
    test('seul le palier le plus haut est annoncé', () {
      final all = evaluateMedals(const ProgressSnapshot(distinctAssets: 8));
      final fresh = newlyEarned(all, {});
      expect(fresh.single.medal.id, 'explorer');
      expect(fresh.single.level, 3);
      expect(awardLabel(fresh.single), 'Explorateur (Or)');
    });

    test('un palier déjà annoncé ne l’est plus ; le suivant oui', () {
      final copper = evaluateMedals(const ProgressSnapshot(distinctAssets: 4));
      final keys = {for (final s in copper) ...earnedKeys(s)};
      expect(keys, {'explorer:1', 'explorer:2'});
      expect(newlyEarned(copper, keys), isEmpty);

      final gold = evaluateMedals(const ProgressSnapshot(distinctAssets: 8));
      expect(awardLabel(newlyEarned(gold, keys).single), 'Explorateur (Or)');
    });

    test('médaille simple : son nom seul', () {
      final all = evaluateMedals(const ProgressSnapshot(lessonsCompleted: 1));
      expect(newlyEarned(all, {}).map(awardLabel), ['Premier pas']);
    });
  });

  test('regard sur le risque : une des deux leçons sur le risque', () {
    expect(
      statusOf('risk', const ProgressSnapshot(riskLessonsCompleted: 1)).earned,
      isTrue,
    );
    expect(statusOf('risk', const ProgressSnapshot()).earned, isFalse);
  });
}
