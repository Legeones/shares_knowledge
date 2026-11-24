import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Ouverture de la base SQLite locale et création des tables.
class AppDatabase {
  static const _fileName = 'shares_knowledge.db';

  /// v1 = cache des cours ; v2 = + simulations sauvegardées ;
  /// v3 = + parties Past Trader ; v4 = + portefeuille en temps réel.
  static const _version = 4;

  /// [path] et [factory] : pour les tests (base en mémoire).
  static Future<Database> open({String? path, DatabaseFactory? factory}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? join(await getDatabasesPath(), _fileName);

    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createPriceTables(db);
    await _createSavedSimulationTable(db);
    await _createTraderAttemptTable(db);
    await _createWalletTables(db);
  }

  /// Ajoute les tables manquantes sans effacer le cache.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createSavedSimulationTable(db);
    if (oldVersion < 3) await _createTraderAttemptTable(db);
    if (oldVersion < 4) await _createWalletTables(db);
  }

  static Future<void> _createPriceTables(Database db) async {
    // Dates en "AAAA-MM-JJ" : l'ordre du texte est l'ordre chronologique.
    await db.execute('''
      CREATE TABLE price_point (
        symbol TEXT NOT NULL,
        date   TEXT NOT NULL,
        close  REAL NOT NULL,
        PRIMARY KEY (symbol, date)
      )
    ''');

    // Pour chaque actif, la période déjà demandée à l'API.
    await db.execute('''
      CREATE TABLE price_coverage (
        symbol     TEXT PRIMARY KEY,
        from_date  TEXT NOT NULL,
        to_date    TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Une simulation sauvegardée par ligne.
  static Future<void> _createSavedSimulationTable(Database db) async {
    await db.execute('''
      CREATE TABLE saved_simulation (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT NOT NULL,
        params_json  TEXT NOT NULL,
        actual_start TEXT NOT NULL,
        actual_end   TEXT NOT NULL,
        final_value  REAL NOT NULL,
        gain         REAL NOT NULL,
        performance  REAL NOT NULL,
        max_drawdown REAL NOT NULL,
        created_at   TEXT NOT NULL
      )
    ''');
  }

  /// Une partie Past Trader terminée par ligne.
  static Future<void> _createTraderAttemptTable(Database db) async {
    await db.execute('''
      CREATE TABLE trader_attempt (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id         TEXT NOT NULL,
        played_at       TEXT NOT NULL,
        end_date        TEXT NOT NULL,
        final_value     REAL NOT NULL,
        performance     REAL NOT NULL,
        spy_performance REAL NOT NULL,
        max_drawdown    REAL NOT NULL,
        trades_count    INTEGER NOT NULL,
        stopped_early   INTEGER NOT NULL
      )
    ''');
  }

  /// Portefeuille en temps réel du Playground : une ligne d'informations, les
  /// opérations (dépôts, achats, ventes), les versements mensuels et les règles
  /// de vente automatique.
  static Future<void> _createWalletTables(Database db) async {
    // id = 1 : un seul portefeuille.
    await db.execute('''
      CREATE TABLE wallet (
        id              INTEGER PRIMARY KEY CHECK (id = 1),
        created_at      TEXT NOT NULL,
        processed_until TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wallet_transaction (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        date   TEXT NOT NULL,
        type   TEXT NOT NULL,
        source TEXT NOT NULL,
        symbol TEXT,
        units  REAL NOT NULL,
        price  REAL NOT NULL,
        amount REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wallet_dca_plan (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol       TEXT NOT NULL,
        name         TEXT NOT NULL,
        amount       REAL NOT NULL,
        day_of_month INTEGER NOT NULL,
        created_at   TEXT NOT NULL,
        last_target  TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE wallet_rule (
        symbol      TEXT PRIMARY KEY,
        stop_loss   REAL,
        take_profit REAL
      )
    ''');
  }
}
