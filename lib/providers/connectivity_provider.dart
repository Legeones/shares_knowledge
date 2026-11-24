import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Indique si le téléphone a un réseau (pas forcément internet : le
/// repository gère aussi l'échec des requêtes).
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
