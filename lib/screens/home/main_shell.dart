import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation.dart';
import '../../core/sections.dart';
import '../../core/theme.dart';
import '../../logic/progress/medals.dart';
import '../../models/foresight/foresight.dart';
import '../../providers/progress/progress.dart';
import '../../widgets/glass.dart';
import '../../widgets/progress/medal_widgets.dart';
import '../../widgets/offline_banner.dart';
import '../../providers/settings_provider.dart';
import '../foresight/foresight_player_screen.dart';
import 'home_screen.dart';
import 'intro_screen.dart';
import '../profile/onboarding_screen.dart';
import '../learn/learn_screen.dart';
import '../foresight/foresight_screen.dart';
import '../past_trader/past_trader_screen.dart';
import '../playground/playground_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';

/// « Coquille » de l'application : barre du haut, barre de navigation du bas,
/// et au milieu l'écran de la rubrique sélectionnée.
///
/// C'est un StatefulWidget car il doit se souvenir de l'onglet sélectionné.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

// RouteAware : MainShell est prévenu quand une page empilée au-dessus de
// lui se ferme (didPopNext).
class _MainShellState extends State<MainShell> with RouteAware {
  /// 0 = Accueil, 1 à 4 = les rubriques dans l'ordre de `sections`.
  int _selectedIndex = 0;

  /// Controlle la visibilité des libellés dans la barre du bas selon le scroll.
  bool _showLabels = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Abonnement à l'observateur des pages, pour la page de MainShell.
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour sur MainShell après la fermeture d'une page (profil, leçon,
  /// résultat…) : les libellés de la barre réapparaissent.
  @override
  void didPopNext() => setState(() => _showLabels = true);

  @override
  void initState() {
    super.initState();
    // Première ouverture : la démonstration Perfect Foresight, puis son
    // bilan, puis l'introduction. addPostFrameCallback attend la fin du
    // premier affichage : on ne peut pas naviguer pendant la construction.
    if (!context.read<SettingsProvider>().introSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFirstLaunch());
    }
  }

  /// Premier démarrage : « Faisons connaissance », puis la démonstration
  /// Perfect Foresight, son bilan, et enfin l'introduction.
  void _openFirstLaunch() {
    // `?` : null si les parcours ne sont pas fournis (introduction seule).
    final catalog = context.read<ForesightCatalog?>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          // La décennie se choisit après la question sur l'année de naissance.
          onDone: (ctx) => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => catalog == null
                  ? const IntroScreen()
                  : ForesightPlayerScreen(
                      scenario: suggestedScenario(
                        catalog,
                        ctx.read<SettingsProvider>().birthYear,
                      ),
                      firstLaunch: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vrai pendant l'annonce, pour ne pas l'envoyer deux fois.
  bool _announcing = false;

  /// Message « Médaille obtenue », une seule fois par médaille.
  ///
  /// MainShell reste sous les autres écrans : il voit donc les médailles
  /// gagnées n'importe où dans l'application.
  void _announceMedals(List<MedalStatus> statuses, Set<String> announced) {
    final fresh = newlyEarned(statuses, announced);
    if (fresh.isEmpty || _announcing) return;
    _announcing = true;
    // Après l'affichage : on ne montre pas de message pendant un build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messenger = ScaffoldMessenger.of(context);
      // Tous les paliers atteints : on n'annoncera pas « Fer » après « Or ».
      await context.read<SettingsProvider>().markMedalsAnnounced([
        for (final s in statuses) ...earnedKeys(s),
      ]);
      _announcing = false;
      const duration = Duration(seconds: 5);
      // Pas de bouton d'action (il la rendrait permanente) : toute la
      // carte se touche.
      messenger.showSnackBar(
        glassSnackBar(
          MedalToast(
            awards: fresh,
            duration: duration,
            onTap: () {
              messenger.hideCurrentSnackBar();
              openProgress(context);
            },
          ),
          duration: duration,
        ),
      );
    });
  }

  void _selectTab(int index) {
    // setState prévient Flutter que l'état a changé : build() est rappelé
    // et l'écran affiché est mis à jour. Changer d'onglet réaffiche aussi
    // les libellés de la barre du bas.
    setState(() {
      _selectedIndex = index;
      _showLabels = true;
    });
  }

  void _openProfile() {
    // Le profil n'est pas un onglet : on l'empile par-dessus avec Navigator.
    // La flèche « retour » apparaît automatiquement dans son AppBar.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedIndex == 0
        ? 'SharesKnowledge'
        : sections[_selectedIndex].title;
    final aiNote = sections[_selectedIndex].aiNote;
    final settings = context.watch<SettingsProvider>();
    final pseudo = settings.pseudo;
    _announceMedals(
      evaluateMedals(watchProgress(context)),
      settings.announcedMedals,
    );

    // Le fond à halos est derrière tout l'écran : le Scaffold et sa barre du
    // haut sont transparents pour le laisser voir.
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // extendBody : le contenu défile sous la barre du bas, qui flotte
        // en verre dépoli par-dessus.
        extendBody: true,
        // Idem en haut : le contenu glisse sous la barre de titre.
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // flexibleSpace : ce qui est dessiné derrière le titre. Ici du
          // verre dépoli, sans arrondi ni liseré.
          flexibleSpace: const Glass(
            borderRadius: BorderRadius.zero,
            tint: AppColors.background,
            opacity: 0.6,
            child: SizedBox.expand(),
          ),
          toolbarHeight: 64,
          titleTextStyle: Theme.of(context).textTheme.headlineMedium,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
              if (aiNote != null) ...[
                const SizedBox(width: 10),
                AiBadge(note: aiNote),
              ],
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Profil',
              onPressed: _openProfile,
              icon: _Avatar(pseudo: pseudo),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.metrics.axis == Axis.vertical &&
                notification.scrollDelta != null) {
              final pixels = notification.metrics.pixels;
              final delta = notification.scrollDelta!;

              // Tout en haut de la page : réafficher les libellés
              if (pixels <= 0 && !_showLabels) {
                setState(() => _showLabels = true);
              }
              // Scroll vers le bas : masquer les libellés
              else if (delta > 3.0 && pixels > 10 && _showLabels) {
                setState(() => _showLabels = false);
              }
              // Scroll vers le haut : réafficher les libellés
              else if (delta < -3.0 && !_showLabels) {
                setState(() => _showLabels = true);
              }
            }
            return false;
          },
          child: Stack(
            children: [
              // IndexedStack garde tous les écrans en mémoire et n'affiche que
              // celui demandé : changer d'onglet ne fait pas perdre la saisie.
              IndexedStack(
                index: _selectedIndex,
                children: [
                  HomeScreen(onOpenSection: _selectTab),
                  const LearnScreen(),
                  const ForesightScreen(),
                  const PastTraderScreen(),
                  const PlaygroundScreen(),
                ],
              ),
              // Visible dans toutes les rubriques quand le réseau est coupé,
              // posé juste sous la barre de titre.
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                child: const OfflineBanner(),
              ),
            ],
          ),
        ),
        // SafeArea : la barre reste au-dessus de la barre de gestes d'Android.
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Glass(
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Row(
                  // Clé : permet aux tests de retrouver la barre des onglets.
                  key: const ValueKey('tab-bar'),
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      // Expanded assure des cases de largeurs strictement égales
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final isSelected = _selectedIndex == i;
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectTab(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  vertical: _showLabels ? 6 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.blue.withValues(alpha: 0.10)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sections[i].icon,
                                      color: isSelected
                                          ? AppColors.blue
                                          : AppColors.muted,
                                      size: 22,
                                    ),
                                    // Animation progressive de la taille et de l'opacité du label
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      child: _showLabels
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 2),
                                                AnimatedOpacity(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  opacity: _showLabels
                                                      ? 1.0
                                                      : 0.0,
                                                  child: Text(
                                                    sections[i].title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isSelected
                                                          ? AppColors.blue
                                                          : AppColors.muted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille ronde du profil : l'initiale du pseudo, ou une silhouette.
class _Avatar extends StatelessWidget {
  final String pseudo;
  const _Avatar({required this.pseudo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.heroGradient,
      ),
      child: pseudo.isEmpty
          ? const Icon(Icons.person_rounded, color: Colors.white)
          : Text(
              pseudo.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
    );
  }
}
