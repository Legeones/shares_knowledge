import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LessonStatus { notStarted, inProgress, completed }

/// Avancement des leçons, enregistré dans shared_preferences.
class LessonProgressProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  LessonProgressProvider(this._prefs);

  String _stepKey(String id) => 'lesson.$id.step';
  String _completedKey(String id) => 'lesson.$id.completed';

  bool isCompleted(String id) => _prefs.getBool(_completedKey(id)) ?? false;

  /// Étape où reprendre (0 = début).
  int stepOf(String id) => _prefs.getInt(_stepKey(id)) ?? 0;

  LessonStatus statusOf(String id) {
    if (isCompleted(id)) return LessonStatus.completed;
    if (_prefs.containsKey(_stepKey(id))) return LessonStatus.inProgress;
    return LessonStatus.notStarted;
  }

  int completedCount(Iterable<String> ids) => ids.where(isCompleted).length;

  Future<void> saveStep(String id, int step) async {
    await _prefs.setInt(_stepKey(id), step);
    notifyListeners();
  }

  /// Fin de leçon : terminée, et la prochaine ouverture repart du début.
  Future<void> complete(String id) async {
    await _prefs.setBool(_completedKey(id), true);
    await _prefs.remove(_stepKey(id));
    notifyListeners();
  }

  Future<void> reset(Iterable<String> ids) async {
    for (final id in ids) {
      await _prefs.remove(_stepKey(id));
      await _prefs.remove(_completedKey(id));
    }
    notifyListeners();
  }
}
