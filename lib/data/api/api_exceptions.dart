/// Toutes les erreurs que peut produire l'appel à l'API.
sealed class ApiException implements Exception {
  /// Message compréhensible par l'utilisateur.
  final String message;
  const ApiException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Pas de réseau, serveur injoignable ou trop lent.
class NetworkException extends ApiException {
  const NetworkException()
    : super('Connexion impossible. Vérifie ta connexion internet.');
}

/// Trop de requêtes (offre gratuite : 8 par minute, 800 par jour).
class QuotaExceededException extends ApiException {
  const QuotaExceededException()
    : super('Trop de demandes en peu de temps. Réessaie dans une minute.');
}

/// Clé absente ou refusée.
class InvalidApiKeyException extends ApiException {
  const InvalidApiKeyException() : super('Clé API manquante ou invalide.');
}

/// Symbole inconnu ou aucun cours sur la période demandée.
class NoDataException extends ApiException {
  const NoDataException(String symbol)
    : super('Aucune donnée disponible pour $symbol sur cette période.');
}

/// Réponse reçue mais dans un format inattendu.
class BadResponseException extends ApiException {
  const BadResponseException()
    : super('Le service de données a renvoyé une réponse inattendue.');
}
