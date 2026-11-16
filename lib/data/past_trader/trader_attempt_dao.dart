import 'package:sqflite/sqflite.dart';

import '../../models/price_point.dart';
import '../../models/past_trader/trader_attempt.dart';
import '../local/price_cache_dao.dart' show toDbDate;

class TraderAttemptDao {
  final Database _db;
  TraderAttemptDao(this._db);

  /// Les plus récentes en premier ; une partie est une « répétition » s'il
  /// en existe une plus ancienne du même jeu.
  Future<List<TraderAttempt>> getAll() async {
    final rows = await _db.query('trader_attempt', orderBy: 'played_at ASC');
    final seen = <String>{};
    final attempts = [
      for (final row in rows)
        TraderAttempt(
          id: row['id'] as int,
          gameId: row['game_id'] as String,
          playedAt: DateTime.parse(row['played_at'] as String),
          endDate: dateOnly(DateTime.parse(row['end_date'] as String)),
          finalValue: (row['final_value'] as num).toDouble(),
          performance: (row['performance'] as num).toDouble(),
          spyPerformance: (row['spy_performance'] as num).toDouble(),
          maxDrawdown: (row['max_drawdown'] as num).toDouble(),
          tradesCount: row['trades_count'] as int,
          stoppedEarly: row['stopped_early'] == 1,
          // add renvoie faux si le jeu était déjà dans l'ensemble.
          isRepeat: !seen.add(row['game_id'] as String),
        ),
    ];
    return attempts.reversed.toList();
  }

  Future<void> insert({
    required String gameId,
    required DateTime playedAt,
    required DateTime endDate,
    required double finalValue,
    required double performance,
    required double spyPerformance,
    required double maxDrawdown,
    required int tradesCount,
    required bool stoppedEarly,
  }) async {
    await _db.insert('trader_attempt', {
      'game_id': gameId,
      'played_at': playedAt.toIso8601String(),
      'end_date': toDbDate(endDate),
      'final_value': finalValue,
      'performance': performance,
      'spy_performance': spyPerformance,
      'max_drawdown': maxDrawdown,
      'trades_count': tradesCount,
      'stopped_early': stoppedEarly ? 1 : 0, // SQLite n'a pas de booléen
    });
  }

  Future<void> deleteAll() async {
    await _db.delete('trader_attempt');
  }
}
