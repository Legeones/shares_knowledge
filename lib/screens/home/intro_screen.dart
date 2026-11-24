import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/sections.dart';
import '../../providers/settings_provider.dart';

/// Introduction de première ouverture : 3 pages qui expliquent les différences
/// entre démonstration idéale, jeu de décision et simulation libre.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroPage {
  final IconData icon;
  final String title;
  final String text;
  const _IntroPage(this.icon, this.title, this.text);
}

class _IntroScreenState extends State<IntroScreen> {
  /// PageController : permet de changer de page par programme (bouton Suivant).
  final _pageController = PageController();
  int _page = 0;

  static final _pages = [
    const _IntroPage(
      Icons.school_outlined,
      'Apprendre en manipulant',
      'SharesKnowledge t’aide à comprendre l’investissement avec de vraies '
          'données historiques. Aucune transaction réelle, aucun compte bancaire.',
    ),
    _IntroPage(
      foresightSection.icon,
      'Démonstration idéale ou décision ?',
      '${foresightSection.title} montre ce qu’on obtiendrait en connaissant le '
          'futur : spectaculaire, mais impossible à reproduire.\n\n'
          '${pastTraderSection.title} te fait décider jour après jour, sans voir '
          'la suite : comme dans la réalité.',
    ),
    _IntroPage(
      playgroundSection.icon,
      'Simulation libre',
      'Dans le ${playgroundSection.title}, choisis un actif, une somme et une '
          'période, puis observe le résultat et rejoue-le dans le temps.\n\n'
          'Un résultat passé ne prédit jamais l’avenir.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsProvider>().markIntroSeen();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Pas d'AppBar ici : on demande des icônes sombres dans la barre d'état
    // (heure, batterie), sinon elles seraient blanches sur fond clair.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final page in _pages)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(page.icon, size: 72, color: colors.primary),
                            const SizedBox(height: 24),
                            Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(page.text, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? colors.primary
                            : colors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLast ? _finish : _next,
                    child: Text(_isLast ? 'Commencer' : 'Suivant'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
