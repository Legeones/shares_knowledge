import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/models/asset.dart';
import 'package:shares_knowledge/models/price_point.dart';

void main() {
  group('PricePoint.fromJson', () {
    test('lit la date et convertit le prix texte en nombre', () {
      final p = PricePoint.fromJson({
        'datetime': '2024-01-05',
        'close': '181.17999',
      });
      expect(p.date, DateTime.utc(2024, 1, 5));
      expect(p.close, 181.17999);
    });

    test('toJson puis fromJson redonne le même cours', () {
      final original = PricePoint(date: DateTime.utc(2024, 2, 29), close: 12.5);
      final copy = PricePoint.fromJson(original.toJson());
      expect(copy.date, original.date);
      expect(copy.close, original.close);
    });

    test('refuse un élément incomplet ou mal formé', () {
      expect(
        () => PricePoint.fromJson({'datetime': '2024-01-05'}),
        throwsFormatException,
      );
      expect(
        () => PricePoint.fromJson({'datetime': 'hier', 'close': '1'}),
        throwsFormatException,
      );
      expect(() => PricePoint.fromJson('texte'), throwsFormatException);
    });
  });

  group('catalogue d’actifs', () {
    // On lit le vrai fichier embarqué dans l'application.
    final catalog = parseAssetCatalog(
      File('assets/data/assets_catalog.json').readAsStringSync(),
    );

    test('se lit sans erreur et n’est pas vide', () {
      expect(catalog, isNotEmpty);
    });

    test('chaque symbole est unique', () {
      final symbols = catalog.map((a) => a.symbol).toSet();
      expect(symbols, hasLength(catalog.length));
    });

    test('contient les trois types d’actifs', () {
      expect(catalog.map((a) => a.type).toSet(), AssetType.values.toSet());
    });
  });
}
