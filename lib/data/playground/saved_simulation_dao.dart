import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/price_point.dart';
import '../../models/simulation.dart';
import '../local/price_cache_dao.dart' show toDbDate;

/// Une simulation sauvegardée, telle qu'affichée dans la liste.
class SavedSimulation {
  final int id;
  final String name;
  final SimulationParams params;
  final DateTime actualStart;
  final DateTime actualEnd;
  final double finalValue;
  final double gain;
  final double performance;
  final double maxDrawdown;
  final DateTime createdAt;

  const SavedSimulation({
    required this.id,
    required this.name,
    required this.params,
    required this.actualStart,
    required this.actualEnd,
    required this.finalValue,
    required this.gain,
    required this.performance,
    required this.maxDrawdown,
    required this.createdAt,
  });
}

/// Toutes les requêtes SQL des sauvegardes.
class SavedSimulationDao {
  final Database _db;
  SavedSimulationDao(this._db);

  /// Les plus récentes en premier.
  Future<List<SavedSimulation>> getAll() async {
    final rows = await _db.query(
      'saved_simulation',
      orderBy: 'created_at DESC',
    );
    return [for (final row in rows) _fromRow(row)];
  }

  /// Enregistre un résultat ; renvoie l'identifiant attribué par SQLite.
  Future<int> insert(String name, SimulationResult result, DateTime now) {
    return _db.insert('saved_simulation', {
      'name': name,
      'params_json': jsonEncode(result.params.toJson()),
      'actual_start': toDbDate(result.actualStart),
      'actual_end': toDbDate(result.actualEnd),
      'final_value': result.finalValue,
      'gain': result.gain,
      'performance': result.performance,
      'max_drawdown': result.maxDrawdown,
      'created_at': now.toIso8601String(),
    });
  }

  Future<void> rename(int id, String name) async {
    await _db.update(
      'saved_simulation',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('saved_simulation', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    await _db.delete('saved_simulation');
  }

  SavedSimulation _fromRow(Map<String, Object?> row) {
    return SavedSimulation(
      id: row['id'] as int,
      name: row['name'] as String,
      params: SimulationParams.fromJson(
        jsonDecode(row['params_json'] as String) as Map<String, dynamic>,
      ),
      actualStart: dateOnly(DateTime.parse(row['actual_start'] as String)),
      actualEnd: dateOnly(DateTime.parse(row['actual_end'] as String)),
      finalValue: (row['final_value'] as num).toDouble(),
      gain: (row['gain'] as num).toDouble(),
      performance: (row['performance'] as num).toDouble(),
      maxDrawdown: (row['max_drawdown'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
