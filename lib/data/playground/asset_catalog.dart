import 'package:flutter/services.dart' show rootBundle;

import '../../models/asset.dart';

/// Charge la liste des actifs proposés dans le Playground.
Future<List<Asset>> loadAssetCatalog() async {
  final text = await rootBundle.loadString('assets/data/assets_catalog.json');
  return parseAssetCatalog(text);
}
