import 'package:flutter/foundation.dart';

import '../../logic/past_trader/news_feed.dart';
import '../../logic/time_cursor.dart';
import '../../logic/past_trader/trading.dart';
import '../../models/past_trader/news.dart';
import '../../models/past_trader/past_trader.dart';
import '../../models/past_trader/trader_save.dart';

/// Partage une partie Past Trader entre les écrans (marché, fiche d'un
/// actif, portefeuille, actualités) et les prévient à chaque changement.
class TraderGameController extends ChangeNotifier {
  final TraderGame game;
  final NewsFeed news;

  TraderGameController(TraderGameData data, this.news)
    : game = TraderGame(data),
      // Les actualités d'avant le début (le contexte) comptent comme non lues.
      _readCount = 0;

  /// Reprend une partie quittée : ses décisions sont rejouées dans l'ordre.
  TraderGameController.resume(TraderGameData data, this.news, TraderSave save)
    : game = TraderGame(data),
      _readCount = save.readCount {
    for (final action in save.actions) {
      _apply(action);
    }
    _log.addAll(save.actions);
  }

  int _readCount;
  final List<NewsItem> _flashes = [];

  /// Journal des décisions, enregistré pour pouvoir reprendre la partie.
  final List<TraderAction> _log = [];

  /// Ce qu'il faut enregistrer pour reprendre la partie plus tard.
  TraderSave snapshot(DateTime now) => TraderSave(
    gameId: game.data.id,
    savedAt: now,
    current: game.current,
    totalValue: game.totalValue,
    readCount: _readCount,
    actions: List.of(_log),
  );

  void _apply(TraderAction action) {
    final symbol = action['symbol'] as String?;
    final amount = (action['amount'] as num?)?.toDouble();
    switch (action['type']) {
      case 'advance':
        game.advanceTo(DateTime.parse(action['date'] as String));
      case 'buy':
        game.buy(symbol!, amount!);
      case 'sell':
        game.sell(symbol!, amount: amount, all: action['all'] == true);
    }
  }

  /// Actualités connues à la date courante, la plus récente en premier.
  List<NewsItem> get knownNews => news.until(game.current);

  int get unreadCount => knownNews.length - _readCount;

  void markNewsRead() {
    if (unreadCount == 0) return;
    _readCount = knownNews.length;
    notifyListeners();
  }

  /// Actualités majeures révélées par la dernière avancée, pas encore montrées.
  bool get hasFlash => _flashes.isNotEmpty;

  List<NewsItem> takeFlashes() {
    final out = [..._flashes];
    _flashes.clear();
    return out;
  }

  /// Passe un ordre ; renvoie le message d'erreur, ou null si exécuté.
  String? buy(String symbol, double amount) =>
      _order({'type': 'buy', 'symbol': symbol, 'amount': amount});

  String? sell(String symbol, {double? amount, bool all = false}) =>
      _order({'type': 'sell', 'symbol': symbol, 'amount': amount, 'all': all});

  String? _order(TraderAction action) {
    try {
      _apply(action);
      _log.add(action); // seuls les ordres exécutés sont rejoués
      notifyListeners();
      return null;
    } on OrderException catch (e) {
      return e.message;
    }
  }

  /// Arrêter la partie maintenant (bilan à la date courante).
  void stop() {
    game.stop();
    notifyListeners();
  }

  void advance(TimeStep step) => advanceTo(addStep(game.current, step));

  void advanceTo(DateTime date) {
    final before = game.current;
    if (!date.isAfter(before)) return;
    game.advanceTo(date);
    // Deux avancées de suite n'en font qu'une (la lecture automatique avance
    // à chaque image) : seule la dernière date compte.
    if (_log.lastOrNull?['type'] == 'advance') _log.removeLast();
    _log.add({'type': 'advance', 'date': game.current.toIso8601String()});
    _flashes.addAll(news.between(before, game.current).where((n) => n.major));
    notifyListeners();
  }
}
