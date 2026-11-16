import 'package:flutter/foundation.dart';

import '../../data/playground/saved_simulation_dao.dart';
import '../../models/simulation.dart';

/// Liste des simulations sauvegardées, partagée entre l'accueil, le profil
/// et l'écran des sauvegardes. Après chaque modification, la liste est
/// relue depuis la base puis les écrans sont prévenus.
class SavesProvider extends ChangeNotifier {
  final SavedSimulationDao _dao;
  final DateTime Function() _now;

  SavesProvider(this._dao, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  List<SavedSimulation> _items = [];
  bool _isLoaded = false;

  List<SavedSimulation> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _items = await _dao.getAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(String name, SimulationResult result) async {
    await _dao.insert(name.trim(), result, _now());
    await load();
  }

  Future<void> rename(int id, String name) async {
    await _dao.rename(id, name.trim());
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    await load();
  }

  Future<void> deleteAll() async {
    await _dao.deleteAll();
    await load();
  }
}
