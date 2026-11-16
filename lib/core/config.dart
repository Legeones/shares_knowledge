/// Clé Twelve Data, injectée à la compilation :
///   flutter run --dart-define-from-file=env.json
///
/// `String.fromEnvironment` lit la valeur au moment de la compilation.
/// Si l'option est oubliée, la clé est vide et l'API répondra par une
/// erreur explicite (voir `TwelveDataApi`).
const twelveDataApiKey = String.fromEnvironment('TWELVE_DATA_KEY');
