import '../price_point.dart';

/// Une décision de la partie : avancer, acheter ou vendre. Rejouées dans
/// l'ordre, elles reconstruisent exactement la même partie (les cours sont
/// fixes, rien n'est tiré au hasard).
typedef TraderAction = Map<String, Object?>;

/// Partie Past Trader quittée avant la fin, à reprendre plus tard.
class TraderSave {
  final String gameId;
  final DateTime savedAt;

  /// Résumé affiché sur la carte « Reprendre », sans rejouer la partie.
  final DateTime current;
  final double totalValue;

  /// Actualités déjà lues (pour le badge « non lues »).
  final int readCount;
  final List<TraderAction> actions;

  const TraderSave({
    required this.gameId,
    required this.savedAt,
    required this.current,
    required this.totalValue,
    required this.readCount,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'savedAt': savedAt.toIso8601String(),
    'current': current.toIso8601String(),
    'totalValue': totalValue,
    'readCount': readCount,
    'actions': actions,
  };

  factory TraderSave.fromJson(Map<String, dynamic> json) => TraderSave(
    gameId: json['gameId'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    current: dateOnly(DateTime.parse(json['current'] as String)),
    totalValue: (json['totalValue'] as num).toDouble(),
    readCount: json['readCount'] as int,
    actions: [
      for (final a in json['actions'] as List)
        Map<String, Object?>.from(a as Map),
    ],
  );
}
