import '../../logic/price_series.dart';
import '../../models/price_point.dart';
import '../api/api_exceptions.dart';
import '../api/twelve_data_api.dart';
import '../local/price_cache_dao.dart';

/// Ce que reçoit l'écran : les cours, et d'où ils viennent.
class PriceData {
  final PriceSeries series;

  /// Date du dernier téléchargement.
  final DateTime updatedAt;

  /// Vrai si le réseau a échoué et qu'on affiche ce qu'on avait en cache.
  /// [fallbackReason] explique pourquoi (pas de réseau, quota…).
  final bool isFallback;
  final ApiException? fallbackReason;

  const PriceData({
    required this.series,
    required this.updatedAt,
    this.isFallback = false,
    this.fallbackReason,
  });
}

/// Cours depuis le cache ou l'API. Un cours passé ne change pas : seuls
/// les jours manquants sont téléchargés.
class PriceRepository {
  final TwelveDataApi _api;
  final PriceCacheDao _dao;
  final DateTime Function() _now;

  PriceRepository(this._api, this._dao, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<PriceData> getDailySeries(
    String symbol, {
    required DateTime start,
    required DateTime end,
  }) async {
    final from = dateOnly(start);

    final yesterday = dateOnly(_now()).subtract(const Duration(days: 1));
    final to = end.isAfter(yesterday) ? yesterday : dateOnly(end);

    if (from.isAfter(to)) throw NoDataException(symbol);

    final coverage = await _dao.getCoverage(symbol);

    // Cas 1 : tout est déjà en cache : aucune requête réseau.
    if (coverage != null && coverage.covers(from, to)) {
      return _readCache(symbol, from, to, coverage.updatedAt);
    }

    // Cas 2 : il manque des jours : on ne télécharge que ceux-là.
    try {
      final newCoverage = await _downloadMissing(symbol, from, to, coverage);
      return await _readCache(symbol, from, to, newCoverage.updatedAt);
    } on NetworkException catch (e) {
      return _fallbackOrThrow(symbol, from, to, coverage, e);
    } on QuotaExceededException catch (e) {
      return _fallbackOrThrow(symbol, from, to, coverage, e);
    }
    // Les autres erreurs (symbole inconnu, clé invalide...) ne se règlent pas
    // avec le cache : elles remontent telles quelles jusqu'à l'écran.
  }

  /// Télécharge ce qui manque avant et/ou après la période déjà en cache,
  /// puis enregistre. La période couverte reste toujours d'un seul tenant.
  Future<Coverage> _downloadMissing(
    String symbol,
    DateTime from,
    DateTime to,
    Coverage? coverage,
  ) async {
    final points = <PricePoint>[];
    var newFrom = from;
    var newTo = to;

    if (coverage == null) {
      // Rien en cache : on télécharge toute la période demandée.
      points.addAll(await _api.fetchDailySeries(symbol, start: from, end: to));
    } else {
      newFrom = from.isBefore(coverage.from) ? from : coverage.from;
      newTo = to.isAfter(coverage.to) ? to : coverage.to;

      if (from.isBefore(coverage.from)) {
        final before = coverage.from.subtract(const Duration(days: 1));
        points.addAll(await _fetchGap(symbol, from, before));
      }
      if (to.isAfter(coverage.to)) {
        final after = coverage.to.add(const Duration(days: 1));
        points.addAll(await _fetchGap(symbol, after, to));
      }
    }

    // L'API renvoie au plus 5000 cours par appel (les plus récents).
    // Si on atteint cette limite, le début de la période n'a peut-être pas été
    // reçu : on ne déclare couvert qu'à partir du plus ancien cours reçu.
    if (points.length >= TwelveDataApi.maxOutputSize) {
      final oldest = points
          .map((p) => p.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (oldest.isAfter(newFrom)) newFrom = oldest;
    }

    final newCoverage = Coverage(from: newFrom, to: newTo, updatedAt: _now());
    await _dao.save(symbol, points, newCoverage);
    return newCoverage;
  }

  /// Comme fetchDailySeries, mais une période sans aucun cours (un week-end,
  /// une date avant l'introduction en bourse) n'est pas une erreur ici :
  /// on sait simplement qu'il n'y a rien à cet endroit.
  Future<List<PricePoint>> _fetchGap(
    String symbol,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _api.fetchDailySeries(symbol, start: start, end: end);
    } on NoDataException {
      return [];
    }
  }

  /// Réseau indisponible : on renvoie le cache s'il contient quelque chose
  /// sur la période, en le signalant. Sinon, l'erreur remonte à l'écran.
  Future<PriceData> _fallbackOrThrow(
    String symbol,
    DateTime from,
    DateTime to,
    Coverage? coverage,
    ApiException error,
  ) async {
    if (coverage == null) throw error;
    final cached = await _dao.getPoints(symbol, from, to);
    if (cached.isEmpty) throw error;
    return PriceData(
      series: PriceSeries(cached),
      updatedAt: coverage.updatedAt,
      isFallback: true,
      fallbackReason: error,
    );
  }

  Future<PriceData> _readCache(
    String symbol,
    DateTime from,
    DateTime to,
    DateTime updatedAt,
  ) async {
    final points = await _dao.getPoints(symbol, from, to);
    if (points.isEmpty) throw NoDataException(symbol);
    return PriceData(series: PriceSeries(points), updatedAt: updatedAt);
  }
}
