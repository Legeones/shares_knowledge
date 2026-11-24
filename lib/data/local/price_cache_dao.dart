import 'package:sqflite/sqflite.dart';

import '../../models/price_point.dart';

/// Période déjà téléchargée pour un actif, et date du téléchargement.
class Coverage {
  final DateTime from;
  final DateTime to;
  final DateTime updatedAt;

  const Coverage({
    required this.from,
    required this.to,
    required this.updatedAt,
  });

  /// Vrai si toute la période [start, end] est déjà en cache.
  bool covers(DateTime start, DateTime end) =>
      !start.isBefore(from) && !end.isAfter(to);
}

/// Requêtes SQL du cache des cours.
class PriceCacheDao {
  final Database _db;
  PriceCacheDao(this._db);

  /// Cours d'un actif entre deux dates incluses, du plus ancien au plus récent.
  Future<List<PricePoint>> getPoints(
    String symbol,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.query(
      'price_point',
      where: 'symbol = ? AND date >= ? AND date <= ?',
      whereArgs: [symbol, toDbDate(start), toDbDate(end)],
      orderBy: 'date ASC',
    );
    return [
      for (final row in rows)
        PricePoint(
          date: DateTime.parse(row['date'] as String),
          close: (row['close'] as num).toDouble(),
        ),
    ];
  }

  Future<Coverage?> getCoverage(String symbol) async {
    final rows = await _db.query(
      'price_coverage',
      where: 'symbol = ?',
      whereArgs: [symbol],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return Coverage(
      from: dateOnly(DateTime.parse(row['from_date'] as String)),
      to: dateOnly(DateTime.parse(row['to_date'] as String)),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Enregistre de nouveaux cours et la nouvelle période couverte.
  Future<void> save(
    String symbol,
    List<PricePoint> points,
    Coverage coverage,
  ) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final p in points) {
        batch.insert('price_point', {
          'symbol': symbol,
          'date': toDbDate(p.date),
          'close': p.close,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.insert('price_coverage', {
        'symbol': symbol,
        'from_date': toDbDate(coverage.from),
        'to_date': toDbDate(coverage.to),
        'updated_at': coverage.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }
}

/// 2024-01-05 donne "2024-01-05"
String toDbDate(DateTime d) => dateOnly(d).toIso8601String().substring(0, 10);
