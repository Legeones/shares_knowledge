import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../models/learn/lessons.dart';
import '../../logic/progress/medals.dart';
import '../learn/lesson_progress_provider.dart';
import '../playground/saves_provider.dart';
import '../settings_provider.dart';
import '../past_trader/trader_attempts_provider.dart';

/// Rassemble la progression éparpillée dans les providers.
ProgressSnapshot watchProgress(BuildContext context) {
  final settings = context.watch<SettingsProvider>();
  final lessons = context.watch<LessonProgressProvider>();
  final attempts = context.watch<TraderAttemptsProvider>().items;
  return ProgressSnapshot(
    lessonsCompleted: lessons.completedCount(availableLessonIds),
    lessonsAvailable: availableLessonIds.length,
    riskLessonsCompleted: lessons.completedCount(riskLessonIds),
    playgroundRuns: settings.playgroundRuns,
    monthlyRuns: settings.monthlyRuns,
    distinctAssets: settings.playgroundAssets.length,
    savedSimulations: context.watch<SavesProvider>().items.length,
    foresightDecadesSeen: settings.foresightDecadesSeen.length,
    traderGames: attempts.length,
    traderRepeats: attempts.where((a) => a.isRepeat).length,
    traderFullGames: attempts.where((a) => !a.stoppedEarly).length,
    bestExcessReturn: attempts.isEmpty
        ? null
        : attempts
              .map((a) => a.performance - a.spyPerformance)
              .reduce((a, b) => a > b ? a : b),
  );
}
