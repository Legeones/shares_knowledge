import 'package:sqflite/sqflite.dart';

import '../local/price_cache_dao.dart';
import '../../models/price_point.dart';
import '../../models/wallet/wallet.dart';

/// Ce qui est enregistré du portefeuille.
typedef WalletData = ({
  DateTime createdAt,
  DateTime processedUntil,
  List<WalletTransaction> transactions,
  List<DcaPlan> plans,
  Map<String, PositionRule> rules,
});

/// Toutes les requêtes SQL du portefeuille en temps réel.
class WalletDao {
  final Database _db;
  WalletDao(this._db);

  /// null si le portefeuille n'a pas encore été créé.
  Future<WalletData?> load() async {
    final info = await _db.query('wallet');
    if (info.isEmpty) return null;
    final row = info.single;
    return (
      createdAt: dateOnly(DateTime.parse(row['created_at'] as String)),
      processedUntil: dateOnly(
        DateTime.parse(row['processed_until'] as String),
      ),
      transactions: [
        for (final r in await _db.query('wallet_transaction', orderBy: 'id'))
          WalletTransaction.fromRow(r),
      ],
      plans: [
        for (final r in await _db.query('wallet_dca_plan', orderBy: 'id'))
          DcaPlan.fromRow(r),
      ],
      rules: {
        for (final r in await _db.query('wallet_rule'))
          r['symbol'] as String: PositionRule.fromRow(r),
      },
    );
  }

  /// Crée le portefeuille (et efface un éventuel ancien).
  Future<void> create(DateTime createdAt, DateTime processedUntil) async {
    await reset();
    await _db.insert('wallet', {
      'id': 1,
      'created_at': toDbDate(createdAt),
      'processed_until': toDbDate(processedUntil),
    });
  }

  Future<void> setProcessedUntil(DateTime date) =>
      _db.update('wallet', {'processed_until': toDbDate(date)});

  /// Une transaction SQLite : tout est écrit, ou rien (en cas d'erreur).
  Future<void> addTransactions(List<WalletTransaction> transactions) =>
      _db.transaction((txn) async {
        for (final t in transactions) {
          await txn.insert('wallet_transaction', t.toRow());
        }
      });

  Future<void> savePlan(DcaPlan plan) => plan.id == null
      ? _db.insert('wallet_dca_plan', plan.toRow())
      : _db.update(
          'wallet_dca_plan',
          plan.toRow(),
          where: 'id = ?',
          whereArgs: [plan.id],
        );

  Future<void> deletePlan(int id) =>
      _db.delete('wallet_dca_plan', where: 'id = ?', whereArgs: [id]);

  /// Enregistre la règle d'un actif ; une règle vide la supprime.
  Future<void> saveRule(PositionRule rule) => rule.isEmpty
      ? deleteRule(rule.symbol)
      : _db.insert(
          'wallet_rule',
          rule.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

  Future<void> deleteRule(String symbol) =>
      _db.delete('wallet_rule', where: 'symbol = ?', whereArgs: [symbol]);

  Future<void> reset() async {
    for (final table in [
      'wallet',
      'wallet_transaction',
      'wallet_dca_plan',
      'wallet_rule',
    ]) {
      await _db.delete(table);
    }
  }
}
