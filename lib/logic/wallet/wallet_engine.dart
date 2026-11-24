/// Calculs du portefeuille en temps réel : état, ordres, rattrapage des jours
/// écoulés (versements mensuels, stop-loss, prises de bénéfices) et valeur au
/// fil du temps.
library;

import '../price_series.dart';
import '../time_cursor.dart';
import '../../models/price_point.dart';
import '../../models/position_rule.dart';
import '../../models/wallet/wallet.dart';

/// Ordre refusé, avec un message pour l'utilisateur.
class WalletException implements Exception {
  final String message;
  const WalletException(this.message);

  @override
  String toString() => message;
}

/// Une ligne du portefeuille : parts détenues et somme payée pour elles.
class Holding {
  double units;
  double cost;
  Holding(this.units, this.cost);

  double get averagePrice => cost / units;
}

/// Ce que contient le portefeuille après une suite d'opérations.
class WalletState {
  double cash = 0;

  /// Total déposé : le gain se mesure par rapport à cette somme.
  double deposited = 0;
  final Map<String, Holding> holdings = {};

  /// Applique une opération (dans l'ordre chronologique).
  void apply(WalletTransaction t) {
    switch (t.type) {
      case WalletTxType.deposit:
        cash += t.amount;
        deposited += t.amount;
      case WalletTxType.buy:
        cash -= t.amount;
        final h = holdings.putIfAbsent(t.symbol!, () => Holding(0, 0));
        h
          ..units += t.units
          ..cost += t.amount;
      case WalletTxType.sell:
        cash += t.amount;
        final h = holdings[t.symbol!]!;
        if (t.units >= h.units - 1e-9) {
          holdings.remove(t.symbol); // vendu en entier
        } else {
          h
            ..cost -= h.averagePrice * t.units
            ..units -= t.units;
        }
    }
  }

  /// Valeur totale : le cash plus chaque position au cours de [priceOf].
  double valueWith(double Function(String symbol) priceOf) {
    var value = cash;
    for (final MapEntry(key: symbol, value: h) in holdings.entries) {
      value += h.units * priceOf(symbol);
    }
    return value;
  }
}

/// Rejoue toutes les opérations pour obtenir l'état actuel.
WalletState walletStateOf(Iterable<WalletTransaction> transactions) {
  final state = WalletState();
  for (final t in _sorted(transactions)) {
    state.apply(t);
  }
  return state;
}

/// Opérations triées par date ; à date égale, dans l'ordre d'enregistrement.
List<WalletTransaction> _sorted(Iterable<WalletTransaction> transactions) {
  final list = transactions.toList();
  final order = {for (final (i, t) in list.indexed) t: i};
  list.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : order[a]!.compareTo(order[b]!);
  });
  return list;
}

WalletTransaction depositOrder(double amount, DateTime date) {
  if (amount <= 0) throw const WalletException('Indique un montant positif.');
  return WalletTransaction(
    date: dateOnly(date),
    type: WalletTxType.deposit,
    source: WalletTxSource.manual,
    amount: amount,
  );
}

/// Achat de [amount] dollars de [symbol] au cours [price].
WalletTransaction buyOrder(
  WalletState state, {
  required String symbol,
  required double amount,
  required double price,
  required DateTime date,
  WalletTxSource source = WalletTxSource.manual,
}) {
  if (amount <= 0) throw const WalletException('Indique un montant positif.');
  // Tolérance d'un centime pour « tout investir ».
  if (amount > state.cash + 0.01) {
    throw const WalletException('Pas assez de cash : dépose de l’argent.');
  }
  final spent = amount > state.cash ? state.cash : amount;
  return WalletTransaction(
    date: dateOnly(date),
    type: WalletTxType.buy,
    source: source,
    symbol: symbol,
    units: spent / price,
    price: price,
    amount: spent,
  );
}

/// Vente de [amount] dollars de [symbol] (ou tout si [all]).
WalletTransaction sellOrder(
  WalletState state, {
  required String symbol,
  required double price,
  required DateTime date,
  double? amount,
  bool all = false,
  WalletTxSource source = WalletTxSource.manual,
}) {
  final h = state.holdings[symbol];
  if (h == null) throw const WalletException('Tu ne détiens pas cet actif.');
  final held = h.units * price;
  if (!all) {
    if (amount == null || amount <= 0) {
      throw const WalletException('Indique un montant positif.');
    }
    if (amount > held + 0.01) {
      throw const WalletException('Tu ne détiens pas autant de cet actif.');
    }
  }
  // Vendre (presque) tout = tout : pas de miettes de parts.
  final units = all || amount! >= held - 0.01 ? h.units : amount / price;
  return WalletTransaction(
    date: dateOnly(date),
    type: WalletTxType.sell,
    source: source,
    symbol: symbol,
    units: units,
    price: price,
    amount: units * price,
  );
}

/// Prochaine date prévue d'un versement mensuel : le [DcaPlan.dayOfMonth]
/// du mois qui suit le dernier exécuté (ou à partir de la création).
DateTime nextTarget(DcaPlan plan) {
  final last = plan.lastTarget;
  if (last != null) return _onDay(addMonths(last, 1), plan.dayOfMonth);
  final created = dateOnly(plan.createdAt);
  final thisMonth = _onDay(created, plan.dayOfMonth);
  // Créé après le jour prévu de ce mois : premier versement le mois suivant.
  return thisMonth.isBefore(created)
      ? _onDay(addMonths(created, 1), plan.dayOfMonth)
      : thisMonth;
}

/// [date] ramenée au jour [day] de son mois (sans déborder du mois).
DateTime _onDay(DateTime date, int day) {
  final lastDay = DateTime.utc(date.year, date.month + 1, 0).day;
  return DateTime.utc(date.year, date.month, day > lastDay ? lastDay : day);
}

/// Ce que le rattrapage a produit.
typedef CatchUpResult = ({
  List<WalletTransaction> transactions,
  List<DcaPlan> plans,
  Set<String> triggeredRules,
});

/// Parcourt chaque jour de cotation de [after] (exclu) à [until] (inclus)
/// et exécute, au cours de clôture de ce jour :
/// 1. les versements mensuels prévus (dépôt puis achat) ;
/// 2. les stop-loss et prises de bénéfices (vente de toute la position).
CatchUpResult catchUp({
  required List<WalletTransaction> transactions,
  required List<DcaPlan> plans,
  required Map<String, PositionRule> rules,
  required Map<String, PriceSeries> prices,
  required DateTime after,
  required DateTime until,
}) {
  final from = dateOnly(after);
  final to = dateOnly(until);
  final existing = _sorted(transactions);
  final state = WalletState();
  var next = 0; // prochaine opération existante à appliquer

  final created = <WalletTransaction>[];
  final updatedPlans = [...plans];
  final triggered = <String>{};

  // Jours de cotation d'au moins un actif concerné.
  final days = <DateTime>{
    for (final s in prices.values)
      for (final p in s.points)
        if (p.date.isAfter(from) && !p.date.isAfter(to)) p.date,
  }.toList()..sort();

  for (final day in days) {
    // Les opérations déjà faites ce jour-là (ou avant) comptent d'abord.
    while (next < existing.length && !existing[next].date.isAfter(day)) {
      state.apply(existing[next++]);
    }

    for (final (i, plan) in updatedPlans.indexed) {
      final series = prices[plan.symbol];
      final close = series?.points.where((p) => p.date == day).firstOrNull;
      if (close == null) continue; // marché fermé pour cet actif
      final target = nextTarget(plan);
      // Exécuté au premier jour de cotation à partir de la date prévue.
      if (target.isAfter(day)) continue;
      final money = WalletTransaction(
        date: day,
        type: WalletTxType.deposit,
        source: WalletTxSource.dca,
        amount: plan.amount,
      );
      state.apply(money);
      final buy = buyOrder(
        state,
        symbol: plan.symbol,
        amount: plan.amount,
        price: close.close,
        date: day,
        source: WalletTxSource.dca,
      );
      state.apply(buy);
      created.addAll([money, buy]);
      updatedPlans[i] = plan.executedOn(target);
    }

    for (final rule in rules.values) {
      if (triggered.contains(rule.symbol)) continue;
      final h = state.holdings[rule.symbol];
      final close = prices[rule.symbol]?.points
          .where((p) => p.date == day)
          .firstOrNull;
      if (h == null || close == null) continue;
      final source = switch (rule.triggerAt(
        averagePrice: h.averagePrice,
        close: close.close,
      )) {
        RuleTrigger.stopLoss => WalletTxSource.stopLoss,
        RuleTrigger.takeProfit => WalletTxSource.takeProfit,
        null => null,
      };
      if (source == null) continue;
      final sell = sellOrder(
        state,
        symbol: rule.symbol,
        price: close.close,
        date: day,
        all: true,
        source: source,
      );
      state.apply(sell);
      created.add(sell);
      triggered.add(rule.symbol); // la règle a servi : on la retire
    }
  }

  return (
    transactions: created,
    plans: updatedPlans,
    triggeredRules: triggered,
  );
}

/// Un point de la courbe : valeur totale et somme déposée à cette date.
typedef WalletPoint = ({DateTime date, double value, double deposited});

/// Valeur du portefeuille à chaque jour de cotation de [from] à [to].
List<WalletPoint> walletHistory({
  required List<WalletTransaction> transactions,
  required Map<String, PriceSeries> prices,
  required DateTime from,
  required DateTime to,
}) {
  final existing = _sorted(transactions);
  final state = WalletState();
  var next = 0;
  final days = <DateTime>{
    for (final s in prices.values)
      for (final p in s.points)
        if (!p.date.isBefore(dateOnly(from)) && !p.date.isAfter(dateOnly(to)))
          p.date,
  }.toList()..sort();

  final points = <WalletPoint>[];
  for (final day in days) {
    while (next < existing.length && !existing[next].date.isAfter(day)) {
      state.apply(existing[next++]);
    }
    points.add((
      date: day,
      value: state.valueWith((s) => prices[s]?.lastOnOrBefore(day)?.close ?? 0),
      deposited: state.deposited,
    ));
  }
  return points;
}
