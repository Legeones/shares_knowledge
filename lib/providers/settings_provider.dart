import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/taxes.dart';
import '../models/simulation.dart';

/// Préférences et petits compteurs, stockés avec shared_preferences.
///
/// shared_preferences = un simple dictionnaire clé → valeur enregistré sur le
/// téléphone. Parfait pour quelques réglages ; les données nombreuses ou
/// structurées (cours, sauvegardes) restent dans SQLite.
class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  SettingsProvider(this._prefs);

  // Les clés sont des constantes : une faute de frappe serait une erreur
  // de compilation au lieu d'un bug silencieux.
  static const _introSeenKey = 'intro_seen';
  static const _pseudoKey = 'pseudo';
  static const _reduceAnimationsKey = 'reduce_animations';
  static const _playgroundRunsKey = 'playground_runs';
  static const _monthlyRunsKey = 'playground_monthly_runs';
  static const _lastSimulationKey = 'last_simulation';
  static const _foresightSeenKey = 'foresight_seen';
  static const _taxCountryKey = 'tax_country';
  static const _taxStateKey = 'tax_state';
  static const _taxIncomeKey = 'tax_income';
  static const _playgroundAssetsKey = 'playground_assets';
  static const _announcedMedalsKey = 'announced_medals';
  static const _birthYearKey = 'birth_year';
  static const _foresightDecadesKey = 'foresight_decades';

  /// L'introduction a-t-elle déjà été vue (ou passée) ?
  bool get introSeen => _prefs.getBool(_introSeenKey) ?? false;

  Future<void> markIntroSeen() async {
    await _prefs.setBool(_introSeenKey, true);
    notifyListeners();
  }

  /// Le bilan de Perfect Foresight a-t-il été vu ?
  bool get foresightSeen => _prefs.getBool(_foresightSeenKey) ?? false;

  /// Décennies dont le bilan a été vu (1970, 1980…).
  Set<int> get foresightDecadesSeen => {
    for (final d in _prefs.getStringList(_foresightDecadesKey) ?? const [])
      int.parse(d),
  };

  Future<void> markForesightSeen(int decade) async {
    await _prefs.setBool(_foresightSeenKey, true);
    await _prefs.setStringList(_foresightDecadesKey, [
      for (final d in {...foresightDecadesSeen, decade}) '$d',
    ]);
    notifyListeners();
  }

  /// Situation fiscale choisie dans un bilan (pays du téléphone par défaut).
  TaxProfile taxProfile({String? defaultCountryCode}) {
    final state = _prefs.getString(_taxStateKey);
    return TaxProfile(
      taxCountryFor(_prefs.getString(_taxCountryKey) ?? defaultCountryCode),
      state: usStates.where((s) => s.name == state).firstOrNull,
      income: IncomeLevel.values.byName(
        _prefs.getString(_taxIncomeKey) ?? IncomeLevel.middle.name,
      ),
    );
  }

  /// Vrai si l'utilisateur a déjà choisi sa situation fiscale.
  bool get hasTaxProfile => _prefs.containsKey(_taxCountryKey);

  /// Année de naissance facultative : elle sert seulement à proposer la
  /// décennie de Perfect Foresight qui parle à l'utilisateur.
  int? get birthYear => _prefs.getInt(_birthYearKey);

  Future<void> setBirthYear(int? year) async {
    if (year == null) {
      await _prefs.remove(_birthYearKey);
    } else {
      await _prefs.setInt(_birthYearKey, year);
    }
    notifyListeners();
  }

  Future<void> setTaxProfile(TaxProfile profile) async {
    await _prefs.setString(_taxCountryKey, profile.country.code);
    await _prefs.setString(_taxIncomeKey, profile.income.name);
    if (profile.state == null) {
      await _prefs.remove(_taxStateKey);
    } else {
      await _prefs.setString(_taxStateKey, profile.state!.name);
    }
    notifyListeners();
  }

  /// Pseudonyme facultatif ('' si aucun).
  String get pseudo => _prefs.getString(_pseudoKey) ?? '';

  Future<void> setPseudo(String value) async {
    await _prefs.setString(_pseudoKey, value.trim());
    notifyListeners();
  }

  /// Réduire les animations (en plus du réglage d'accessibilité du téléphone).
  bool get reduceAnimations => _prefs.getBool(_reduceAnimationsKey) ?? false;

  Future<void> setReduceAnimations(bool value) async {
    await _prefs.setBool(_reduceAnimationsKey, value);
    notifyListeners();
  }

  /// Nombre de simulations Playground lancées depuis le formulaire.
  int get playgroundRuns => _prefs.getInt(_playgroundRunsKey) ?? 0;

  /// Dont celles en versements mensuels (DCA).
  int get monthlyRuns => _prefs.getInt(_monthlyRunsKey) ?? 0;

  /// Symboles des actifs déjà simulés (sans doublon), pour « Explorateur ».
  Set<String> get playgroundAssets =>
      (_prefs.getStringList(_playgroundAssetsKey) ?? const []).toSet();

  /// Médailles déjà annoncées par un message (pour ne pas les répéter).
  Set<String> get announcedMedals =>
      (_prefs.getStringList(_announcedMedalsKey) ?? const []).toSet();

  Future<void> markMedalsAnnounced(Iterable<String> ids) async {
    await _prefs.setStringList(_announcedMedalsKey, [
      ...{...announcedMedals, ...ids},
    ]);
    notifyListeners();
  }

  /// Dernière simulation lancée, pour le bouton « Reprendre » de l'accueil.
  /// null si aucune, ou si la valeur enregistrée est illisible.
  SimulationParams? get lastSimulation {
    final text = _prefs.getString(_lastSimulationKey);
    if (text == null) return null;
    try {
      return SimulationParams.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
    } on Object {
      return null; // donnée abîmée : on fait comme s'il n'y en avait pas
    }
  }

  /// Appelée après chaque simulation réussie lancée depuis le formulaire.
  Future<void> recordPlaygroundRun(SimulationParams params) async {
    await _prefs.setInt(_playgroundRunsKey, playgroundRuns + 1);
    if (params.isMonthly) {
      await _prefs.setInt(_monthlyRunsKey, monthlyRuns + 1);
    }
    await _prefs.setString(_lastSimulationKey, jsonEncode(params.toJson()));
    await _prefs.setStringList(_playgroundAssetsKey, [
      ...{...playgroundAssets, params.asset.symbol},
    ]);
    notifyListeners();
  }

  /// Remise à zéro de la progression (les préférences sont conservées).
  Future<void> resetProgress() async {
    await _prefs.remove(_playgroundRunsKey);
    await _prefs.remove(_monthlyRunsKey);
    await _prefs.remove(_lastSimulationKey);
    await _prefs.remove(_foresightSeenKey);
    await _prefs.remove(_foresightDecadesKey);
    await _prefs.remove(_playgroundAssetsKey);
    await _prefs.remove(_announcedMedalsKey);
    notifyListeners();
  }
}
