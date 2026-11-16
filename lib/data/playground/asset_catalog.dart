import 'package:flutter/services.dart' show rootBundle;

import '../../models/asset.dart';

/// Charge la liste des actifs proposés dans le Playground.
///
/// Le catalogue est un fichier JSON embarqué dans l'application
/// (assets/data/assets_catalog.json). Contient pour l'instant des
/// actifs basiques (Bitcoin, Ethereum, GAFAM, etc.).
Future<List<Asset>> loadAssetCatalog() async {
  final text = await rootBundle.loadString('assets/data/assets_catalog.json');
  return parseAssetCatalog(text);
}
