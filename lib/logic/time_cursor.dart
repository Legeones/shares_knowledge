import '../models/price_point.dart';
import 'price_series.dart';

/// Les sauts de temps proposés par les boutons.
enum TimeStep { day, week, month }

/// La « tête de lecture » qui avance dans un historique de cours.
///
/// Utilisée par le rejeu du Playground, Perfect Foresight et Past Trader.
/// Elle ne connaît que la date courante ; le prix est retrouvé dans la série.
class TimeCursor {
  final PriceSeries series;
  final DateTime start;
  final DateTime end;
  DateTime _current;

  TimeCursor({
    required this.series,
    required DateTime start,
    required DateTime end,
  }) : start = dateOnly(start),
       end = dateOnly(end),
       _current = dateOnly(start);

  DateTime get current => _current;
  bool get isAtEnd => !_current.isBefore(end);

  /// Dernier cours connu à la date courante (null avant la première cotation).
  PricePoint? get currentPrice => series.lastOnOrBefore(_current);

  /// Faux un week-end ou un jour férié : l'écran affiche alors
  /// « marché fermé, dernier cours connu ».
  bool get isMarketOpen => series.isMarketDay(_current);

  /// Avance d'un pas, sans jamais dépasser la date de fin.
  void advance(TimeStep step) {
    final next = addStep(_current, step);
    _current = next.isAfter(end) ? end : next;
  }

  /// Retour au début (autorisé dans Playground et Foresight, pas Past Trader).
  void reset() => _current = start;

  /// Saut direct à la fin (voir le bilan sans tout rejouer).
  void jumpToEnd() => _current = end;

  /// Place la tête de lecture à une date précise, bornée à la période.
  void jumpTo(DateTime date) {
    final day = dateOnly(date);
    _current = day.isBefore(start) ? start : (day.isAfter(end) ? end : day);
  }
}

/// Ajoute un pas de temps à une date.
DateTime addStep(DateTime date, TimeStep step) {
  switch (step) {
    case TimeStep.day:
      return DateTime.utc(date.year, date.month, date.day + 1);
    case TimeStep.week:
      return DateTime.utc(date.year, date.month, date.day + 7);
    case TimeStep.month:
      final lastDayOfNextMonth = DateTime.utc(date.year, date.month + 2, 0).day;
      final day = date.day > lastDayOfNextMonth ? lastDayOfNextMonth : date.day;
      return DateTime.utc(date.year, date.month + 1, day);
  }
}

/// Durée de la lecture automatique : 10 s + 1 s par 60 jours, entre 15 et 60 s.
Duration autoPlayDuration(int periodDays) {
  final seconds = (10 + periodDays / 60).clamp(15, 60);
  return Duration(milliseconds: (seconds * 1000).round());
}

/// [date] décalée de [months] mois, en restant dans le mois visé.
DateTime addMonths(DateTime date, int months) {
  final lastDay = DateTime.utc(date.year, date.month + months + 1, 0).day;
  return DateTime.utc(
    date.year,
    date.month + months,
    date.day > lastDay ? lastDay : date.day,
  );
}
