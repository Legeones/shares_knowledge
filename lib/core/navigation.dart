import 'package:flutter/widgets.dart';

/// Prévient les écrans abonnés quand une page s'ouvre ou se ferme au-dessus
/// d'eux (MainShell s'en sert pour réafficher les libellés de la barre).
final routeObserver = RouteObserver<ModalRoute<void>>();
