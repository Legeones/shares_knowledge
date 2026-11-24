# Script de démo — SharesKnowledge

Durée visée : **10 à 12 minutes** de démo, puis les questions.
Légende : **▶ Faire** = ce que tu touches à l'écran · **💬 Dire** = rappels à formuler avec tes mots (pas à lire).

---

## 0. Préparation (avant d'entrer dans la salle)

- [ ] Émulateur lancé **à l'avance** : le premier démarrage en debug prend ~20 s avant de réagir aux appuis.
- [ ] App lancée avec la clé : `flutter run --dart-define-from-file=env.json` (ou un build release, plus fluide).
- [ ] Internet actif sur l'émulateur.
- [ ] **Pré-charger le cache** : lancer une fois la simulation de la démo (ex. Apple, 1 000 $, 2015 → 2024). Elle servira pour la partie hors connexion.
- [ ] Choisir : montrer le **premier démarrage** (profil → Perfect Foresight) ou non. Si oui : Profil → « Tout remettre à zéro » n'efface pas l'intro ; le plus simple est de désinstaller/réinstaller l'app avant la démo (le cache des cours sera alors vide : refaire la pré-simulation).
- [ ] Une partie Past Trader **déjà avancée** de quelques mois (pour ne pas attendre en direct), et une partie terminée pour montrer un bilan.
- [ ] Animations activées (Profil : interrupteur « Réduire les animations » désactivé).
- [ ] Plan B : une courte vidéo d'écran de la démo, au cas où l'émulateur ou le réseau lâche.

---

## 1. Introduction — 1 min

**▶ Faire** : rien encore, l'app est ouverte sur l'accueil.

**💬 Dire**
- SharesKnowledge : application Flutter pour **apprendre l'investissement en manipulant de vraies données historiques**, sans argent réel, sans compte, sans courtier.
- Public : débutants. Le but est de comprendre, pas de prédire : un résultat passé ne prédit pas l'avenir.
- Données réelles : API REST **Twelve Data** (cours de clôture quotidiens).
- 4 rubriques, chacune répond à une question : Learn, Foresight, Past Trader, Playground.
- Honnêteté dès le début : **fait à la main**, sauf **Past Trader et Perfect Foresight** (réalisés avec l'aide de l'IA, code et données) et **la plupart des tests** (IA, par manque de temps). Une pastille « AI » le signale dans l'app.

---

## 2. Premier démarrage (facultatif) — 1 min

**▶ Faire** : écran « Faisons connaissance » → année de naissance + situation fiscale → Continuer.

**💬 Dire**
- Deux questions seulement, **tout reste sur le téléphone** (pas de compte, pas de base distante : choix assumé).
- L'année de naissance sert à proposer la décennie de tes 25 ans dans Foresight ; la fiscalité sert au calcul des impôts.
- Stocké avec `shared_preferences` (réglages simples clé → valeur).

---

## 3. Accueil et navigation — 30 s

**▶ Faire** : montrer l'accueil (bonjour, progression, « Reprendre »), faire défiler → les libellés de la barre du bas se cachent ; remonter → ils reviennent. Toucher les onglets.

**💬 Dire**
- Barre de navigation à 5 onglets, construite à partir d'**une seule liste de rubriques** (`sections.dart`) : renommer une rubrique se fait à un seul endroit.
- `IndexedStack` : les écrans restent en mémoire, on ne perd pas sa saisie en changeant d'onglet.
- Libellés cachés au défilement : `NotificationListener<ScrollNotification>`.
- Thème « verre » : flou d'arrière-plan avec `BackdropFilter`.

---

## 4. Playground — le cœur du projet — 3 min

### 4.1 Formulaire

**▶ Faire** : onglet Playground → Simulateur → toucher « Actif » → **liste filtrable**, chercher « Apple » → choisir. Montant 1 000, dates 2015 → 2024.
Montrer une **erreur de validation** : vider le montant ou mettre la date de fin avant le début → message.
Puis basculer « En une fois » / « Chaque mois » pour montrer le DCA.

**💬 Dire**
- Formulaire validé : montant > 0, dates cohérentes, actif choisi.
- Liste dynamique : catalogue d'actifs chargé depuis un fichier JSON embarqué, filtrable.
- Deux modes : versement unique, ou **versements mensuels (DCA)**.

### 4.2 Résultat

**▶ Faire** : « Lancer la simulation » → (chargement) → résultat : valeur finale, gain, performance, baisse maximale, graphique.

**💬 Dire**
- Trois états gérés explicitement : **chargement, données, erreur** (classe `sealed` : impossible d'en oublier un).
- Calculs métier en pur Dart (`logic/`), testés : gain, performance, **baisse maximale** (plus forte chute depuis un sommet), rendement annualisé.
- Dates ajustées aux jours de bourse : un samedi devient le lundi.
- Graphique avec `fl_chart` : cours et valeur, zone de la baisse maximale.
- Hypothèses affichées : pas de frais, pas de dividendes, devise de l'actif.

### 4.3 Rejeu animé — le moment « waouh »

**▶ Faire** : ouvrir le **Rejeu** → appuyer +1 jour, +7 jours, +1 mois → puis **Lecture** → puis **Pause** (le ciel finit son tour et s'arrête à midi).

**💬 Dire**
- Trois animations, dont deux programmées :
  1. **cycle soleil/lune** (`AnimationController` + `CustomPainter`) : une valeur de 0 à 1 devient une heure de la journée, un sinus donne la luminosité, l'astre suit un arc ;
  2. **révélation du graphique** point par point (`AnimationController` + `Tween`) ;
  3. **compteur du montant** (`TweenAnimationBuilder`, animation implicite).
- Le ciel est redessiné à chaque image **sans reconstruire les widgets** (`repaint: cycle`).
- Accessibilité : si le téléphone demande moins d'animations, on saute directement au résultat.

### 4.4 Sauvegarde

**▶ Faire** : « Sauvegarder » → nommer → ouvrir la liste des simulations sauvegardées (depuis le profil).

**💬 Dire**
- Persistance dans **SQLite** (`sqflite`), via un DAO : la seule classe qui contient le SQL de cette table.

---

## 5. Cache et hors connexion — 1 min 30

**▶ Faire**
1. Relancer la même simulation Apple → **instantané** (aucune requête).
2. Couper le réseau de l'émulateur (mode avion) → le **bandeau hors connexion** apparaît.
3. Relancer la simulation Apple → **elle marche** grâce au cache.
4. Essayer un actif jamais consulté → **message d'erreur + « Réessayer »**.
5. Remettre le réseau.

**💬 Dire**
- Idée clé : **un cours passé ne change jamais**. Une période déjà téléchargée n'est jamais redemandée ; seuls les jours manquants le sont.
- Le **repository** décide : cache ou API. L'écran ne sait pas d'où viennent les données.
- Si le réseau tombe, on affiche ce qu'on a en cache **en le signalant**.
- Important avec l'offre gratuite Twelve Data : 8 requêtes/min, 800/jour.
- Clé API jamais dans le code : `env.json` ignoré par Git, injecté à la compilation.

---

## 6. Learn — 1 min

**▶ Faire** : onglet Learn → ouvrir « Rendement composé » (ou Baisse maximale) → bouger un curseur → le graphique réagit → répondre à la question → leçon « Terminée ».

**💬 Dire**
- Leçons courtes : une situation, des curseurs, un graphique qui réagit, une question.
- Notions : rendement, rendement composé, volatilité, baisse maximale, DCA, diversification.
- Exemple à citer : après **−50 %, il faut +100 %** pour revenir au départ.
- Progression enregistrée, visible sur l'accueil.

---

## 7. Perfect Foresight *(fait avec l'aide de l'IA)* — 1 min 30

**▶ Faire** : onglet Foresight (montrer la pastille **AI**) → choisir une décennie → Lecture → laisser un chapitre s'afficher → aller au bilan → « Pourquoi c'est impossible ».

**💬 Dire**
- Question : *que gagnerait-on en connaissant le futur ?* 1 000 $ déplacés vers les bons actifs aux bons jours.
- Résultat énorme… **impossible à reproduire** : biais rétrospectif, timing au jour près (vendre un jour trop tard change tout), chutes vertigineuses en chemin.
- Réalisme : impôts du profil, retraits pour vivre, inflation.
- Parcours proposés par une IA (GPT) **puis vérifiés avec les vrais cours** Twelve Data par un script.

---

## 8. Past Trader *(fait avec l'aide de l'IA)* — 1 min 30

**▶ Faire** : onglet Past Trader → lire vite les règles → « Reprendre la partie » (préparée à l'avance) → onglet Marché, acheter un actif → avancer le temps → une actualité tombe → « Arrêter et voir le bilan » (ou ouvrir une partie terminée).

**💬 Dire**
- L'inverse de Foresight : *qu'aurais-je décidé sans connaître la suite ?*
- 2018-2020, 10 000 $, 16 actifs réels. **Aucun cours futur n'est jamais affiché**, aucune actualité future non plus.
- Le temps n'avance que vers l'avant : pas d'annulation.
- Bilan comparé à des stratégies simples (tout en S&P 500, tout en cash) : battre l'indice est difficile.
- Actualités rédigées avec l'IA à partir d'événements réels — à lire avec un œil critique.

---

## 9. Progression, médailles, profil — 30 s

**▶ Faire** : avatar → Profil → « Ma progression » → médailles.

**💬 Dire**
- Les médailles récompensent **la curiosité et la régularité, jamais le montant des gains**.
- Elles ne sont pas stockées : elles sont **déduites** de la progression.

*(Si le temps le permet : « Mon portefeuille » dans le Playground — portefeuille fictif qui avance avec les vrais cours à partir d'aujourd'hui.)*

---

## 10. Conclusion — 1 min

**💬 Dire**
- Récap des exigences couvertes : plusieurs écrans + navigation, formulaire validé, liste dynamique, API REST + JSON, SQLite, cache, hors connexion, états chargement/données/erreur, graphiques, calculs métier, 3 animations, tests unitaires (~400), séparation en couches.
- Architecture : `models` / `logic` (pur Dart, testable) / `data` (API, SQLite, repository) / `providers` / `screens`.
- Ce que j'ai appris : séparer la logique de l'interface, gérer les erreurs réseau, le cache, les animations.
- Limites : pas de frais ni dividendes, quota de l'API, pas de synchronisation entre appareils.
- Pistes : plus de leçons, d'autres périodes Past Trader.
- « Merci, je suis prêt pour vos questions. » → les réponses types sont dans [EXPLICATIONS_CODE.md](EXPLICATIONS_CODE.md), section 4.

---

## Si quelque chose plante

| Problème | Réaction |
| --- | --- |
| Pas de réseau / quota dépassé | Parfait pour montrer le cache : enchaîner sur la partie 5 avec la simulation pré-chargée. |
| Clé API refusée | Message d'erreur clair → le montrer comme un état d'erreur géré, utiliser le cache. |
| L'app ne réagit pas au démarrage | Attendre ~20 s (debug) ; d'où l'intérêt de la lancer avant. |
| L'émulateur plante | Passer sur la vidéo de secours en commentant de la même façon. |
| Trop peu de temps | Couper dans cet ordre : partie 9, puis 2, puis 6. Garder Playground + rejeu + hors connexion. |
