import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/playground/saved_simulation_dao.dart';
import '../../providers/playground/saves_provider.dart';
import '../../widgets/dialogs.dart';
import 'simulation_result_screen.dart';
import '../../widgets/glass.dart';

/// Liste des simulations sauvegardées : ouvrir, renommer, supprimer.
class SavedSimulationsScreen extends StatelessWidget {
  const SavedSimulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saves = context.watch<SavesProvider>();

    return LargeTitleScaffold(
      title: 'Sauvegardes',
      body: !saves.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : saves.items.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: pagePadding(context, top: 4),
              children: [
                const PageTitle('Sauvegardes'),
                for (final saved in saves.items) ...[
                  _SavedCard(saved: saved),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 48),
            SizedBox(height: 16),
            Text(
              'Aucune simulation sauvegardée.\n'
              'Lance une simulation dans le Playground, puis touche '
              '« Sauvegarder » sur le résultat.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _Action { rename, delete }

class _SavedCard extends StatelessWidget {
  final SavedSimulation saved;
  const _SavedCard({required this.saved});

  Future<void> _onAction(BuildContext context, _Action action) async {
    final saves = context.read<SavesProvider>();
    switch (action) {
      case _Action.rename:
        final name = await askText(
          context,
          title: 'Renommer',
          label: 'Nom de la sauvegarde',
          initialValue: saved.name,
        );
        if (name != null) await saves.rename(saved.id, name);
      case _Action.delete:
        final ok = await confirmAction(
          context,
          title: 'Supprimer la sauvegarde ?',
          message: '« ${saved.name} » sera définitivement supprimée.',
          confirmLabel: 'Supprimer',
        );
        if (ok) await saves.delete(saved.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = saved.params.asset.currency;
    final isGain = saved.gain >= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        title: Text(saved.name),
        subtitle: Text(
          '${formatMoney(saved.params.amount, cur)}'
          '${saved.params.isMonthly ? '/mois' : ''} → '
          '${formatMoney(saved.finalValue, cur)}\n'
          'Du ${formatDate(saved.actualStart)} au ${formatDate(saved.actualEnd)} · '
          'sauvegardée le ${formatDate(saved.createdAt)}',
        ),
        isThreeLine: true,
        leading: Text(
          formatPercent(saved.performance),
          style: TextStyle(
            color: isGain ? AppColors.gain : AppColors.loss,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Toucher la carte : relance la simulation (depuis le cache local).
        onTap: () => openSimulation(context, saved.params),
        trailing: PopupMenuButton<_Action>(
          tooltip: 'Options',
          onSelected: (action) => _onAction(context, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _Action.rename, child: Text('Renommer')),
            PopupMenuItem(value: _Action.delete, child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}
