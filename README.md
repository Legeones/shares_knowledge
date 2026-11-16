# SharesKnowledge

SharesKnowledge est une application mobile Flutter de partage de connaissances destinée aux débutants qui souhaitent comprendre l'investissement en manipulant des données réelles, **sans effectuer de transactions** (pas de compte, pas de courtier, pas d'argent réel).

Les résultats affichés servent à apprendre : ce ne sont ni des prévisions, ni des conseils financiers.

## Rubriques

| Rubrique | Question posée | Ce qu'on y fait |
| --- | --- | --- |
| **Home** | Comprenez-vous les bases ? | Accueil, accès aux rubriques, progression et profil. |
| **Learn** | Comment fonctionne cette notion ? | Leçons courtes avec curseurs et graphique qui réagit : rendement, rendement composé, volatilité, baisse maximale, investissement régulier (DCA), diversification. |
| **Foresight** (Perfect Foresight) | Que pourrait-on obtenir en connaissant le futur ? | Parcours scénarisé par décennie (1970 → 2020) : 1 000 $ placés dans les meilleurs actifs au meilleur moment, avec impôts, retraits pour vivre et inflation. Montre pourquoi c'est impossible à reproduire. |
| **Past Trader** | Qu'aurais-je décidé sans connaître la suite ? | Partie de trading sur 2018-2020 : 10 000 $, 16 actifs, fil d'actualités jour par jour, le futur reste caché. Bilan avec impôts et comparaison au S&P 500. |
| **Playground** | Que se serait-il passé avec mes paramètres ? | Choix d'un actif, d'un montant et d'une période (versement unique ou mensuel) ; gain, performance, baisse maximale, graphique et rejeu animé dans le temps. |

À côté des rubriques : profil (année de naissance, situation fiscale, réglages), simulations sauvegardées, médailles et écran « Ma progression », portefeuille fictif « Mon portefeuille », bandeau hors connexion.

## Ce qui a été fait à la main / avec l'aide de l'IA

**Fait à la main** : tout le projet, à l'exception de Past Trader et Perfect Foresight.
Cela comprend l'architecture (modèles, logique, données, providers, écrans), le client API Twelve Data, la base SQLite et le cache des cours, le mode hors connexion, Learn et ses leçons, Playground (formulaire, simulation, graphique, rejeu), les animations (cycle soleil/lune, révélation du graphique, compteur), le thème « verre », la navigation et la barre du bas, le profil, les sauvegardes, les médailles et la progression, le portefeuille, ainsi que les tests associés.

**Réalisé avec l'aide de l'IA** : **Past Trader** et **Perfect Foresight**, aussi bien le code que les fichiers de données qui les font fonctionner :

- Past Trader
  - code : `lib/**/past_trader/` (moteur de partie, ordres, fil d'actualités, écrans de jeu et de bilan, sauvegarde des parties) ;
  - données : `assets/scenarios/past_trader_2018_2020.json` (cours réels récupérés sur Twelve Data) et `assets/scenarios/past_trader_news.json` (actualités rédigées avec une IA à partir d'événements réels) ;
  - scripts de génération : `tool/build_past_trader.dart`, `tool/build_past_trader_news.dart`, `tool/past_trader_assets.dart`, `tool/past_trader_news.dart`, `tool/text_utils.dart`.
- Perfect Foresight
  - code : `lib/**/foresight/` (calcul du parcours, impôts, retraits, inflation, lecture animée, chapitres, bilan) ;
  - données : `assets/scenarios/foresight/foresight_*.json` (parcours proposés par une IA, GPT, puis vérifiés avec les vrais cours Twelve Data) et les textes sources `docs/foresight_gpt/` ;
  - scripts de génération : `tool/build_foresight_scenario.dart`, `tool/find_best_window.dart`, `tool/foresight/`.

Dans l'application, une pastille **« AI »** sur le titre de ces deux rubriques le rappelle à l'utilisateur.

## Technique

- **Flutter / Dart**, état partagé avec `provider`.
- **API REST** : [Twelve Data](https://twelvedata.com) `/time_series` (cours de clôture quotidiens), JSON converti à la main (`fromJson`).
- **Stockage local** : SQLite (`sqflite`) pour le cache des cours, les simulations sauvegardées, les parties Past Trader et le portefeuille ; `shared_preferences` pour les réglages et la progression.
- **Graphiques** : `fl_chart`.
- **Hors connexion** : les cours déjà consultés, les leçons et les scénarios embarqués restent utilisables sans réseau.

Organisation du code (`lib/`) :

```
core/       thème, formats, navigation, liste des rubriques
models/     classes de données (PricePoint, SimulationResult…)
logic/      calculs en pur Dart, sans Flutter : testables
data/       API, base SQLite (DAO), repository, chargement des fichiers JSON
providers/  état de l'application (ChangeNotifier)
screens/    écrans, rangés par rubrique
widgets/    composants réutilisables (ciel animé, verre, graphiques…)
```

Explication détaillée du code et questions possibles pour la soutenance : [docs/EXPLICATIONS_CODE.md](docs/EXPLICATIONS_CODE.md).

## Lancer le projet

1. Créer une clé gratuite sur Twelve Data.
2. Copier `env.example.json` en `env.json` et y mettre la clé (`env.json` n'est jamais commité).
3. Lancer :

```bash
flutter pub get
```

```bash
flutter run --dart-define-from-file=env.json
```

Tests unitaires et de widgets :

```bash
flutter test
```

## Limites

Cours quotidiens dans la devise d'origine (souvent USD), ajustés des divisions d'actions ; pas de frais ni de dividendes. Offre gratuite Twelve Data : 8 requêtes/minute, 800/jour (le cache évite de redemander une période déjà téléchargée). Pas de compte utilisateur ni de synchronisation entre appareils.
