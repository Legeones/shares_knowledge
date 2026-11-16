import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shares_knowledge/data/api/api_exceptions.dart';
import 'package:shares_knowledge/data/api/twelve_data_api.dart';

/// Réponse réelle de Twelve Data (raccourcie), copiée depuis un vrai appel.
const okBody = '''
{"meta":{"symbol":"AAPL","interval":"1day","currency":"USD"},
 "values":[
   {"datetime":"2024-01-05","open":"181.99","high":"182.76","low":"180.17","close":"181.17999","volume":"62303300"},
   {"datetime":"2024-01-04","open":"182.14999","high":"183.08","low":"180.88","close":"181.91000","volume":"71983600"}
 ],
 "status":"ok"}
''';

/// Crée l'API avec un **faux serveur** : au lieu d'aller sur internet,
/// chaque requête est passée à [handler], qui décide de la réponse.
TwelveDataApi apiWith(
  Future<http.Response> Function(http.Request request) handler, {
  String key = 'test-key',
  DateTime? today,
}) {
  return TwelveDataApi(
    apiKey: key,
    client: MockClient(handler),
    now: () => today ?? DateTime.utc(2024, 6, 1),
  );
}

Future<void> fetch(TwelveDataApi api) => api.fetchDailySeries(
  'AAPL',
  start: DateTime.utc(2024, 1, 1),
  end: DateTime.utc(2024, 1, 5),
);

void main() {
  test('construit la bonne URL', () async {
    late Uri called;
    final api = apiWith((request) async {
      called = request.url;
      return http.Response(okBody, 200);
    });

    await fetch(api);

    expect(called.host, 'api.twelvedata.com');
    expect(called.path, '/time_series');
    expect(called.queryParameters, {
      'symbol': 'AAPL',
      'interval': '1day',
      'start_date': '2024-01-01',
      'end_date': '2024-01-05',
      'outputsize': '5000',
      'apikey': 'test-key',
    });
  });

  test('convertit le JSON en PricePoint (texte → nombre)', () async {
    final api = apiWith((_) async => http.Response(okBody, 200));

    final points = await api.fetchDailySeries(
      'AAPL',
      start: DateTime.utc(2024, 1, 1),
      end: DateTime.utc(2024, 1, 5),
    );

    expect(points, hasLength(2));
    expect(points[0].date, DateTime.utc(2024, 1, 5));
    expect(points[0].close, closeTo(181.18, 0.001));
    expect(points[1].close, closeTo(181.91, 0.001));
  });

  test('écarte le cours du jour, encore incomplet', () async {
    final api = apiWith(
      (_) async => http.Response(okBody, 200),
      today: DateTime.utc(2024, 1, 5, 16, 0), // pendant la séance du 5
    );

    final points = await api.fetchDailySeries(
      'AAPL',
      start: DateTime.utc(2024, 1, 1),
      end: DateTime.utc(2024, 1, 5),
    );

    expect(points, hasLength(1));
    expect(points.single.date, DateTime.utc(2024, 1, 4));
  });

  group('erreurs traduites en exceptions claires', () {
    // Twelve Data renvoie ses erreurs avec un code HTTP 200 et le vrai code
    // dans le corps de la réponse.
    http.Response apiError(int code) => http.Response(
      jsonEncode({'code': code, 'message': '...', 'status': 'error'}),
      200,
    );

    test('quota dépassé (code 429 dans le corps)', () {
      final api = apiWith((_) async => apiError(429));
      expect(fetch(api), throwsA(isA<QuotaExceededException>()));
    });

    test('quota dépassé (vrai code HTTP 429)', () {
      final api = apiWith((_) async => http.Response('', 429));
      expect(fetch(api), throwsA(isA<QuotaExceededException>()));
    });

    test('clé refusée', () {
      final api = apiWith((_) async => apiError(401));
      expect(fetch(api), throwsA(isA<InvalidApiKeyException>()));
    });

    test('clé absente : aucune requête envoyée', () {
      var called = false;
      final api = apiWith((_) async {
        called = true;
        return http.Response(okBody, 200);
      }, key: '');
      expect(fetch(api), throwsA(isA<InvalidApiKeyException>()));
      expect(called, isFalse);
    });

    test('symbole inconnu', () {
      final api = apiWith((_) async => apiError(404));
      expect(fetch(api), throwsA(isA<NoDataException>()));
    });

    test('aucun cours dans la période', () {
      final api = apiWith(
        (_) async => http.Response('{"values":[],"status":"ok"}', 200),
      );
      expect(fetch(api), throwsA(isA<NoDataException>()));
    });

    test('pas de réseau', () {
      final api = apiWith((_) async => throw http.ClientException('offline'));
      expect(fetch(api), throwsA(isA<NetworkException>()));
    });

    test('réponse qui n’est pas du JSON', () {
      final api = apiWith(
        (_) async => http.Response('<html>panne</html>', 200),
      );
      expect(fetch(api), throwsA(isA<BadResponseException>()));
    });

    test('JSON valide mais prix illisible', () {
      final api = apiWith(
        (_) async => http.Response(
          '{"values":[{"datetime":"2024-01-05","close":"abc"}],"status":"ok"}',
          200,
        ),
      );
      expect(fetch(api), throwsA(isA<BadResponseException>()));
    });

    test('erreur serveur (500)', () {
      final api = apiWith((_) async => http.Response('', 500));
      expect(fetch(api), throwsA(isA<BadResponseException>()));
    });
  });
}
