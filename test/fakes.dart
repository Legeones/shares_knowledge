import 'package:shares_knowledge/data/playground/saved_simulation_dao.dart';
import 'package:shares_knowledge/data/past_trader/trader_attempt_dao.dart';
import 'package:shares_knowledge/models/past_trader/trader_attempt.dart';
import 'package:shares_knowledge/models/simulation.dart';

/// Fausse table des sauvegardes, en mémoire, pour les tests d'écrans.
///
/// `implements` : on promet de fournir les mêmes méthodes publiques que le
/// vrai DAO, sans SQLite. Les écrans ne voient pas la différence.
class FakeSavedSimulationDao implements SavedSimulationDao {
  final _rows = <SavedSimulation>[];
  var _nextId = 1;

  @override
  Future<List<SavedSimulation>> getAll() async => [..._rows.reversed];

  @override
  Future<int> insert(String name, SimulationResult r, DateTime now) async {
    _rows.add(
      SavedSimulation(
        id: _nextId,
        name: name,
        params: r.params,
        actualStart: r.actualStart,
        actualEnd: r.actualEnd,
        finalValue: r.finalValue,
        gain: r.gain,
        performance: r.performance,
        maxDrawdown: r.maxDrawdown,
        createdAt: now,
      ),
    );
    return _nextId++;
  }

  @override
  Future<void> rename(int id, String name) async {
    final i = _rows.indexWhere((s) => s.id == id);
    final old = _rows[i];
    _rows[i] = SavedSimulation(
      id: old.id,
      name: name,
      params: old.params,
      actualStart: old.actualStart,
      actualEnd: old.actualEnd,
      finalValue: old.finalValue,
      gain: old.gain,
      performance: old.performance,
      maxDrawdown: old.maxDrawdown,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<void> delete(int id) async => _rows.removeWhere((s) => s.id == id);

  @override
  Future<void> deleteAll() async => _rows.clear();
}

/// Fausse table des parties Past Trader, en mémoire.
class FakeTraderAttemptDao implements TraderAttemptDao {
  final _rows = <TraderAttempt>[];

  @override
  Future<List<TraderAttempt>> getAll() async => [..._rows.reversed];

  @override
  Future<void> insert({
    required String gameId,
    required DateTime playedAt,
    required DateTime endDate,
    required double finalValue,
    required double performance,
    required double spyPerformance,
    required double maxDrawdown,
    required int tradesCount,
    required bool stoppedEarly,
  }) async {
    _rows.add(
      TraderAttempt(
        id: _rows.length + 1,
        gameId: gameId,
        playedAt: playedAt,
        endDate: endDate,
        finalValue: finalValue,
        performance: performance,
        spyPerformance: spyPerformance,
        maxDrawdown: maxDrawdown,
        tradesCount: tradesCount,
        stoppedEarly: stoppedEarly,
        isRepeat: _rows.any((r) => r.gameId == gameId),
      ),
    );
  }

  @override
  Future<void> deleteAll() async => _rows.clear();
}
