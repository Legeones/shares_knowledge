import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shares_knowledge/data/api/twelve_data_api.dart';
import 'package:shares_knowledge/data/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Un faux marché pour les tests : il répond comme Twelve Data, avec un cours
/// pour chaque jour de semaine (lundi → vendredi), égal au numéro du jour.
/// Il note chaque requête reçue pour vérifier ce que le cache évite.
class FakeMarket {
  final requests = <Uri>[];
  bool offline = false;
  bool quotaExceeded = false;

  /// Symboles inconnus du faux marché.
  final unknownSymbols = <String>{'INCONNU'};

  late final client = MockClient((request) async {
    requests.add(request.url);
    if (offline) throw http.ClientException('pas de réseau');
    if (quotaExceeded) {
      return http.Response('{"code":429,"status":"error"}', 200);
    }

    final q = request.url.queryParameters;
    if (unknownSymbols.contains(q['symbol'])) {
      return http.Response('{"code":404,"status":"error"}', 200);
    }

    final start = DateTime.parse('${q['start_date']}T00:00:00Z');
    final end = DateTime.parse('${q['end_date']}T00:00:00Z');
    final values = [
      // Du plus récent au plus ancien, comme la vraie API.
      for (
        var d = end;
        !d.isBefore(start);
        d = d.subtract(const Duration(days: 1))
      )
        if (d.weekday <= DateTime.friday)
          {
            'datetime': d.toIso8601String().substring(0, 10),
            'close': '${d.day}.0',
          },
    ];
    if (values.isEmpty) {
      return http.Response('{"code":400,"status":"error"}', 200);
    }
    return http.Response(jsonEncode({'values': values, 'status': 'ok'}), 200);
  });

  TwelveDataApi api(DateTime Function() now) =>
      TwelveDataApi(apiKey: 'test', client: client, now: now);
}

/// Base SQLite en mémoire, sur l'ordinateur (pas besoin de téléphone).
/// À fermer en fin de test : la base disparaît, le test suivant repart à vide.
Future<Database> inMemoryDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.open(
    path: inMemoryDatabasePath,
    factory: databaseFactoryFfiNoIsolate,
  );
}
