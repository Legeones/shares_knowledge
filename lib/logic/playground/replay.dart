import '../../models/price_point.dart';
import '../../models/simulation.dart';
import '../price_series.dart';
import '../returns.dart';
import '../time_cursor.dart';

/// Rejeu d'une simulation dans le temps : « où en était mon investissement à
/// telle date ? ».
class Replay {
  final SimulationResult result;
  final TimeCursor _cursor;

  Replay(this.result)
    : _cursor = TimeCursor(
        series: PriceSeries([
          for (final p in result.history)
            PricePoint(date: p.date, close: p.price),
        ]),
        start: result.actualStart,
        end: result.actualEnd,
      );

  DateTime get currentDate => _cursor.current;
  bool get isAtStart => _cursor.current == _cursor.start;
  bool get isAtEnd => _cursor.isAtEnd;

  /// Faux un week-end ou un jour férié : la valeur affichée est celle du
  /// dernier jour de bourse.
  bool get isMarketOpen => _cursor.isMarketOpen;

  /// Nombre de jours de l'historique déjà « vécus » (date <= date courante).
  int get visibleCount {
    var count = 0;
    for (final p in result.history) {
      if (p.date.isAfter(_cursor.current)) break; // l'historique est trié
      count++;
    }
    return count;
  }

  /// Dernier point connu à la date courante.
  ValuePoint get currentPoint => result.history[visibleCount - 1];

  double get currentValue => currentPoint.value;

  /// Somme versée jusqu'à la date courante (elle grandit en DCA).
  double get currentInvested => currentPoint.invested;

  double get currentGain =>
      gain(invested: currentInvested, finalValue: currentValue);

  double get currentPerformance =>
      performance(invested: currentInvested, finalValue: currentValue);

  void advance(TimeStep step) => _cursor.advance(step);
  void reset() => _cursor.reset();
  void jumpToEnd() => _cursor.jumpToEnd();
  void jumpTo(DateTime date) => _cursor.jumpTo(date);
}
