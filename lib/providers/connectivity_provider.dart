import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Indique si le téléphone a un réseau, et prévient les écrans quand ça change.
///
/// C'est un ChangeNotifier : quand `isOnline` change, il appelle
/// `notifyListeners()` et tous les widgets qui l'observent se redessinent.
///
/// Limite : être connecté à un Wi-Fi ne garantit pas l'accès à internet.
/// C'est pourquoi le repository gère aussi l'échec réel de la requête.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  late final StreamSubscription<bool> _subscription;

  /// [statusStream] sert aux tests : on y injecte un faux état du réseau.
  ConnectivityProvider({Stream<bool>? statusStream}) {
    _subscription = (statusStream ?? _platformStatus()).listen(_update);
  }

  bool get isOnline => _isOnline;

  void _update(bool online) {
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  /// Flux d'états du réseau fourni par le système.
  ///
  /// `async*` crée un Stream : chaque `yield` envoie une valeur.
  /// On envoie d'abord l'état actuel, puis chaque changement.
  static Stream<bool> _platformStatus() async* {
    final connectivity = Connectivity();
    yield _hasNetwork(await connectivity.checkConnectivity());
    yield* connectivity.onConnectivityChanged.map(_hasNetwork);
  }

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void dispose() {
    _subscription.cancel(); // arrêter d'écouter quand l'objet est détruit
    super.dispose();
  }
}
