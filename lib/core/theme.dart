import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleurs de l'application, construites autour du bleu du logo Sᵏ.
class AppColors {
  static const navy = Color(0xFF003891); // le S du logo
  static const turquoise = Color(0xFF01D2BE); // le k du logo
  static const blue = Color(0xFF1F5EFF); // bleu vif : boutons, courbes
  static const sky = Color(0xFF6A9BFF); // bleu clair des dégradés

  static const ink = Color(0xFF0B1424); // texte principal
  static const muted = Color(0xFF6B7385); // texte secondaire
  static const background = Color(0xFFF2F4F8); // fond gris bleuté (style iOS)
  static const line = Color(0xFFE3E7EF); // séparateurs, contours
  static const paleBlue = Color(0xFFE4ECFF); // fonds doux

  // Gains et pertes : la couleur n'est jamais seule, on affiche aussi le signe.
  static const gain = Color(0xFF0F9D6B);
  static const loss = Color(0xFFE5484D);

  static const gold = Color(0xFFE0A21B);
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD66B), gold],
  );

  /// Dégradé des cartes « héros » (comme la carte de solde de Revolut).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue, sky],
  );

  /// Remplissage sous une courbe : la couleur s'efface vers le bas.
  static LinearGradient fadeDown(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
  );
}

class AppTheme {
  /// Arrondi des cartes : grand et doux, comme sur iOS.
  static const radius = 22.0;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.turquoise,
      // Fonds « doux » (boutons tonals, encadrés) : un bleu très pâle.
      primaryContainer: AppColors.paleBlue,
      onPrimaryContainer: AppColors.navy,
      secondaryContainer: AppColors.paleBlue,
      onSecondaryContainer: AppColors.blue,
      surface: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.loss,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    // Titres gras et serrés (lettres rapprochées) : le style Apple/Revolut.
    TextStyle? bold(TextStyle? s, FontWeight w, double spacing) =>
        s?.copyWith(fontWeight: w, letterSpacing: spacing);
    final textTheme = text.copyWith(
      displaySmall: bold(text.displaySmall, FontWeight.w800, -1),
      headlineMedium: bold(text.headlineMedium, FontWeight.w800, -0.8),
      headlineSmall: bold(text.headlineSmall, FontWeight.w700, -0.5),
      titleLarge: bold(text.titleLarge, FontWeight.w700, -0.4),
      titleMedium: bold(text.titleMedium, FontWeight.w600, -0.2),
      titleSmall: bold(text.titleSmall, FontWeight.w600, 0),
      labelLarge: bold(text.labelLarge, FontWeight.w600, 0),
      bodySmall: text.bodySmall?.copyWith(color: AppColors.muted),
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final field = UnderlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      // Barre du haut fondue dans le fond, titre sombre et gras.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Champs blancs arrondis, sans contour ; liseré bleu quand actifs.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        errorBorder: field.copyWith(
          borderSide: const BorderSide(color: AppColors.loss),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: AppColors.paleBlue,
          selectedForegroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: Colors.white,
        selectedColor: AppColors.blue.withValues(alpha: 0.15),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      // La barre du bas est posée sur un panneau en verre (MainShell) :
      // elle-même est transparente.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.blue.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.muted,
          ),
        ),
      ),
      // Onglets façon « segmented control » d'iOS : une pilule blanche.
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x1A0B1424), blurRadius: 8)],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.blue,
        // Valeurs à droite d'une ligne (compteurs…) : lisibles, pas minuscules.
        leadingAndTrailingTextStyle: textTheme.titleSmall,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: AppColors.line,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.loss),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
