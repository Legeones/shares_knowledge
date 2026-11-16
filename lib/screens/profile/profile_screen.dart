import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/learn/lessons.dart';
import '../../logic/birth_year.dart';
import '../../providers/learn/lesson_progress_provider.dart';
import '../../providers/progress/progress.dart';
import '../../providers/playground/saves_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/past_trader/trader_attempts_provider.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/glass.dart';
import '../../widgets/tax_profile_picker.dart';
import '../home/intro_screen.dart';
import '../progress/progress_screen.dart';
import '../playground/saved_simulations_screen.dart';

/// Profil : pseudo, compteurs, accès aux médailles et statistiques, réglages.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editPseudo(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final pseudo = await askText(
      context,
      title: 'Ton pseudonyme',
      label: 'Pseudonyme (facultatif)',
      initialValue: settings.pseudo,
      allowEmpty: true,
    );
    if (pseudo != null) await settings.setPseudo(pseudo);
  }

  Future<void> _editBirthYear(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final text = await askText(
      context,
      title: 'Ton année de naissance',
      label: 'Année (facultatif)',
      initialValue: '${settings.birthYear ?? ''}',
      allowEmpty: true,
      validator: (t) => validateBirthYear(t, currentYear: DateTime.now().year),
    );
    if (text != null) await settings.setBirthYear(parseBirthYear(text));
  }

  /// Feuille du bas : chaque changement est enregistré tout de suite.
  Future<void> _editTaxProfile(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        // Consumer : la feuille se redessine quand le profil change.
        child: Consumer<SettingsProvider>(
          builder: (_, settings, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ta situation fiscale',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TaxProfilePicker(
                profile: settings.taxProfile(),
                onChanged: settings.setTaxProfile,
              ),
              const SizedBox(height: 12),
              Text(
                settings.taxProfile().explanation,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetProgress(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Tout remettre à zéro ?',
      message:
          'Les leçons, le compteur de simulations, la dernière simulation, '
          'les parties Past Trader, les médailles et toutes les sauvegardes '
          'seront remis à zéro. Les cours déjà téléchargés sont conservés.',
      confirmLabel: 'Remettre à zéro',
    );
    if (!ok || !context.mounted) return;
    await context.read<SettingsProvider>().resetProgress();
    if (!context.mounted) return;
    await context.read<LessonProgressProvider>().reset(availableLessonIds);
    if (!context.mounted) return;
    await context.read<TraderAttemptsProvider>().deleteAll();
    if (!context.mounted) return;
    await context.read<SavesProvider>().deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final hero = heroText(context);
    final settings = context.watch<SettingsProvider>();
    final saves = context.watch<SavesProvider>();
    final lessonProgress = context.watch<LessonProgressProvider>();
    final attempts = context.watch<TraderAttemptsProvider>();
    final colors = Theme.of(context).colorScheme;
    final pseudo = settings.pseudo;

    // Ce Scaffold a sa propre AppBar car l'écran est empilé par-dessus
    // MainShell (Navigator.push) et non affiché dans un onglet.
    return LargeTitleScaffold(
      title: 'Profil',
      body: ListView(
        padding: pagePadding(context, top: 4, bottom: 32),
        children: [
          const PageTitle('Profil'),
          HeroCard(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                child: Text(
                  pseudo.isEmpty ? '?' : pseudo[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                pseudo.isEmpty ? 'Sans pseudonyme' : pseudo,
                style: hero.titleLarge,
              ),
              subtitle: const Text(
                'Toucher pour modifier',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.edit_rounded, color: Colors.white),
              onTap: () => _editPseudo(context),
            ),
          ),
          const SizedBox(height: 20),
          const GroupTitle('Ma situation'),
          CardGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Année de naissance'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${settings.birthYear ?? 'Non renseignée'}'),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _editBirthYear(context),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Fiscalité'),
                subtitle: Text(settings.taxProfile().summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editTaxProfile(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const GroupTitle('Ma progression'),
          CardGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Simulations Playground lancées'),
                trailing: Text('${settings.playgroundRuns}'),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Simulations sauvegardées'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${saves.items.length}'),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SavedSimulationsScreen(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Leçons terminées'),
                trailing: Text(
                  '${lessonProgress.completedCount(availableLessonIds)} / '
                  '${availableLessonIds.length}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history_edu_outlined),
                title: const Text('Parties Past Trader'),
                subtitle: attempts.repeatCount == 0
                    ? null
                    : Text('dont ${attempts.repeatCount} rejouée(s)'),
                trailing: Text('${attempts.count}'),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Médailles et statistiques'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${earnedMedalsCount(watchProgress(context))}'),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => openProgress(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const GroupTitle('Réglages'),
          CardGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: const Text('Réduire les animations'),
                subtitle: const Text('Les valeurs changent sans défilement.'),
                value: settings.reduceAnimations,
                onChanged: settings.setReduceAnimations,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Revoir l’introduction'),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const IntroScreen())),
              ),
              ListTile(
                leading: Icon(Icons.restart_alt, color: colors.error),
                title: Text(
                  'Remettre ma progression à zéro',
                  style: TextStyle(color: colors.error),
                ),
                onTap: () => _resetProgress(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
