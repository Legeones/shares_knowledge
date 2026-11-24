import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Panneau effet Liquid Glass : ce qui est derrière
/// est flouté, puis recouvert d'un voile clair et d'un fin liseré blanc.
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  /// Couleur et opacité du voile posé sur le flou.
  final Color tint;
  final double opacity;

  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 24,
    this.tint = Colors.white,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: tint.withValues(alpha: opacity),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Fond clair avec des halos de couleur : donne de la profondeur et
/// quelque chose à flouter aux panneaux en verre.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.background)),
        Positioned(
          top: -140,
          left: -100,
          child: _Halo(
            color: AppColors.blue.withValues(alpha: 0.22),
            size: 380,
          ),
        ),
        Positioned(
          top: 60,
          right: -140,
          child: _Halo(
            color: AppColors.turquoise.withValues(alpha: 0.16),
            size: 340,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Disque coloré qui s'efface vers ses bords (dégradé radial).
class _Halo extends StatelessWidget {
  final Color color;
  final double size;
  const _Halo({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Grande carte en dégradé bleu pour l'information principale d'un écran,
/// comme la carte de solde de Revolut. Le texte y est blanc.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;

  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient = AppColors.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(28));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Deux bulles claires : l'effet « liquide ».
            Positioned(
              top: -70,
              right: -50,
              child: _Halo(
                color: Colors.white.withValues(alpha: 0.28),
                size: 220,
              ),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _Halo(
                color: AppColors.turquoise.withValues(alpha: 0.45),
                size: 220,
              ),
            ),
            IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Styles de texte blancs pour le contenu d'une [HeroCard] :
/// `heroText(context).displaySmall` au lieu de `textTheme.displaySmall`.
TextTheme heroText(BuildContext context) =>
    Theme.of(context).textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);

/// Petit panneau de verre posé sur une [HeroCard] (une statistique…).
class HeroPill extends StatelessWidget {
  final Widget child;
  const HeroPill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(18),
      blur: 12,
      opacity: 0.16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }
}

/// Icône dans un carré arrondi en dégradé, comme les réglages d'iOS.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;

  const IconTile(
    this.icon, {
    super.key,
    this.size = 44,
    this.gradient = AppColors.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

/// Titre de groupe au-dessus d'une liste de cartes (« Rubriques »…).
class GroupTitle extends StatelessWidget {
  final String text;
  const GroupTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Groupe de lignes dans une carte blanche, séparées par un trait fin
/// (les « listes groupées » des réglages d'iOS).
class CardGroup extends StatelessWidget {
  final List<Widget> children;
  const CardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16),
            child,
          ],
        ],
      ),
    );
  }
}

/// Marges d'une liste d'onglet : les barres du haut et du bas flottent
/// par-dessus le contenu (MediaQuery donne leur hauteur), il faut pouvoir faire
/// défiler au-delà.
EdgeInsets tabListPadding(BuildContext context) {
  final insets = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(16, 8 + insets.top, 16, 24 + insets.bottom);
}

/// Barre du haut des pages empilées : verre dépoli, titre centré, bouton retour
/// rond, comme sur iOS.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  /// Visibilité du fond en verre et du titre (de 0 à 1). Le bouton retour et
  /// les actions restent toujours visibles.
  final double opacity;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.opacity = 1,
  });

  /// Hauteur de la barre (sans la barre d'état du téléphone).
  static const height = 60.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop =
        automaticallyImplyLeading && (ModalRoute.of(context)?.canPop ?? false);
    return AppBar(
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: canPop
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: BackButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.75),
                    foregroundColor: AppColors.ink,
                    fixedSize: const Size(40, 40),
                  ),
                ),
              ),
            )
          : null,
      title: Opacity(opacity: opacity, child: title),
      titleTextStyle: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      actions: [...?actions, const SizedBox(width: 8)],
      bottom: bottom,
      flexibleSpace: Opacity(
        opacity: opacity,
        child: const Glass(
          borderRadius: BorderRadius.zero,
          tint: AppColors.background,
          opacity: 0.55,
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Page à grand titre, comme sur iOS : le titre est écrit en grand au début du
/// contenu (voir [PageTitle]) et la barre du haut est invisible ; seul le
/// bouton retour flotte.
class LargeTitleScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  State<LargeTitleScaffold> createState() => _LargeTitleScaffoldState();
}

class _LargeTitleScaffoldState extends State<LargeTitleScaffold> {
  /// Visibilité de la barre. ValueNotifier : seule la barre est redessinée
  /// pendant le défilement, pas toute la page.
  final _barOpacity = ValueNotifier<double>(0);

  @override
  void dispose() {
    _barOpacity.dispose();
    super.dispose();
  }

  /// Appelée à chaque défilement dans la page.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      // Invisible tant que le grand titre est à l'écran, puis apparition
      // progressive sur 32 pixels de défilement.
      _barOpacity.value = ((n.metrics.pixels - 24) / 32).clamp(0, 1);
    }
    return false; // la notification continue sa route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(GlassAppBar.height),
        child: ValueListenableBuilder<double>(
          valueListenable: _barOpacity,
          builder: (context, opacity, _) => GlassAppBar(
            title: Text(widget.title),
            actions: widget.actions,
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            opacity: opacity,
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.body,
      ),
    );
  }
}

/// Le grand titre en gras, au début du contenu d'une [LargeTitleScaffold].
class PageTitle extends StatelessWidget {
  final String text;

  /// Petite ligne sous le titre (facultative).
  final String? subtitle;

  const PageTitle(this.text, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: textTheme.headlineMedium),
          if (subtitle != null)
            Text(
              subtitle!,
              style: textTheme.titleMedium?.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// Hauteur cachée en haut par la barre d'état et la [GlassAppBar].
double glassBarInset(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  return Scaffold.maybeOf(context) != null ? top : top + GlassAppBar.height;
}

/// Marges d'une liste dans une page à [GlassAppBar] : la barre du haut
/// flotte au-dessus du contenu.
EdgeInsets pagePadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 8,
  double bottom = 24,
}) => EdgeInsets.fromLTRB(
  horizontal,
  top + glassBarInset(context),
  horizontal,
  bottom + MediaQuery.paddingOf(context).bottom,
);

/// SnackBar transparente qui porte une carte en verre ([content]).
SnackBar glassSnackBar(
  Widget content, {
  Duration duration = const Duration(seconds: 4),
}) => SnackBar(
  persist: false,
  duration: duration,
  backgroundColor: Colors.transparent,
  elevation: 0,
  padding: EdgeInsets.zero,
  content: content,
);

/// Message court en verre : une pastille colorée et un texte.
class GlassMessage extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const GlassMessage(
    this.text, {
    super.key,
    this.icon = Icons.check_rounded,
    this.color = AppColors.gain,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      opacity: 0.85,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche un [GlassMessage] en bas de l'écran.
void showGlassMessage(
  ScaffoldMessengerState messenger,
  String text, {
  IconData icon = Icons.check_rounded,
  Color color = AppColors.gain,
}) {
  messenger.showSnackBar(
    glassSnackBar(GlassMessage(text, icon: icon, color: color)),
  );
}

/// Pastille « AI » : signale un contenu produit avec une intelligence
/// artificielle. La toucher affiche [note].
class AiBadge extends StatelessWidget {
  final String note;
  const AiBadge({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Contenu produit avec une IA',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.blue),
            title: const Text('Contenu produit avec une IA'),
            content: Text(note),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Compris'),
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.turquoise],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
