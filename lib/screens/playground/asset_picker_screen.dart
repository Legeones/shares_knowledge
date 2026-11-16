import 'package:flutter/material.dart';

import '../../data/playground/asset_catalog.dart';
import '../../models/asset.dart';
import '../../widgets/glass.dart';

/// Liste des actifs avec recherche. Renvoie l'actif choisi à l'écran
/// précédent avec `Navigator.pop(context, asset)`.
class AssetPickerScreen extends StatefulWidget {
  const AssetPickerScreen({super.key});

  @override
  State<AssetPickerScreen> createState() => _AssetPickerScreenState();
}

class _AssetPickerScreenState extends State<AssetPickerScreen> {
  /// Le chargement est lancé une seule fois (dans initState), pas à chaque
  /// build : sinon le fichier serait relu à chaque frappe dans la recherche.
  late final Future<List<Asset>> _catalog;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _catalog = loadAssetCatalog();
  }

  List<Asset> _filter(List<Asset> assets) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return assets;
    return assets
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              a.symbol.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: const Text('Choisir un actif')),
      body: Column(
        children: [
          Padding(
            // Sous la barre du haut, qui flotte au-dessus de la page.
            padding: EdgeInsets.fromLTRB(
              16,
              16 + glassBarInset(context),
              16,
              16,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher (ex. Apple, SPY, Bitcoin)',
              ),
              // Chaque frappe met à jour la recherche et redessine la liste.
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
          Expanded(
            // FutureBuilder affiche un contenu différent selon l'état du Future.
            child: FutureBuilder<List<Asset>>(
              future: _catalog,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Impossible de lire la liste des actifs.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assets = _filter(snapshot.data!);
                if (assets.isEmpty) {
                  return const Center(
                    child: Text('Aucun actif ne correspond.'),
                  );
                }
                // ListView.builder ne construit que les lignes visibles :
                // efficace même avec une très longue liste.
                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, i) => _AssetTile(
                    asset: assets[i],
                    onTap: () => Navigator.pop(context, assets[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const _AssetTile({required this.asset, required this.onTap});

  static const _typeLabels = {
    AssetType.stock: 'Action',
    AssetType.etf: 'ETF',
    AssetType.crypto: 'Crypto',
  };

  static const _typeIcons = {
    AssetType.stock: Icons.business_outlined,
    AssetType.etf: Icons.pie_chart_outline,
    AssetType.crypto: Icons.currency_bitcoin,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_typeIcons[asset.type]),
      title: Text('${asset.name} (${asset.symbol})'),
      subtitle: Text(asset.description),
      trailing: Text(_typeLabels[asset.type]!),
      onTap: onTap,
    );
  }
}
