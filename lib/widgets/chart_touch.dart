import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Comportement commun à tous les graphiques en courbe : en touchant (ou en
/// glissant le doigt), une bulle affiche le point le plus proche.
LineTouchData chartTouch(String? Function(LineBarSpot spot) label) =>
    LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => AppColors.blue,
        // La bulle reste dans le graphique, même au bord de l'écran.
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (touched) => [
          for (final spot in touched)
            switch (label(spot)) {
              final text? => LineTooltipItem(
                text,
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
              null => null,
            },
        ],
      ),
    );
