import '../../models/drawdown.dart';
import '../../models/past_trader/past_trader.dart';
import '../../models/price_point.dart';
import '../drawdown.dart';
import '../price_series.dart';
import '../taxes.dart';
import '../time_cursor.dart';

enum TradeSide { buy, sell }

/// Un ordre exécuté, conservé pour l'historique et le calcul des impôts.
class Trade {
  final DateTime date;
  final String symbol;
  final TradeSide side;
  final double units;
  final double price;
  final double amount; // en dollars

  /// Plus-value (ou moins-value si négative) réalisée par une vente.
  final double realizedGain;

  /// Vente : jours depuis l'ouverture de la position (pour l'impôt).
  final int holdingDays;

  const Trade({
    required this.date,
    required this.symbol,
    required this.side,
    required this.units,
    required this.price,
    required this.amount,
    this.realizedGain = 0,
    this.holdingDays = 0,
  });
}

/// Une ligne du portefeuille : quantité détenue et prix de revient total.
class Position {
  double units;
  double cost;

  /// Date du premier achat de la position (durée de détention simplifiée).
  final DateTime openedAt;

  Position(this.units, this.cost, this.openedAt);

  /// Prix de revient moyen d'une part (méthode du « prix moyen pondéré »).
  double get averagePrice => cost / units;
}

/// Ordre refusé, avec un message pour l'utilisateur.
class OrderException implements Exception {
  final String message;
  const OrderException(this.message);

  @override
  String toString() => message;
}

/// Valeur du portefeuille à une date (pour la courbe et la baisse maximale).
typedef PortfolioPoint = ({DateTime date, double value});

/// Une partie Past Trader en cours.
///
/// Règles :
/// - le temps n'avance que vers l'avant ; une décision ne peut pas être
///   annulée après avoir vu la suite ;
/// - un ordre s'exécute au cours de clôture du jour courant, seulement si
///   l'actif est coté ce jour-là (pas de Bourse le week-end, crypto 7 j/7) ;
/// - parts fractionnaires autorisées, pas de frais.
class TraderGame {
  final TraderGameData data;
  final Map<String, PriceSeries> _series;

  DateTime _current;
  double _cash;
  final Map<String, Position> _positions = {};
  final List<Trade> _trades = [];
  final List<PortfolioPoint> _history = [];

  TraderGame(this.data)
    : _series = {for (final a in data.assets) a.symbol: PriceSeries(a.prices)},
      _current = data.start,
      _cash = data.initialCash {
    _record();
  }

  // --- Lecture de l'état -------------------------------------------------

  DateTime get current => _current;
  double get cash => _cash;
  Map<String, Position> get positions => Map.unmodifiable(_positions);
  List<Trade> get trades => List.unmodifiable(_trades);
  List<PortfolioPoint> get history => List.unmodifiable(_history);
  bool _stopped = false;

  /// Partie terminée : date de fin atteinte, ou arrêtée par le joueur.
  bool get isFinished => _stopped || !_current.isBefore(data.end);
  bool get stoppedEarly => _stopped && _current.isBefore(data.end);

  /// Arrêter la partie maintenant et passer au bilan.
  void stop() => _stopped = true;

  /// Dernier cours connu à la date courante (null si pas encore coté).
  double? priceOf(String symbol) =>
      _series[symbol]!.lastOnOrBefore(_current)?.close;

  /// L'actif a-t-il déjà un cours (Zoom n'est coté qu'à partir d'avril 2019) ?
  bool isListed(String symbol) => priceOf(symbol) != null;

  /// Peut-on passer un ordre aujourd'hui sur cet actif ?
  bool isMarketOpen(String symbol) => _series[symbol]!.isMarketDay(_current);

  /// Les cours **passés seulement** : jamais rien après la date courante.
  List<PricePoint> visiblePrices(String symbol) =>
      _series[symbol]!.between(data.historyFrom, _current);

  double positionValue(String symbol) {
    final p = _positions[symbol];
    return p == null ? 0 : p.units * priceOf(symbol)!;
  }

  /// Variation du cours sur les [days] derniers jours (null si inconnue).
  double? changeOver(String symbol, int days) {
    final now = priceOf(symbol);
    final before = _series[symbol]!.lastOnOrBefore(
      _current.subtract(Duration(days: days)),
    );
    if (now == null || before == null) return null;
    return now / before.close - 1;
  }

  double get totalValue => _valueAt(_current);
  double get gain => totalValue - data.initialCash;
  double get performance => gain / data.initialCash;
  double get realizedGains => _trades.fold(0, (s, t) => s + t.realizedGain);

  /// Valeur qu'aurait la même somme placée en S&P 500 dès le départ.
  double get buyAndHoldSpy {
    final s = _series['SPY']!;
    return data.initialCash /
        s.firstOnOrAfter(data.start)!.close *
        s.lastOnOrBefore(_current)!.close;
  }

  /// Pire chute de la valeur du portefeuille pendant la partie.
  Drawdown get drawdown => maxDrawdown([for (final p in _history) p.value]);

  /// Valeur de chaque actif s'il avait été acheté au début et gardé :
  /// révélé seulement dans le bilan. Les actifs pas encore cotés au début
  /// sont ignorés.
  Map<String, double> buyAndHoldPerformances() => {
    for (final a in data.assets)
      if (_series[a.symbol]!.firstOnOrAfter(data.start) case final first?
          when !first.date.isAfter(data.start.add(const Duration(days: 7))))
        a.symbol:
            _series[a.symbol]!.lastOnOrBefore(_current)!.close / first.close -
            1,
  };

  /// Plus-values pour l'impôt : les ventes réalisées, plus les positions
  /// encore ouvertes considérées comme vendues à la date courante.
  List<TaxableGain> taxableGains() => [
    for (final t in _trades)
      if (t.side == TradeSide.sell)
        (date: t.date, gain: t.realizedGain, holdingDays: t.holdingDays),
    for (final MapEntry(key: symbol, value: p) in _positions.entries)
      (
        date: _current,
        gain: p.units * priceOf(symbol)! - p.cost,
        holdingDays: _current.difference(p.openedAt).inDays,
      ),
  ];

  // --- Ordres --------------------------------------------------------------

  /// Achète pour [amount] dollars de [symbol] au cours de clôture du jour.
  void buy(String symbol, double amount) {
    _checkTradable(symbol);
    if (amount <= 0) throw const OrderException('Indique un montant positif.');
    // Tolérance d'un centime pour les arrondis (« tout investir »).
    if (amount > _cash + 0.01) {
      throw const OrderException('Pas assez de cash disponible.');
    }
    amount = amount.clamp(0, _cash);
    final price = priceOf(symbol)!;
    final units = amount / price;
    final position = _positions.putIfAbsent(
      symbol,
      () => Position(0, 0, _current),
    );
    position
      ..units += units
      ..cost += amount;
    _cash -= amount;
    _trades.add(
      Trade(
        date: _current,
        symbol: symbol,
        side: TradeSide.buy,
        units: units,
        price: price,
        amount: amount,
      ),
    );
    _replaceTodayInHistory();
  }

  /// Vend pour [amount] dollars de [symbol] (ou tout si [all]).
  void sell(String symbol, {double? amount, bool all = false}) {
    _checkTradable(symbol);
    final position = _positions[symbol];
    if (position == null) {
      throw const OrderException('Tu ne détiens pas cet actif.');
    }
    final price = priceOf(symbol)!;
    final held = position.units * price;
    if (!all) {
      if (amount == null || amount <= 0) {
        throw const OrderException('Indique un montant positif.');
      }
      if (amount > held + 0.01) {
        throw const OrderException('Tu ne détiens pas autant de cet actif.');
      }
    }
    // Vendre (presque) tout = tout : pas de miettes de 0,0000001 part.
    final sellAll = all || amount! >= held - 0.01;
    final units = sellAll ? position.units : amount / price;
    final proceeds = units * price;
    final costSold = position.averagePrice * units;

    _cash += proceeds;
    _trades.add(
      Trade(
        date: _current,
        symbol: symbol,
        side: TradeSide.sell,
        units: units,
        price: price,
        amount: proceeds,
        realizedGain: proceeds - costSold,
        holdingDays: _current.difference(position.openedAt).inDays,
      ),
    );
    if (sellAll) {
      _positions.remove(symbol);
    } else {
      position
        ..units -= units
        ..cost -= costSold;
    }
    _replaceTodayInHistory();
  }

  void _checkTradable(String symbol) {
    if (isFinished) throw const OrderException('La partie est terminée.');
    if (!isListed(symbol)) {
      throw const OrderException('Cet actif n’est pas encore coté.');
    }
    if (!isMarketOpen(symbol)) {
      throw const OrderException(
        'Marché fermé aujourd’hui pour cet actif (week-end ou jour férié).',
      );
    }
  }

  // --- Temps ---------------------------------------------------------------

  /// Avance dans le temps (jamais en arrière) et enregistre la valeur du
  /// portefeuille pour chaque jour traversé.
  void advance(TimeStep step) => advanceTo(addStep(_current, step));

  /// Avance jusqu'à [date] (bornée à la fin de la partie).
  void advanceTo(DateTime date) {
    final target = dateOnly(date);
    final end = target.isAfter(data.end) ? data.end : target;
    while (_current.isBefore(end)) {
      _current = DateTime.utc(_current.year, _current.month, _current.day + 1);
      _record();
    }
  }

  double _valueAt(DateTime date) {
    var value = _cash;
    for (final MapEntry(key: symbol, value: p) in _positions.entries) {
      value += p.units * _series[symbol]!.lastOnOrBefore(date)!.close;
    }
    return value;
  }

  void _record() => _history.add((date: _current, value: _valueAt(_current)));

  void _replaceTodayInHistory() {
    _history.removeLast();
    _record();
  }
}
