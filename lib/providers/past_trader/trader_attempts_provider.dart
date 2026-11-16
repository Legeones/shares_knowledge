import 'package:flutter/foundation.dart';

import '../../data/past_trader/trader_attempt_dao.dart';
import '../../models/past_trader/trader_attempt.dart';
import '../../logic/past_trader/trading.dart';

/// Historique des parties Past Trader, pour le profil et l'onglet.
class TraderAttemptsProvider extends ChangeNotifier {
  final TraderAttemptDao _dao;
  final DateTime Function() _now;

  TraderAttemptsProvider(this._dao, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  List<TraderAttempt> _items = [];
  List<TraderAttempt> get items => List.unmodifiable(_items);

  int get count => _items.length;
  int get repeatCount => _items.where((a) => a.isRepeat).length;

  Future<void> load() async {
    _items = await _dao.getAll();
    notifyListeners();
  }

  /// Enregistre une partie terminée.
  Future<void> record(TraderGame game) async {
    await _dao.insert(
      gameId: game.data.id,
      playedAt: _now(),
      endDate: game.current,
      finalValue: game.totalValue,
      performance: game.performance,
      spyPerformance: game.buyAndHoldSpy / game.data.initialCash - 1,
      maxDrawdown: game.drawdown.depth,
      tradesCount: game.trades.length,
      stoppedEarly: game.stoppedEarly,
    );
    await load();
  }

  Future<void> deleteAll() async {
    await _dao.deleteAll();
    await load();
  }
}
