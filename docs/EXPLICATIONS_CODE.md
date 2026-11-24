# SharesKnowledge — Explication du code et préparation de la soutenance

Ce document explique comment l'application est construite, détaille les parties les plus délicates du code et propose des questions qui peuvent tomber à l'oral, avec des pistes de réponse.

---

## 1. Vue d'ensemble

### Les couches

```
écran (screens/, widgets/)
   │  lit l'état avec context.watch / context.read
   ▼
provider (providers/)          ← ChangeNotifier : garde l'état, prévient l'écran
   │
   ▼
logique (logic/)               ← pur Dart : calculs, aucune dépendance à Flutter
   │
   ▼
données (data/)                ← API REST, SQLite (DAO), repository, fichiers JSON
   │
   ▼
modèles (models/)              ← classes de données (PricePoint, SimulationResult…)
```

Règle suivie partout : **un écran ne fait jamais de calcul ni de requête lui-même**. Il demande au provider, qui utilise la logique et les données. C'est ce qui permet de tester les calculs sans lancer l'application (`test/logic/`).

### Ce qui se passe au lancement (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()` : obligatoire avant d'utiliser un plugin (SQLite, SharedPreferences) avant `runApp`.
2. Ouverture de la base SQLite (`AppDatabase.open()`), des préférences, chargement des fichiers JSON embarqués (scénarios Foresight, partie Past Trader, actualités).
3. Création du `PriceRepository` (API Twelve Data + cache SQLite).
4. `MultiProvider` rend tous ces objets accessibles à tous les écrans.
5. `SharesKnowledgeApp` (`lib/app.dart`) configure le thème, la langue française et affiche `MainShell`.

### La coquille (`lib/screens/home/main_shell.dart`)

- Garde l'onglet sélectionné (`_selectedIndex`).
- `IndexedStack` : tous les écrans des onglets restent en mémoire, un seul est affiché. Changer d'onglet ne fait donc pas perdre ce qu'on a saisi dans le formulaire.
- Au premier démarrage (`introSeen` faux), ouvre l'enchaînement : profil → démonstration Foresight → introduction. `addPostFrameCallback` attend la fin du premier affichage, car on ne peut pas naviguer pendant la construction d'un widget.
- Annonce les médailles gagnées (une seule fois chacune).

---

## 2. Les parties les plus compliquées

### 2.1 L'animation soleil / lune (`lib/widgets/sky_header.dart`)

**Principe** : un `AnimationController` produit une valeur `t` qui va de 0 à 1. Un tour complet (0 → 1) = midi → coucher → nuit → lever → midi. Tout le ciel est dessiné à la main sur un `Canvas` grâce à un `CustomPainter`.

**Étape 1 — transformer `t` en moment de la journée**

```dart
double dayPhase(double t) => (0.25 + t) % 1.0;
```

On décale de 0,25 pour que le repos (t = 0) soit midi. Ensuite : 0 = lever, 0,25 = midi, 0,5 = coucher, 0,75 = minuit. Le `% 1.0` (modulo) ramène la valeur entre 0 et 1.

**Étape 2 — la luminosité**

```dart
double skyBrightness(double phase) => sin(2 * pi * phase);
```

Un sinus fait un tour complet quand `phase` va de 0 à 1 : il vaut 1 à midi (plein jour), 0 au lever et au coucher (crépuscule), −1 à minuit (pleine nuit). Une seule fonction donne donc la lumière à tout moment.

**Étape 3 — la position de l'astre** (`celestialPosition`)

- La première moitié de la phase, c'est le soleil ; la seconde, la lune. Dans chaque moitié, `along` va de 0 à 1.
- `x` avance de gauche à droite (10 % → 90 % de la largeur).
- `y = 0.9 − 0.75 × sin(π × along)` : le sinus d'un demi-tour monte puis redescend, ce qui dessine un **arc**. L'astre se lève, passe en haut, se couche.

**Étape 4 — les couleurs** (`skyColors`)

`Color.lerp(a, b, x)` mélange deux couleurs (x = 0 → a, x = 1 → b). Le jour, on mélange les couleurs du crépuscule et du jour selon la luminosité ; la nuit, celles du crépuscule et de la nuit.

**Étape 5 — le dessin** (`SkyPainter.paint`), dans l'ordre (comme des calques) :

1. dégradé du ciel (haut → horizon) ;
2. lueur orangée sur l'horizon au lever/coucher (`dusk = 1 − |light|`, maximal au crépuscule) ;
3. étoiles la nuit : `Random(42)` utilise toujours la même graine, donc les étoiles sont **au même endroit à chaque image** (sinon elles sauteraient partout) ; leur opacité varie avec un sinus pour scintiller ;
4. soleil (halo, 12 rayons qui tournent avec `t`, disque en dégradé radial) ou lune (halo, disque, 3 cratères) ;
5. deux collines en courbes de Bézier (`quadraticBezierTo`), plus sombres que l'horizon ;
6. un liseré blanc semi-transparent (effet verre).

**Le halo hors de la carte** : `SkyGlowPainter` dessine un grand dégradé radial dans un `Positioned` plus grand que la carte, avec `Clip.none` pour qu'il déborde et éclaire le fond de la page.

**Pourquoi c'est efficace** : `super(repaint: cycle)` dans le peintre. Le peintre s'abonne directement au contrôleur : à chaque image, **seul le dessin est refait**, sans reconstruire les widgets (pas de `setState` 60 fois par seconde).

**Qui fait tourner le ciel ?** L'écran qui l'affiche (rejeu Playground, Foresight, Past Trader) :
- appui sur +1 jour / +7 jours / +1 mois : `_sky.forward(from: 0)` → un tour, d'une durée qui dépend du saut (600 / 900 / 1200 ms) ;
- lecture automatique : `_sky.repeat()` → le ciel tourne en boucle (un tour toutes les 2 s, quelle que soit la vitesse de lecture, sinon on verrait 46 nuits par seconde) ;
- pause : `_sky.forward()` → le ciel **finit son tour** et s'arrête à midi au lieu de rester figé en pleine nuit.

### 2.2 Les trois animations du rejeu (`lib/screens/playground/replay_screen.dart`)

| Animation | Type | Rôle |
| --- | --- | --- |
| `_sky` | programmée (`AnimationController`) | cycle soleil/lune |
| `_reveal` | programmée (`AnimationController` + `Tween`) | le graphique se dessine point par point jusqu'à la nouvelle date |
| `AnimatedMoney` | implicite (`TweenAnimationBuilder`) | le montant défile jusqu'à sa nouvelle valeur |

Plus un quatrième contrôleur, `_playback`, pour la **lecture automatique** : sa valeur 0 → 1 représente la position dans la période. À chaque image, `_onPlaybackFrame` calcule `jour = valeur × nombre de jours` et place la date dessus.

Points importants :
- `TickerProviderStateMixin` fournit le `vsync` : un signal à chaque image de l'écran, coupé quand l'écran n'est pas visible (économie de batterie).
- `dispose()` libère les contrôleurs, sinon ils continueraient de tourner après la fermeture de l'écran (fuite de mémoire).
- Appuis rapides : `_revealCount.evaluate(_reveal)` récupère le nombre de points **actuellement affichés** pour repartir de là, même si l'animation précédente n'était pas finie.
- `AnimatedBuilder` ne reconstruit que le graphique à chaque image, pas tout l'écran.
- Le réglage « Supprimer les animations » du téléphone (`MediaQuery.disableAnimations`) et l'interrupteur du profil sont respectés : on saute directement à la valeur finale.

**Différence animation implicite / explicite** : avec `TweenAnimationBuilder` (implicite) on donne seulement la valeur d'arrivée, Flutter anime tout seul depuis l'ancienne valeur, sans contrôleur à créer ni à libérer. Avec `AnimationController` (explicite), on décide quand démarrer, arrêter, répéter, revenir en arrière.

### 2.3 Le cache des cours et le hors connexion (`lib/data/repositories/price_repository.dart`)

Idée clé : **un cours passé ne change jamais**. Une période déjà téléchargée n'est donc jamais redemandée.

Pour chaque actif, la table `price_coverage` mémorise la période déjà en cache (`from`, `to`) et la date du téléchargement. Quand l'écran demande des cours :

1. **Tout est en cache** (`coverage.covers(from, to)`) → lecture SQLite, aucune requête.
2. **Il manque des jours** → on ne télécharge que le morceau avant et/ou après la période connue (`_downloadMissing`). La période couverte reste toujours d'un seul tenant.
3. **Le réseau échoue** (pas de connexion, quota dépassé) → on renvoie ce qu'on a en cache avec `isFallback = true`, et l'écran affiche un avertissement. S'il n'y a rien en cache, l'erreur remonte à l'écran.

Détails :
- On s'arrête à **hier** : le cours du jour n'est pas définitif pendant la séance.
- L'API renvoie au plus 5 000 cours par appel. Si on atteint la limite, on ne déclare couvert qu'à partir du plus ancien cours reçu.
- L'enregistrement se fait dans une **transaction** (tout ou rien) et avec un **batch** (toutes les insertions envoyées d'un coup, beaucoup plus rapide).
- Requêtes avec `?` (`whereArgs`) : protège de l'injection SQL.
- La clé primaire `(symbol, date)` empêche les doublons.

### 2.4 L'appel à l'API et la conversion JSON (`lib/data/api/twelve_data_api.dart`)

1. Construction de l'URL avec `Uri.https` (les paramètres sont encodés automatiquement).
2. `_client.get(uri).timeout(15 s)`.
3. Traduction des erreurs en exceptions de l'application (`NetworkException`, `QuotaExceededException`, `InvalidApiKeyException`, `NoDataException`, `BadResponseException`).
4. **Piège de Twelve Data** : une erreur peut arriver avec le code HTTP 200 ; le vrai code est dans le corps (`{"status":"error","code":429}`). On le vérifie donc aussi.
5. `jsonDecode` → `Map<String, dynamic>` → `PricePoint.fromJson` pour chaque élément de `values`.

Le client HTTP et l'horloge sont passés en paramètre : dans les tests on donne un faux serveur et une fausse date.

La clé API est injectée à la compilation (`--dart-define-from-file=env.json`, lue par `String.fromEnvironment`) et `env.json` est dans le `.gitignore` : elle n'est jamais commitée.

### 2.5 Les états chargement / données / erreur (`lib/providers/playground/playground_provider.dart`)

```dart
sealed class PlaygroundState {}
class PlaygroundIdle    extends PlaygroundState {}
class PlaygroundLoading extends PlaygroundState {}
class PlaygroundSuccess extends PlaygroundState {}
class PlaygroundFailure extends PlaygroundState {}
```

`sealed` oblige l'écran à traiter **tous** les cas dans son `switch` : si on en oublie un, le code ne compile pas. Le provider appelle `notifyListeners()` à chaque changement, et les écrans qui font `context.watch<PlaygroundProvider>()` se reconstruisent.

### 2.6 Les calculs métier (`lib/logic/`)

**Baisse maximale** (`drawdown.dart`) — la plus forte chute depuis un sommet :
on parcourt les valeurs en retenant le plus haut sommet vu jusqu'ici ; à chaque point, `baisse = (sommet − valeur) / sommet` ; on garde la plus grande. Exemple : 100 → 150 → 90 → 200 → 180 donne 40 % (de 150 à 90).

**Rendement composé** (`returns.dart`) : `capital × (1 + taux)^années`. Chaque année, les gains précédents rapportent aussi. Comparé aux intérêts simples `capital × (1 + taux × années)`.

**Rendement annualisé** : `(final / investi)^(1 / années) − 1`. Non calculé sous un an (ramener 3 mois à « par an » exagérerait).

**Volatilité** (`risk.dart`) : écart type des rendements d'une période à l'autre. On divise par `n − 1` (écart type d'échantillon).

**Gain nécessaire après une perte** : `1 / (1 − perte) − 1`. Après −50 %, il faut +100 % pour revenir au départ.

**Simulation Playground** (`playground/simulator.dart`) :
- versement unique : `parts = montant / cours d'achat`, puis `valeur = parts × cours` chaque jour ;
- versements mensuels (DCA) : chaque mois, le même montant achète plus de parts quand le cours est bas. La baisse maximale est calculée sur le **cours** et non sur la valeur, car chaque versement ferait monter la valeur et masquerait les chutes ;
- achat au premier jour de bourse à partir de la date choisie (un samedi → le lundi), vente au dernier jour de bourse avant la fin.

### 2.7 La tête de lecture du temps (`lib/logic/time_cursor.dart`)

`TimeCursor` ne connaît que la date courante ; le prix est retrouvé dans la série (`lastOnOrBefore` : dernier cours connu, utile le week-end). Utilisé par le rejeu, Foresight et Past Trader.

Piège des mois : ajouter un mois au 31 janvier ne doit pas donner le 3 mars. `addStep` calcule le dernier jour du mois suivant avec `DateTime.utc(année, mois + 2, 0)` (le jour 0 d'un mois = le dernier jour du mois précédent) et se limite à ce jour.

La vitesse de lecture automatique s'adapte à la période : `10 s + 1 s par tranche de 60 jours`, entre 15 et 60 s.

### 2.8 La base SQLite et ses versions (`lib/data/local/app_database.dart`)

- `onCreate` : appelé une seule fois, crée toutes les tables.
- `onUpgrade` : appelé quand l'application déjà installée a une base plus ancienne. On ajoute seulement ce qui manque (`if (oldVersion < 2) …`), sans effacer le cache. Historique : v1 cache des cours, v2 simulations sauvegardées, v3 parties Past Trader, v4 portefeuille.
- Les dates sont stockées en texte `AAAA-MM-JJ` : lisible, et l'ordre alphabétique est aussi l'ordre chronologique.

### 2.9 La barre du bas qui cache ses libellés (`main_shell.dart`)

Un `NotificationListener<ScrollNotification>` écoute les défilements de n'importe quelle liste en dessous de lui :
- défilement vers le bas de plus de 3 px (et pas tout en haut) → libellés masqués ;
- défilement vers le haut ou retour tout en haut → libellés réaffichés ;
- `return false` : la notification continue de remonter (on ne la « consomme » pas).

`RouteAware` + `didPopNext` : quand on revient sur la coquille après avoir fermé une page (profil, leçon…), les libellés réapparaissent.

### 2.10 Les médailles (`lib/logic/progress/medals.dart`)

Rien n'est enregistré pour les médailles : elles sont **déduites** de la progression (leçons faites, simulations, parties). Une remise à zéro de la progression les retire donc automatiquement. Seule la liste des médailles déjà annoncées est mémorisée, pour ne pas afficher deux fois le message.

### 2.11 L'effet verre (`lib/widgets/glass.dart`)

`ClipRRect` (forme arrondie) + `BackdropFilter(ImageFilter.blur(...))` : floute ce qui est **derrière** le widget, comme une vitre dépolie.

### 2.12 Les graphiques : la bulle au toucher et la répartition

Tous les graphiques en courbe (Playground, Past Trader, portefeuille, Foresight, leçons) utilisent le même outil, `chartTouch` (`lib/widgets/chart_touch.dart`) : en touchant ou en glissant le doigt, une bulle affiche la date et la valeur du point le plus proche. Chaque graphique ne fournit que le texte de sa bulle ; renvoyer `null` masque une courbe (par exemple les points des ordres dans le bilan Past Trader).

Le portefeuille affiche aussi sa **répartition** (`lib/widgets/wallet/allocation_chart.dart`) : un `PieChart` avec un trou au centre (un anneau), une part par position et le cash en gris, la légende en pourcentages. En touchant une position, son détail montre le cours depuis l'achat, avec le **prix moyen d'achat** en pointillés : au-dessus, la position gagne ; en dessous, elle perd.

### 2.13 Stop-loss et objectif (`lib/models/position_rule.dart`)

Une seule règle sert au portefeuille et à Past Trader : `stopLoss` (0,2 = vendre si le cours perd 20 % par rapport au prix moyen d'achat) et `takeProfit` (0,5 = vendre s'il en gagne 50 %). `triggerAt` compare le cours de clôture au prix moyen d'achat. La fenêtre de saisie est commune aussi (`lib/widgets/rule_sheet.dart`).

---

## 3. Parties réalisées avec l'aide de l'IA

À présenter honnêtement comme telles (voir le README). Les idées principales à savoir expliquer :

**Past Trader** (`lib/logic/past_trader/trading.dart`, `TraderGame`)
- Le temps n'avance que vers l'avant : impossible d'annuler une décision après avoir vu la suite.
- `visiblePrices` ne renvoie que les cours **jusqu'à la date courante** ; `NewsFeed.until(date)` ne révèle jamais une actualité future.
- Un ordre s'exécute au cours de clôture du jour, seulement si l'actif est coté ce jour-là.
- Prix de revient moyen pondéré (`cost / units`) pour calculer la plus-value à la vente, puis l'impôt selon la durée de détention.
- Stop-loss et objectif (voir 2.13) : chaque jour traversé, `_applyRules` vend toute la position si un seuil est franchi au cours de clôture ; la vente garde la règle qui l'a déclenchée (« Stop-loss » dans l'onglet Ordres).
- En lecture automatique, `advanceTo(date, stopAtMajorNews: true)` s'arrête au jour de la première **grande** nouvelle : le flash info s'affiche et la lecture ne reprend que si le joueur appuie sur lecture. Il peut ainsi vendre avant que la nouvelle ne fasse son effet ; les petites nouvelles, elles, défilent sans arrêter la lecture.
- Changer la vitesse (lent / moyen / rapide) pendant la lecture s'applique tout de suite : la lecture repart du jour courant à la nouvelle vitesse.
- Une partie quittée est enregistrée sous forme de **journal de décisions** (avancer, acheter, vendre, poser une règle) : « Reprendre » le rejoue. Les ventes automatiques ne sont pas dans le journal : elles se redéclenchent d'elles-mêmes, puisque les cours sont fixes.
- Données : cours réels 2018-2020 téléchargés une fois par un script (`tool/build_past_trader.dart`) et embarqués dans l'application ; actualités rédigées avec une IA à partir d'événements réels.

**Perfect Foresight** (`lib/logic/foresight/foresight.dart`, `ForesightRun`)
- Le scénario est une suite d'étapes « acheter tel actif tel jour, revendre tel jour ». Le calcul enchaîne les étapes en réinvestissant le capital.
- Impôt prélevé à chaque vente, retraits mensuels de 4 % par an plafonnés (montant indexé sur l'inflation), réserve plafonnée : ce qui dépasse est mis à l'abri.
- `PlaybackTimeline` donne à chaque étape un temps d'écran proportionnel à sa durée (entre 4 et 15 s), pour que la lecture ne passe pas trop vite sur les étapes courtes.
- Données : parcours proposés par GPT (`docs/foresight_gpt/`), puis vérifiés et générés avec les vrais cours (`tool/build_foresight_scenario.dart`, `tool/find_best_window.dart`).
- But pédagogique : montrer le **biais rétrospectif** — le résultat est énorme, mais impossible à obtenir sans connaître le futur.

---

## 4. Questions possibles à l'oral

### Animations

**Comment fonctionne l'animation soleil/lune ?**
Un `AnimationController` produit une valeur de 0 à 1. Je la transforme en moment de la journée (`dayPhase`), puis en luminosité avec un sinus (1 à midi, −1 à minuit). La position de l'astre suit un arc calculé avec un sinus. Un `CustomPainter` dessine le ciel en dégradé, les étoiles, le soleil ou la lune et les collines. Le peintre est abonné au contrôleur (`repaint: cycle`), donc seul le dessin est refait à chaque image.

**Pourquoi les étoiles ne bougent pas d'une image à l'autre alors qu'elles sont aléatoires ?**
`Random(42)` : même graine, donc même suite de nombres, donc mêmes positions à chaque image.

**Que se passe-t-il quand on met pause pendant la nuit ?**
`_sky.forward()` laisse le ciel finir son tour jusqu'à t = 1, c'est-à-dire midi.

**Différence entre animation implicite et explicite ?**
Implicite (`TweenAnimationBuilder`) : on donne la valeur cible, Flutter anime seul. Explicite (`AnimationController`) : on contrôle démarrage, arrêt, répétition, durée.

**À quoi sert `vsync` / `TickerProviderStateMixin` ?**
À recevoir un signal à chaque image de l'écran, et à l'arrêter quand l'écran n'est pas visible.

**Pourquoi `dispose()` ?**
Pour libérer les contrôleurs : sinon fuite de mémoire et animation qui tourne pour rien.

**Comment l'application respecte-t-elle l'accessibilité ?**
Si le téléphone demande de supprimer les animations (ou l'interrupteur du profil), on saute directement à la valeur finale.

### Données, API, stockage

**Comment fonctionne le cache ?**
Voir 2.3 : une période déjà téléchargée n'est jamais redemandée, seuls les jours manquants le sont ; en cas de panne réseau, on affiche le cache en le signalant.

**Que se passe-t-il sans Internet ?**
Les cours déjà consultés, les sauvegardes, les leçons, Foresight et Past Trader (données embarquées) fonctionnent. Un bandeau indique l'absence de connexion. Une nouvelle simulation sur un actif jamais consulté affiche une erreur avec un bouton pour réessayer.

**Comment convertis-tu le JSON en objets Dart ?**
`jsonDecode` donne une `Map`, puis un constructeur `fromJson` écrit à la main lit chaque champ et le convertit (date, nombre).

**Pourquoi SQLite et pas seulement SharedPreferences ?**
SharedPreferences convient pour quelques réglages (clé → valeur). Pour des milliers de cours avec des requêtes par date, il faut une vraie base avec tables et index.

**Qu'est-ce qu'un DAO ? Un repository ?**
DAO : la seule classe qui contient le SQL d'une table. Repository : décide d'où viennent les données (cache ou API) ; l'écran ne le sait pas.

**Comment protèges-tu ta clé API ?**
Elle est dans `env.json`, ignoré par Git, et injectée à la compilation avec `--dart-define-from-file`.

**Comment gères-tu une mise à jour de l'application qui ajoute une table ?**
Numéro de version de la base + `onUpgrade` qui crée seulement les tables manquantes.

**Pourquoi une transaction pour enregistrer les cours ?**
Si une erreur survient au milieu, rien n'est enregistré : on ne déclare jamais une période couverte alors que ses cours manquent.

### Architecture et état

**Pourquoi `provider` ?**
Simple à expliquer : un `ChangeNotifier` garde l'état, `notifyListeners()` prévient les écrans qui font `context.watch`.

**Différence entre `context.watch` et `context.read` ?**
`watch` reconstruit le widget quand l'état change (dans `build`). `read` lit une fois sans s'abonner (dans un bouton, `initState`).

**Pourquoi un seul outil pour les bulles des graphiques ?**
Pour que tous les graphiques se comportent pareil, et qu'un changement (couleur, taille) ne se fasse qu'à un endroit.

**Pourquoi séparer la logique dans `logic/` ?**
Pur Dart, sans Flutter : testable rapidement, réutilisable par plusieurs écrans.

**StatelessWidget ou StatefulWidget ?**
Stateful quand le widget doit se souvenir de quelque chose qui change (onglet sélectionné, contrôleurs d'animation, saisie du formulaire).

**Pourquoi `IndexedStack` ?**
Garder les écrans des onglets en mémoire : on ne perd pas la saisie en changeant d'onglet.

**Que fait `sealed` ?**
Oblige à traiter tous les états (chargement, succès, erreur, repos) dans le `switch`.

### Calculs

**Comment calcules-tu la baisse maximale ?** Voir 2.6.

**Pourquoi la baisse maximale du DCA est calculée sur le cours ?**
Les versements font monter la valeur et cacheraient les chutes.

**Pourquoi −50 % demande +100 % pour revenir ?**
100 → 50 ; pour revenir à 100 il faut gagner 50, soit 100 % de 50.

**Que se passe-t-il si on choisit un samedi comme date de début ?**
`firstOnOrAfter` prend le premier jour de bourse suivant (le lundi).

**Comment ajoutes-tu un mois au 31 janvier ?** Voir 2.7.

### Tests

**Que testes-tu ?**
Les calculs (`test/logic/`), la conversion JSON, le client API avec un faux serveur, le repository et le cache avec une base SQLite en mémoire (`sqflite_common_ffi`), les providers et certains écrans (tests de widgets).

**Comment testes-tu l'API sans Internet ?**
Le client HTTP est passé en paramètre : dans le test, on donne un faux client qui renvoie un JSON préparé.

### IA et honnêteté

**Qu'as-tu fait toi-même, et avec l'IA ?**
Tout sauf Past Trader et Perfect Foresight, réalisés avec l'aide de l'IA (code et fichiers de données). Dans l'application, une pastille « AI » le signale. Les cours, eux, sont réels (Twelve Data). La plupart des tests ont aussi été écrits avec l'IA, surtout par manque de temps : je sais expliquer ce qu'ils vérifient et comment ils fonctionnent (faux client HTTP, base en mémoire).

**Comment as-tu vérifié les données générées par l'IA ?**
Les parcours Foresight proposés par GPT ont été recalculés avec les vrais cours Twelve Data par un script ; les actualités Past Trader sont signalées comme rédigées par IA, à lire avec un œil critique.

---

## 5. Notions Flutter et Dart à connaître

Questions de cours qui peuvent tomber, avec à chaque fois un exemple pris dans le projet : un exemple concret montre que tu as compris, pas seulement appris.

### 5.1 Les widgets

**Qu'est-ce qu'un widget ?**
Une description d'un morceau d'interface : un texte, un bouton, une marge, une page entière. En Flutter **tout est widget**, même la mise en page (`Padding`, `Column`, `Center`). On assemble de petits widgets pour en faire de plus gros : c'est l'**arbre de widgets**.

**Pourquoi des widgets ?**
- **Réutilisables** : `SkyHeader` sert dans le rejeu, Foresight et Past Trader ; `Glass` et `AnimatedMoney` un peu partout.
- **Déclaratifs** : on décrit *à quoi l'écran doit ressembler* pour un état donné, et Flutter met l'affichage à jour. On ne modifie jamais un bouton « à la main ».
- **Légers** : un widget est un simple objet de configuration, immuable. En recréer beaucoup ne coûte presque rien : Flutter compare l'ancien et le nouvel arbre et ne redessine que ce qui a changé.

**Les trois arbres (si on pousse la question)** : widgets (la configuration) → éléments (gardent la place dans l'arbre et l'état) → objets de rendu (mesurent et dessinent).

**La méthode `build`**
Renvoie l'arbre de widgets à afficher. Elle peut être appelée très souvent, donc elle doit être rapide et ne faire que construire l'affichage : jamais de requête réseau dans `build`.

**`BuildContext`**
La position du widget dans l'arbre. Il sert à remonter l'arbre pour trouver quelque chose : le thème (`Theme.of(context)`), la navigation (`Navigator.of(context)`), un provider (`context.read<...>()`).

**`const` devant un widget**
Le widget est créé une seule fois à la compilation et réutilisé : Flutter sait qu'il n'a pas changé et ne le reconstruit pas. Petit gain de performance gratuit.

### 5.2 Stateless ou Stateful

| | `StatelessWidget` | `StatefulWidget` |
| --- | --- | --- |
| Mémoire | aucune : l'affichage dépend seulement de ce qu'on lui donne | garde un **état** qui change avec le temps |
| Mise à jour | reconstruit quand son parent change | `setState(() {...})` le reconstruit |
| Exemples du projet | `AnimatedMoney`, `SkyHeader`, `SharesKnowledgeApp` | `MainShell` (onglet choisi), `ReplayScreen` (contrôleurs d'animation), formulaire du Playground |

Règle simple : **Stateless par défaut**, Stateful seulement si le widget doit se souvenir de quelque chose qui change (une saisie, un onglet, une animation).

**`setState`** : prévient Flutter que l'état a changé, ce qui rappelle `build`. À n'appeler que pour un changement visible, et jamais après `dispose`.

**Cycle de vie d'un `State`** :
1. `initState()` : une fois, à la création. On y crée les contrôleurs, on lance un chargement (dans `MainShell` : ouverture du premier démarrage).
2. `didChangeDependencies()` : quand quelque chose dont il dépend change (thème, route). Dans `MainShell` : abonnement au `routeObserver`.
3. `build()` : à chaque affichage.
4. `dispose()` : à la destruction. On libère contrôleurs, abonnements, flux.

**Pourquoi l'état est dans une classe séparée (`State`) ?** Le widget est immuable et recréé souvent ; l'objet `State`, lui, survit entre les reconstructions et garde les valeurs.

**Les `Key`** : aident Flutter à reconnaître un widget quand une liste change d'ordre. `GlobalKey<FormState>` (formulaire du Playground) permet d'appeler `validate()` sur tout le formulaire.

### 5.3 Provider et la gestion d'état

**Le problème** : avec seulement `setState`, l'état vit dans un widget. Si des écrans éloignés ont besoin de la même donnée (le résultat de simulation dans le formulaire et dans l'écran de résultat, les réglages du profil partout), il faudrait la passer de constructeur en constructeur à travers tout l'arbre.

**La solution `provider`** : on place l'objet **au-dessus** de l'arbre (`MultiProvider` dans `main.dart`), et n'importe quel écran en dessous peut le récupérer.

- `ChangeNotifier` : classe qui garde l'état et appelle `notifyListeners()` quand il change (`PlaygroundProvider`, `SettingsProvider`…).
- `context.watch<T>()` : lit **et s'abonne** → le widget se reconstruit à chaque `notifyListeners()`. À utiliser dans `build`.
- `context.read<T>()` : lit **sans s'abonner**. À utiliser dans un bouton, `initState`, un callback.
- `context.select<T, R>(...)` : s'abonne seulement à une partie de l'état.
- `Provider.value` : pour un objet qui ne change pas (le `PriceRepository`, les scénarios chargés).
- `ChangeNotifierProvider(create: ...)` : crée l'objet au premier besoin et le libère tout seul.

**Utilité** :
- séparer l'état et la logique de l'affichage (l'écran ne fait qu'afficher) ;
- partager l'état entre écrans ;
- tester le provider sans interface (`test/providers/`) ;
- **injection de dépendances** : les écrans reçoivent le repository sans le créer eux-mêmes.

**Pourquoi provider et pas Riverpod ou Bloc ?** Recommandé par la documentation Flutter pour débuter, peu de code, suffisant pour la taille du projet. Bloc et Riverpod apportent plus de structure, utile sur de gros projets en équipe.

### 5.4 Les types d'animations

**Implicites** : on donne la valeur d'arrivée, Flutter anime tout seul depuis l'ancienne valeur. Pas de contrôleur.
- `AnimatedContainer` (écran d'introduction, leçon Rendement), `AnimatedOpacity` (libellés de la barre du bas), `AnimatedSwitcher`…
- `TweenAnimationBuilder` : version générique, pour animer n'importe quelle valeur (`AnimatedMoney`).
- Les graphiques `fl_chart` ont aussi une animation implicite (`duration`) : les courbes glissent quand on bouge un curseur dans les leçons.

**Explicites (programmées)** : on pilote l'animation soi-même.
- `AnimationController` : produit une valeur de 0 à 1 sur une durée ; contrôlé par `forward()`, `reverse()`, `repeat()`, `stop()`.
- `vsync` (`TickerProviderStateMixin`) : un signal à chaque image (~60/s), coupé quand l'écran n'est pas visible.
- `Tween` : transforme le 0 → 1 en une autre plage (ex. nombre de points du graphique, de 120 à 150).
- `CurvedAnimation` / `Curves.easeOut` : change le rythme (démarre vite, finit doucement).
- `AnimatedBuilder` : reconstruit seulement la partie qui dépend de l'animation (le graphique du rejeu).
- `CustomPainter` avec `repaint:` : redessine seulement le dessin à chaque image (le ciel).
- Toujours libérer le contrôleur dans `dispose()`.

**Quand choisir laquelle ?**
Implicite quand on passe simplement d'une valeur à une autre. Explicite quand il faut répéter, enchaîner, mettre en pause, synchroniser plusieurs éléments ou dessiner image par image. Exemple : le ciel tourne en boucle pendant la lecture puis finit son tour à la pause, ce qui est impossible avec une animation implicite.

**Autres familles (à citer si on demande)** : transitions entre pages (`MaterialPageRoute`, `Hero`), animations physiques (ressort, inertie du défilement), animations dessinées par des outils (Lottie, Rive).

### 5.5 Mise en page

- `Column` / `Row` : empilent verticalement / horizontalement. `Expanded` prend la place restante.
- `Stack` : superpose (le texte posé sur le ciel, le halo sous la carte). `Positioned` place un enfant précisément.
- `Padding`, `SizedBox`, `Center` : marges, taille, centrage.
- `ListView` : liste qui défile. `ListView.builder` ne construit **que les lignes visibles** : indispensable pour une longue liste (catalogue d'actifs, ordres Past Trader).
- `Scaffold` : la structure d'une page Material (barre du haut, corps, barre du bas, `SnackBar`).
- Contraintes : le parent donne une taille min/max à l'enfant, l'enfant choisit sa taille dedans, le parent le place. C'est l'origine des erreurs « overflow » (bandes jaunes et noires).

### 5.6 Navigation

- `Navigator.push(MaterialPageRoute(...))` empile une nouvelle page ; `Navigator.pop` revient en arrière.
- `pushReplacement` remplace la page (premier démarrage : profil → Foresight sans pouvoir revenir au profil).
- Les onglets du bas ne sont pas des pages empilées : c'est un `IndexedStack` qui change d'enfant affiché.
- `RouteObserver` / `RouteAware` : être prévenu quand une page au-dessus se ferme (`didPopNext`).

### 5.7 Asynchrone

- `Future<T>` : une valeur qui arrivera plus tard (réponse de l'API, lecture SQLite).
- `async` / `await` : écrire du code asynchrone comme du code normal ; `await` attend sans bloquer l'interface.
- `try` / `catch` autour des `await` pour gérer les erreurs réseau.
- `Stream<T>` : une suite de valeurs dans le temps (changements de connexion dans `ConnectivityProvider`). On s'y abonne avec `listen` et on annule l'abonnement dans `dispose`.
- `FutureBuilder` : affiche un contenu différent selon l'état du `Future` (chargement / données / erreur) ; utilisé pour le catalogue d'actifs.
- Dart est **mono-thread** avec une boucle d'événements : un calcul très long bloquerait l'interface (on utiliserait alors un `Isolate`).
- `mounted` : vérifier que l'écran existe encore après un `await`, avant d'appeler `setState` ou d'utiliser le `context`.

### 5.8 Dart : le langage

- **Null safety** : `String?` peut être null, `String` jamais. `!` force (« je sais que ce n'est pas null »), `??` donne une valeur par défaut, `?.` n'appelle que si non null.
- `var` (type déduit, modifiable), `final` (affecté une seule fois, à l'exécution), `const` (connu à la compilation).
- `late` : initialisé plus tard, au premier usage (les `AnimationController` de `ReplayScreen`, qui ont besoin de `this`).
- `required` : paramètre nommé obligatoire.
- `sealed class` + `switch` : le compilateur vérifie que tous les cas sont traités (états du Playground).
- **Records** `(a, b)` / `({int year, double value})` : regrouper quelques valeurs sans créer de classe (`skyColors` renvoie deux couleurs).
- `extends` (héritage), `with` (mixin : ajouter un comportement, ex. `TickerProviderStateMixin`), `implements` (respecter une interface).
- Fonctions passées en paramètre : `DateTime Function() now` dans le repository, pour remplacer l'horloge dans les tests.

### 5.9 JSON, API, stockage

- `jsonDecode` transforme le texte en `Map<String, dynamic>` / `List` ; `fromJson` construit l'objet Dart ; `toJson` fait l'inverse (paramètres des simulations sauvegardées).
- Conversion écrite à la main plutôt que générée (`json_serializable`) : moins de magie, plus facile à expliquer.
- HTTP : requête `GET` avec les paramètres dans l'URL ; codes 200 (OK), 401/403 (clé refusée), 404 (introuvable), 429 (trop de requêtes).
- `shared_preferences` : petites valeurs clé → valeur. SQLite (`sqflite`) : données nombreuses et structurées, requêtes SQL.
- **Repository** : décide d'où viennent les données. **DAO** : contient le SQL d'une table.

### 5.10 Projet, outils, tests

- `pubspec.yaml` : nom, version, dépendances (packages de pub.dev) et fichiers embarqués (`assets`, police d'icônes).
- **Hot reload** : injecte le code modifié en gardant l'état (rapide). **Hot restart** : relance l'app, l'état est perdu.
- **Debug / release** : en debug, Dart est compilé à la volée (JIT) pour permettre le hot reload, donc plus lent (démarrage ~20 s sur l'émulateur) ; en release, il est compilé en code machine à l'avance (AOT), donc rapide.
- **Un seul code** pour Android et iOS : Flutter dessine lui-même ses widgets avec son moteur de rendu, il n'utilise pas les composants natifs.
- **Material** : la bibliothèque de composants de Google (`ThemeData`, `Scaffold`, boutons). Le thème est centralisé dans `core/theme.dart`.
- Tests :
  - **unitaires** : une fonction ou une classe seule (`test/logic/`) ;
  - **de widgets** : un écran affiché dans un environnement de test, on simule des appuis (`testWidgets`, `tester.tap`, `find.text`) ;
  - **d'intégration** : l'app entière sur un vrai appareil (non faits ici).
- **Faux objets (fakes)** : un faux client HTTP, une base en mémoire, une fausse date, pour des tests rapides et sans réseau.
- **Séparation des responsabilités** : chaque couche a un seul rôle ; changer d'API ne toucherait que `data/`.
