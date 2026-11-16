import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/foresight/foresight.dart';

/// Décennies disponibles dans Perfect Foresight : un fichier par décennie.
const foresightDecades = [1970, 1980, 1990, 2000, 2010, 2020];

String foresightAsset(int decade) =>
    'assets/scenarios/foresight/foresight_${decade}s.json';

/// Lit tous les parcours Perfect Foresight embarqués (hors connexion).
Future<ForesightCatalog> loadForesightCatalog() async => ForesightCatalog([
  for (final decade in foresightDecades)
    ForesightScenario.fromJson(
      jsonDecode(await rootBundle.loadString(foresightAsset(decade)))
          as Map<String, dynamic>,
    ),
]);
