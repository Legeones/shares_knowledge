import 'package:flutter/foundation.dart';

import '../../data/api/api_exceptions.dart';
import '../../data/repositories/price_repository.dart';
import '../../logic/price_series.dart';
import '../../models/asset.dart';
import '../../models/price_point.dart';
import '../../data/wallet/wallet_dao.dart';
import '../../logic/wallet/wallet_engine.dart';
import '../../models/position_rule.dart';
import '../../models/wallet/wallet.dart';

/// Le portefeuille en temps réel : il grandit au fil des vrais jours.
class WalletProvider extends ChangeNotifier {
  final WalletDao _dao;
  final PriceRepository _prices;
  final DateTime Function() _now;

  WalletProvider(this._dao, this._prices, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  WalletData? _data;
  final Map<String, PriceSeries> _series = {};
  final Map<String, String> _names = {};

  bool _loading = false;
  bool _loaded = false;

  /// Problème de cours (réseau, quota…) : le portefeuille reste affiché.
  String? _warning;

  bool get loading => _loading;
  bool get loaded => _loaded;
  bool get exists => _data != null;
  String? get warning => _warning;

  DateTime get _today => dateOnly(_now());
  DateTime get createdAt => _data!.createdAt;
  List<WalletTransaction> get transactions => _data!.transactions;
  List<DcaPlan> get plans => _data!.plans;
  Map<String, PositionRule> get rules => _data!.rules;

  WalletState get state => walletStateOf(transactions);

  /// Nom lisible d'un actif (« S&P 500 (ETF SPDR) »), sinon son symbole.
  String nameOf(String symbol) => _names[symbol] ?? symbol;

  /// Dernier cours de clôture connu ; null si pas encore téléchargé.
  double? priceOf(String symbol) => _series[symbol]?.points.lastOrNull?.close;

  /// Cours connus de [symbol], depuis peu avant la création du portefeuille.
  List<PricePoint> pricesOf(String symbol) =>
      _series[symbol]?.points ?? const [];

  /// Date des cours les plus récents.
  DateTime? get pricesDate => [
    for (final s in _series.values)
      if (s.points.isNotEmpty) s.points.last.date,
  ].fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

  /// Valeur totale aux derniers cours (le prix moyen d'achat à défaut).
  double get totalValue {
    final s = state;
    return s.valueWith(
      (symbol) => priceOf(symbol) ?? s.holdings[symbol]!.averagePrice,
    );
  }

  List<WalletPoint> get history => walletHistory(
    transactions: transactions,
    prices: _series,
    from: createdAt,
    to: _today,
  );

  /// Lit le portefeuille enregistré, puis le met à jour.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _data = await _dao.load();
    for (final p in _data?.plans ?? const <DcaPlan>[]) {
      _names[p.symbol] = p.name;
    }
    if (_data != null) await _update();
    _loading = false;
    _loaded = true;
    notifyListeners();
  }

  /// Crée le portefeuille aujourd'hui, avec [capital] de départ (0 permis).
  Future<void> create(double capital) async {
    final today = _today;
    await _dao.create(today, today.subtract(const Duration(days: 1)));
    if (capital > 0) {
      await _dao.addTransactions([
        WalletTransaction(
          date: today,
          type: WalletTxType.deposit,
          source: WalletTxSource.initial,
          amount: capital,
        ),
      ]);
    }
    await load();
  }

  Future<void> reset() async {
    await _dao.reset();
    _series.clear();
    _warning = null;
    await load();
  }

  /// Chaque ordre renvoie le message d'erreur, ou null s'il est exécuté.
  Future<String?> deposit(double amount) =>
      _run(() async => [depositOrder(amount, _today)]);

  /// [name] : nom affiché de l'actif, retenu pour la liste des positions.
  Future<String?> buy(String symbol, double amount, {String? name}) =>
      _run(() async {
        if (name != null) _names[symbol] = name;
        final price = await _latestPrice(symbol);
        return [
          buyOrder(
            state,
            symbol: symbol,
            amount: amount,
            price: price,
            date: _today,
          ),
        ];
      });

  Future<String?> sell(String symbol, {double? amount, bool all = false}) =>
      _run(() async {
        final price = await _latestPrice(symbol);
        return [
          sellOrder(
            state,
            symbol: symbol,
            price: price,
            date: _today,
            amount: amount,
            all: all,
          ),
        ];
      });

  Future<String?> _run(Future<List<WalletTransaction>> Function() order) async {
    try {
      final transactions = await order();
      await _dao.addTransactions(transactions);
      await _reload();
      return null;
    } on WalletException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> addPlan(Asset asset, double amount, int dayOfMonth) async {
    _names[asset.symbol] = asset.name;
    await _dao.savePlan(
      DcaPlan(
        symbol: asset.symbol,
        name: asset.name,
        amount: amount,
        dayOfMonth: dayOfMonth,
        createdAt: _today,
      ),
    );
    await _reload();
  }

  Future<void> removePlan(DcaPlan plan) async {
    await _dao.deletePlan(plan.id!);
    await _reload();
  }

  Future<void> setRule(PositionRule rule) async {
    await _dao.saveRule(rule);
    await _reload();
  }

  Future<void> _reload() async {
    _data = await _dao.load();
    notifyListeners();
  }

  /// Télécharge les cours manquants puis rattrape les jours écoulés.
  Future<void> _update() async {
    final data = _data!;
    final symbols = {
      for (final t in data.transactions)
        if (t.symbol != null) t.symbol!,
      for (final p in data.plans) p.symbol,
      ...data.rules.keys,
    };
    var complete = true;
    for (final symbol in symbols) {
      complete &= await _fetch(symbol);
    }
    // Un actif sans cours à jour : on attend, pour ne sauter aucun jour.
    if (!complete || symbols.isEmpty) return;

    final until = [for (final s in symbols) _series[s]!.points.last.date]
        .reduce((a, b) => a.isBefore(b) ? a : b);
    if (!until.isAfter(data.processedUntil)) return;

    final result = catchUp(
      transactions: data.transactions,
      plans: data.plans,
      rules: data.rules,
      prices: _series,
      after: data.processedUntil,
      until: until,
    );
    await _dao.addTransactions(result.transactions);
    for (final plan in result.plans) {
      await _dao.savePlan(plan);
    }
    for (final symbol in result.triggeredRules) {
      await _dao.deleteRule(symbol);
    }
    await _dao.setProcessedUntil(until);
    _data = await _dao.load();
  }

  /// Cours de [symbol] depuis un peu avant la création ; faux si échec.
  Future<bool> _fetch(String symbol) async {
    try {
      final data = await _prices.getDailySeries(
        symbol,
        start: createdAt.subtract(const Duration(days: 10)),
        end: _today,
      );
      _series[symbol] = data.series;
      if (data.isFallback) {
        _warning = data.fallbackReason?.message;
        return false;
      }
      return true;
    } on ApiException catch (e) {
      _warning = e.message;
      return false;
    }
  }

  Future<double> _latestPrice(String symbol) async {
    if (priceOf(symbol) == null) await _fetch(symbol);
    final price = priceOf(symbol);
    if (price == null) {
      throw WalletException(_warning ?? 'Cours indisponible pour $symbol.');
    }
    return price;
  }
}
