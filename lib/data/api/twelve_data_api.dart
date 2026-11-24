import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/price_point.dart';
import 'api_exceptions.dart';

/// Client de l'API Twelve Data (https://twelvedata.com/docs).
class TwelveDataApi {
  static const _host = 'api.twelvedata.com';
  static const _timeout = Duration(seconds: 15);

  /// Nombre maximum de cours renvoyés par un appel.
  static const maxOutputSize = 5000;

  final String apiKey;

  /// Le client HTTP et l'horloge sont passés en paramètres pour pouvoir les
  /// remplacer dans les tests (faux serveur, fausse date du jour).
  final http.Client _client;
  final DateTime Function() _now;

  TwelveDataApi({
    required this.apiKey,
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  /// Cours de clôture quotidiens de [symbol] entre [start] et [end] inclus.
  Future<List<PricePoint>> fetchDailySeries(
    String symbol, {
    required DateTime start,
    required DateTime end,
  }) async {
    if (apiKey.isEmpty) throw const InvalidApiKeyException();

    final uri = Uri.https(_host, '/time_series', {
      'symbol': symbol,
      'interval': '1day',
      'start_date': _formatDate(start),
      'end_date': _formatDate(end),
      'outputsize': '$maxOutputSize',
      'apikey': apiKey,
    });

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      // Pas de réseau, nom de domaine introuvable, connexion coupée...
      throw const NetworkException();
    }

    if (response.statusCode == 429) throw const QuotaExceededException();
    if (response.statusCode != 200) throw const BadResponseException();

    final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw const BadResponseException(); // le texte reçu n'est pas du JSON
    }
    if (json is! Map<String, dynamic>) throw const BadResponseException();

    // Twelve Data peut renvoyer une erreur avec un code HTTP 200.
    if (json['status'] == 'error') {
      throw switch (json['code']) {
        429 => const QuotaExceededException(),
        401 || 403 => const InvalidApiKeyException(),
        400 || 404 => NoDataException(symbol),
        _ => const BadResponseException(),
      };
    }

    return _parseValues(json, symbol);
  }

  /// Convertit la liste "values" du JSON en objets PricePoint.
  List<PricePoint> _parseValues(Map<String, dynamic> json, String symbol) {
    final values = json['values'];
    if (values is! List) throw const BadResponseException();
    if (values.isEmpty) throw NoDataException(symbol);

    final List<PricePoint> points;
    try {
      points = [for (final v in values) PricePoint.fromJson(v)];
    } on FormatException {
      throw const BadResponseException();
    }

    // Pendant la séance, le cours « du jour » n'est pas encore définitif :
    // écarté pour ne pas le mémoriser comme un cours de clôture.
    final today = dateOnly(_now());
    return points.where((p) => p.date.isBefore(today)).toList();
  }

  /// 2024-03-05 donne "2024-03-05" (format attendu par l'API).
  static String _formatDate(DateTime d) =>
      dateOnly(d).toIso8601String().substring(0, 10);
}
