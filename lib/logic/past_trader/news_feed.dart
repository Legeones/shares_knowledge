import '../../models/past_trader/news.dart';
import '../../models/price_point.dart';

/// Le fil d'actualités de la partie : ne révèle jamais une nouvelle datée
/// après la date courante.
class NewsFeed {
  /// Du plus ancien au plus récent.
  final List<NewsItem> items;

  NewsFeed(List<NewsItem> items)
    : items = [...items]..sort((a, b) => a.date.compareTo(b.date));

  /// Toutes les actualités connues à [date], la plus récente en premier.
  List<NewsItem> until(DateTime date) {
    final day = dateOnly(date);
    return [
      for (final n in items.reversed)
        if (!n.date.isAfter(day)) n,
    ];
  }

  /// Celles qui « tombent » entre [after] (exclu) et [upTo] (inclus) :
  /// les nouvelles révélées par une avancée du temps.
  List<NewsItem> between(DateTime after, DateTime upTo) {
    final from = dateOnly(after);
    final to = dateOnly(upTo);
    return [
      for (final n in items)
        if (n.date.isAfter(from) && !n.date.isAfter(to)) n,
    ];
  }

  /// Actualités d'un actif connues à [date], la plus récente en premier.
  List<NewsItem> forSymbol(String symbol, DateTime date) =>
      until(date).where((n) => n.symbols.contains(symbol)).toList();
}
