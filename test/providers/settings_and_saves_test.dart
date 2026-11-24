import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/logic/taxes.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';
import 'package:shares_knowledge/providers/playground/saves_provider.dart';
import 'package:shares_knowledge/providers/settings_provider.dart';

import '../fakes.dart';
import '../logic/helpers.dart';

final params = SimulationParams(
  asset: const Asset(
    symbol: 'AAPL',
    name: 'Apple',
    currency: 'USD',
    type: AssetType.stock,
  ),
  amount: 1000,
  start: d(2024, 1, 1),
  end: d(2024, 1, 8),
);

Future<SettingsProvider> settingsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsProvider(await SharedPreferences.getInstance());
}

void main() {
  group('SimulationParams JSON', () {
    test('toJson puis fromJson redonne les mêmes paramètres', () {
      final copy = SimulationParams.fromJson(params.toJson());
      expect(copy.asset.symbol, 'AAPL');
      expect(copy.asset.type, AssetType.stock);
      expect(copy.amount, 1000);
      expect(copy.start, d(2024, 1, 1));
      expect(copy.end, d(2024, 1, 8));
    });
  });

  group('SettingsProvider', () {
    test('valeurs par défaut', () async {
      final s = await settingsWith({});
      expect(s.introSeen, isFalse);
      expect(s.pseudo, '');
      expect(s.reduceAnimations, isFalse);
      expect(s.playgroundRuns, 0);
      expect(s.lastSimulation, isNull);
    });

    test('les réglages sont enregistrés', () async {
      final s = await settingsWith({});
      await s.markIntroSeen();
      await s.setPseudo('  Théo  ');
      await s.setReduceAnimations(true);

      // Relecture depuis le stockage, comme après un redémarrage.
      final reloaded = SettingsProvider(await SharedPreferences.getInstance());
      expect(reloaded.introSeen, isTrue);
      expect(reloaded.pseudo, 'Théo'); // espaces retirés
      expect(reloaded.reduceAnimations, isTrue);
    });

    test('une simulation lancée : compteur + dernière simulation', () async {
      final s = await settingsWith({});
      await s.recordPlaygroundRun(params);
      await s.recordPlaygroundRun(params);
      expect(s.playgroundRuns, 2);
      expect(s.lastSimulation!.asset.name, 'Apple');
    });

    test('actifs simulés : chacun compté une seule fois', () async {
      final s = await settingsWith({});
      final bitcoin = SimulationParams(
        asset: const Asset(
          symbol: 'BTC/USD',
          name: 'Bitcoin',
          currency: 'USD',
          type: AssetType.crypto,
        ),
        amount: 100,
        start: d(2024, 1, 1),
        end: d(2024, 1, 8),
      );
      await s.recordPlaygroundRun(params);
      await s.recordPlaygroundRun(params);
      await s.recordPlaygroundRun(bitcoin);
      expect(s.playgroundAssets, {'AAPL', 'BTC/USD'});
    });

    test('médailles annoncées : mémorisées sans doublon', () async {
      final s = await settingsWith({});
      await s.markMedalsAnnounced(['first_lesson']);
      await s.markMedalsAnnounced(['first_lesson', 'explorer']);
      final reloaded = SettingsProvider(await SharedPreferences.getInstance());
      expect(reloaded.announcedMedals, {'first_lesson', 'explorer'});
    });

    test('année de naissance et situation fiscale mémorisées', () async {
      final s = await settingsWith({});
      expect(s.birthYear, isNull);
      expect(s.hasTaxProfile, isFalse);
      await s.setBirthYear(1985);
      await s.setTaxProfile(
        TaxProfile(taxCountryFor('US'), state: usStates[0]),
      );
      final reloaded = SettingsProvider(await SharedPreferences.getInstance());
      expect(reloaded.birthYear, 1985);
      expect(reloaded.hasTaxProfile, isTrue);
      expect(
        reloaded.taxProfile().summary,
        'États-Unis · Californie · revenus moyens',
      );
      await reloaded.setBirthYear(null);
      expect(reloaded.birthYear, isNull);
    });

    test('dernière simulation illisible : ignorée sans planter', () async {
      final s = await settingsWith({'last_simulation': 'pas du JSON'});
      expect(s.lastSimulation, isNull);
    });

    test('remise à zéro : progression effacée, réglages gardés', () async {
      final s = await settingsWith({'pseudo': 'Théo'});
      await s.recordPlaygroundRun(params);
      await s.markMedalsAnnounced(['first_simulation']);
      await s.resetProgress();
      expect(s.playgroundRuns, 0);
      expect(s.lastSimulation, isNull);
      expect(s.playgroundAssets, isEmpty);
      expect(s.announcedMedals, isEmpty);
      expect(s.pseudo, 'Théo');
    });
  });

  group('SavesProvider', () {
    final result = simulateLumpSum(params, weekSeries);

    test('sauvegarder, renommer, supprimer', () async {
      final saves = SavesProvider(FakeSavedSimulationDao());
      await saves.load();
      expect(saves.items, isEmpty);

      await saves.save('  Ma simu  ', result);
      expect(saves.items.single.name, 'Ma simu');

      await saves.rename(saves.items.single.id, 'Renommée');
      expect(saves.items.single.name, 'Renommée');

      await saves.delete(saves.items.single.id);
      expect(saves.items, isEmpty);
    });

    test('les écrans sont prévenus de chaque changement', () async {
      final saves = SavesProvider(FakeSavedSimulationDao());
      var notifications = 0;
      saves.addListener(() => notifications++);
      await saves.load();
      await saves.save('A', result);
      expect(notifications, 2);
    });
  });
}
