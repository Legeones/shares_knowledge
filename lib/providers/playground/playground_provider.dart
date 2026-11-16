import 'package:flutter/foundation.dart';

import '../../data/api/api_exceptions.dart';
import '../../data/repositories/price_repository.dart';
import '../../logic/playground/simulator.dart';
import '../../models/simulation.dart';

/// Les états possibles d'une simulation. `sealed` : l'écran doit les traiter
/// tous dans son `switch` (obligation : chargement / données / erreur).
sealed class PlaygroundState {
  const PlaygroundState();
}

/// Rien de lancé pour l'instant.
class PlaygroundIdle extends PlaygroundState {
  const PlaygroundIdle();
}

/// Récupération des cours en cours.
class PlaygroundLoading extends PlaygroundState {
  final SimulationParams params;
  const PlaygroundLoading(this.params);
}

/// Résultat prêt, avec l'origine des données (date, cache de secours).
class PlaygroundSuccess extends PlaygroundState {
  final SimulationResult result;
  final PriceData data;
  const PlaygroundSuccess(this.result, this.data);
}

/// Échec, avec un message pour l'utilisateur.
class PlaygroundFailure extends PlaygroundState {
  final SimulationParams params;
  final String message;
  const PlaygroundFailure(this.params, this.message);
}

/// État du Playground, partagé entre le formulaire et l'écran de résultat.
class PlaygroundProvider extends ChangeNotifier {
  final PriceRepository _repository;

  /// Prévenu après chaque **nouvelle** simulation réussie (compteur du
  /// profil, bouton « Reprendre »). Le provider ne sait pas ce qu'on en fait.
  final void Function(SimulationParams params)? onNewRunSucceeded;

  PlaygroundProvider(this._repository, {this.onNewRunSucceeded});

  /// Vrai si la simulation en cours vient du formulaire ; faux pour la
  /// réouverture d'une sauvegarde ou « Reprendre » (déjà comptées).
  bool _isNewRun = true;

  PlaygroundState _state = const PlaygroundIdle();
  PlaygroundState get state => _state;

  void _setState(PlaygroundState state) {
    _state = state;
    notifyListeners(); // l'écran de résultat se redessine
  }

  Future<void> simulate(SimulationParams params, {bool isNewRun = true}) async {
    _isNewRun = isNewRun;
    _setState(PlaygroundLoading(params));
    try {
      final data = await _repository.getDailySeries(
        params.asset.symbol,
        start: params.start,
        end: params.end,
      );
      final result = runSimulation(params, data.series);
      _setState(PlaygroundSuccess(result, data));
      if (_isNewRun) onNewRunSucceeded?.call(params);
    } on ApiException catch (e) {
      _setState(PlaygroundFailure(params, e.message));
    } on SimulationException catch (e) {
      _setState(PlaygroundFailure(params, e.message));
    }
  }

  /// Relance la dernière simulation (bouton « Réessayer »).
  Future<void> retry() async {
    final current = _state;
    if (current is PlaygroundFailure) {
      await simulate(current.params, isNewRun: _isNewRun);
    }
  }
}
