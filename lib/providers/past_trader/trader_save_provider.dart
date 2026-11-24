import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/past_trader/trader_save.dart';

/// La partie en cours, gardée quand on quitte avant la fin. Une seule à la
/// fois : en commencer une nouvelle l'efface.
class TraderSaveProvider extends ChangeNotifier {
  static const _key = 'past_trader_save';
  final SharedPreferences _prefs;

  TraderSaveProvider(this._prefs);

  /// La partie à reprendre pour ce jeu, ou null.
  TraderSave? saveFor(String gameId) {
    final text = _prefs.getString(_key);
    if (text == null) return null;
    try {
      final save = TraderSave.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      return save.gameId == gameId ? save : null;
    } on Object {
      return null; // donnée abîmée : comme s'il n'y en avait pas
    }
  }

  Future<void> save(TraderSave save) async {
    await _prefs.setString(_key, jsonEncode(save.toJson()));
    notifyListeners();
  }

  Future<void> clear() async {
    if (!_prefs.containsKey(_key)) return;
    await _prefs.remove(_key);
    notifyListeners();
  }
}
