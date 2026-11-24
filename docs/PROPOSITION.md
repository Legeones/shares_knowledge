# SharesKnowledge : proposition de projet

**Application mobile Flutter d'apprentissage de l'investissement pour débutants**

## Objectif

Faire comprendre les notions de base de l'investissement (rendement, rendement composé, volatilité,
baisse maximale, investissement régulier) **en manipulant des données historiques réelles**, sans
aucune transaction financière, sans compte bancaire ni courtier. Les résultats servent à apprendre ;
ce ne sont pas des prévisions.

## Quatre rubriques

| Rubrique | Question | Principe |
| --- | --- | --- |
| **Learn** | Comment fonctionne cette notion ? | Leçons courtes : explication, curseurs à manipuler, graphique qui réagit, question de compréhension. |
| **Perfect Foresight** | Que gagnerait-on en connaissant le futur ? | Parcours scénarisé (1 000 € en 2021 réinvestis dans GME, DOGE, CVNA, MSTR, APP) pour illustrer le biais rétrospectif. |
| **Past Trader** | Qu'aurais-je décidé sans connaître la suite ? | L'utilisateur achète, vend ou attend jour après jour sur une période passée ; le futur reste caché. |
| **Playground** | Que se serait-il passé avec mes paramètres ? | Choix d'un actif, d'un capital et d'une période ; calcul du gain, de la performance et de la baisse maximale. |

Communs : avancée du temps (+1 jour, +7 jours, +1 mois), profil avec progression et simulations sauvegardées.

## Premier périmètre (livrable minimal)

Accueil, **Playground complet** (formulaire, résultat, graphique, rejeu temporel animé), sauvegardes,
profil minimal, fonctionnement hors connexion. Ensuite, par priorité : 2 leçons Learn et Perfect Foresight,
puis Past Trader, puis médailles et statistiques.

## Réponse aux exigences du sujet

| Exigence | Réalisation |
| --- | --- |
| ≥ 3 écrans + navigation | Accueil, Playground (configuration / résultat), Sauvegardes, Profil, rubriques ; barre de navigation. |
| Formulaire validé | Configuration Playground : montant > 0, dates cohérentes, historique disponible. |
| Liste dynamique | Catalogue d'actifs filtrable, liste des simulations sauvegardées. |
| API REST et conversion JSON en Dart | **Twelve Data** `/time_series` (cours quotidiens actions, crypto, EUR/USD) ; conversion `fromJson` manuelle. |
| Persistance métier | SQLite (`sqflite`) : simulations sauvegardées, progression. |
| Cache local | Historiques stockés en SQLite avec leur date de mise à jour ; seuls les jours manquants sont redemandés. |
| Hors connexion partiel | Historiques déjà consultés, sauvegardes, leçons et scénarios embarqués utilisables sans réseau. |
| États chargement / données / erreur | État explicite dans chaque écran asynchrone, avec action de reprise (réessayer, changer de période). |
| Visualisation | Courbes du cours et de la valeur simulée (`fl_chart`). |
| ≥ 2 calculs métier | Gain/perte, performance, baisse maximale, rendement composé. |
| ≥ 3 animations (dont 2 programmées) | Cycle soleil/lune et révélation progressive du graphique (`AnimationController`) ; compteur du capital (`TweenAnimationBuilder`). |
| Tests unitaires | Logique métier isolée de l'interface : calculs et cas limites (période vide, perte totale, jours sans cotation). |
| Séparation des responsabilités | Couches : modèles, logique, données (API / local / repository), état (`provider`), écrans. |

## Limites assumées

Cours quotidiens en devise d'origine (USD le plus souvent), sans frais, dividendes ni fiscalité.
Pas de compte utilisateur ni de synchronisation entre appareils. Offre gratuite Twelve Data
(8 requêtes/min, 800/jour), largement suffisante grâce au cache des historiques.
