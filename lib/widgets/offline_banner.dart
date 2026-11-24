import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/connectivity_provider.dart';

/// Bandeau affiché en haut de l'application quand il n'y a pas de réseau.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // `watch` : ce widget sera redessiné à chaque notifyListeners().
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    if (isOnline) return const SizedBox.shrink(); // rien à afficher

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hors connexion : les données déjà consultées restent disponibles.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
