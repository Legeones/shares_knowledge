import '../price_point.dart';

/// Nature d'une opération du portefeuille.
enum WalletTxType { deposit, buy, sell }

/// Qui a déclenché l'opération (affiché dans l'historique).
enum WalletTxSource {
  initial('Capital de départ'),
  manual('Manuel'),
  dca('Versement mensuel'),
  stopLoss('Stop-loss'),
  takeProfit('Prise de bénéfices');

  final String label;
  const WalletTxSource(this.label);
}

/// Une opération : dépôt d'argent, achat ou vente.
class WalletTransaction {
  final int? id; // attribué par SQLite
  final DateTime date;
  final WalletTxType type;
  final WalletTxSource source;
  final String? symbol; // null pour un dépôt
  final double units;
  final double price;

  /// Montant en dollars (dépôt, coût de l'achat, produit de la vente).
  final double amount;

  const WalletTransaction({
    this.id,
    required this.date,
    required this.type,
    required this.source,
    this.symbol,
    this.units = 0,
    this.price = 0,
    required this.amount,
  });

  Map<String, Object?> toRow() => {
    'date': _day(date),
    'type': type.name,
    'source': source.name,
    'symbol': symbol,
    'units': units,
    'price': price,
    'amount': amount,
  };

  factory WalletTransaction.fromRow(Map<String, Object?> row) =>
      WalletTransaction(
        id: row['id'] as int?,
        date: dateOnly(DateTime.parse(row['date'] as String)),
        type: WalletTxType.values.byName(row['type'] as String),
        source: WalletTxSource.values.byName(row['source'] as String),
        symbol: row['symbol'] as String?,
        units: (row['units'] as num).toDouble(),
        price: (row['price'] as num).toDouble(),
        amount: (row['amount'] as num).toDouble(),
      );
}

/// Versement mensuel (DCA) : [amount] dollars déposés puis investis dans
/// [symbol] chaque mois, le [dayOfMonth] (ou au jour de bourse suivant).
class DcaPlan {
  final int? id;
  final String symbol;
  final String name;
  final double amount;
  final int dayOfMonth;
  final DateTime createdAt;

  /// Dernière date prévue déjà exécutée : la suivante est un mois après.
  final DateTime? lastTarget;

  const DcaPlan({
    this.id,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    required this.createdAt,
    this.lastTarget,
  });

  DcaPlan executedOn(DateTime target) => DcaPlan(
    id: id,
    symbol: symbol,
    name: name,
    amount: amount,
    dayOfMonth: dayOfMonth,
    createdAt: createdAt,
    lastTarget: target,
  );

  Map<String, Object?> toRow() => {
    'symbol': symbol,
    'name': name,
    'amount': amount,
    'day_of_month': dayOfMonth,
    'created_at': _day(createdAt),
    'last_target': lastTarget == null ? null : _day(lastTarget!),
  };

  factory DcaPlan.fromRow(Map<String, Object?> row) => DcaPlan(
    id: row['id'] as int?,
    symbol: row['symbol'] as String,
    name: row['name'] as String,
    amount: (row['amount'] as num).toDouble(),
    dayOfMonth: row['day_of_month'] as int,
    createdAt: dateOnly(DateTime.parse(row['created_at'] as String)),
    lastTarget: row['last_target'] == null
        ? null
        : dateOnly(DateTime.parse(row['last_target'] as String)),
  );
}

String _day(DateTime d) => dateOnly(d).toIso8601String().substring(0, 10);
