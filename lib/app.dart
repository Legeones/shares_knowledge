import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation.dart';
import 'core/theme.dart';
import 'screens/home/main_shell.dart';

/// Racine de l'application : configure le thème et le premier écran.
class SharesKnowledgeApp extends StatelessWidget {
  const SharesKnowledgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharesKnowledge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Calendrier, boutons « Annuler / OK »… en français.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorObservers: [routeObserver],
      home: const MainShell(),
    );
  }
}
