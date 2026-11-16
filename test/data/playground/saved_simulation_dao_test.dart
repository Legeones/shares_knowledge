import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/local/app_database.dart';
import 'package:shares_knowledge/data/playground/saved_simulation_dao.dart';
import 'package:shares_knowledge/logic/playground/simulator.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/simulation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../logic/helpers.dart';
import '../fake_market.dart';

final result = simulateLumpSum(
  SimulationParams(
    asset: const Asset(
      symbol: 'BTC/USD',
      name: 'Bitcoin',
      currency: 'USD',
      type: AssetType.crypto,
      description: 'Première cryptomonnaie.',
    ),
    amount: 1000,
    start: d(2024, 1, 1),
    end: d(2024, 1, 8),
  ),
  weekSeries,
);

void main() {
  late Database db;
  late SavedSimulationDao dao;

  setUp(() async {
    db = await inMemoryDatabase();
    dao = SavedSimulationDao(db);
  });
  tearDown(() => db.close());

  test('enregistrer puis relire : tout est conservé', () async {
    await dao.insert('Mon test', result, DateTime(2026, 10, 5, 14, 30));
    final saved = (await dao.getAll()).single;

    expect(saved.name, 'Mon test');
    expect(saved.params.asset.symbol, 'BTC/USD');
    expect(saved.params.asset.type, AssetType.crypto);
    expect(saved.params.amount, 1000);
    expect(saved.params.start, d(2024, 1, 1));
    expect(saved.actualEnd, d(2024, 1, 8));
    expect(saved.finalValue, result.finalValue);
    expect(saved.performance, result.performance);
    expect(saved.createdAt, DateTime(2026, 10, 5, 14, 30));
  });

  test('les plus récentes en premier', () async {
    await dao.insert('Ancienne', result, DateTime(2026, 1, 1));
    await dao.insert('Récente', result, DateTime(2026, 6, 1));
    expect((await dao.getAll()).map((s) => s.name), ['Récente', 'Ancienne']);
  });

  test('renommer', () async {
    final id = await dao.insert('Avant', result, DateTime(2026));
    await dao.rename(id, 'Après');
    expect((await dao.getAll()).single.name, 'Après');
  });

  test('supprimer une sauvegarde ne touche pas les autres', () async {
    final a = await dao.insert('A', result, DateTime(2026, 1, 1));
    await dao.insert('B', result, DateTime(2026, 1, 2));
    await dao.delete(a);
    expect((await dao.getAll()).map((s) => s.name), ['B']);
  });

  test('tout supprimer', () async {
    await dao.insert('A', result, DateTime(2026));
    await dao.insert('B', result, DateTime(2026));
    await dao.deleteAll();
    expect(await dao.getAll(), isEmpty);
  });

  test('migration v1 → v2 : la table est ajoutée, le cache conservé', () async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfiNoIsolate;
    // Un vrai fichier temporaire : il faut fermer puis rouvrir la base.
    final dir = Directory.systemTemp.createTempSync('sk_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/test.db';

    // 1. Base « ancienne version » (v1) : seulement le cache, avec une ligne.
    final v1 = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE price_coverage (symbol TEXT PRIMARY KEY, '
            'from_date TEXT, to_date TEXT, updated_at TEXT)',
          );
          await db.insert('price_coverage', {
            'symbol': 'AAPL',
            'from_date': '2024-01-01',
            'to_date': '2024-01-31',
            'updated_at': '2026-10-05',
          });
        },
      ),
    );
    await v1.close();

    // 2. Mise à jour de l'application : réouverture avec la version 2.
    final v2 = await AppDatabase.open(path: path, factory: factory);
    expect(await v2.query('price_coverage'), hasLength(1)); // conservé
    expect(await v2.query('saved_simulation'), isEmpty); // ajoutée
    await v2.close();
  });
}
