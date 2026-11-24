# SharesKnowledge : plan fonctionnel du projet

## 1. Rôle de ce document

Ce document décrit ce que l’utilisateur doit pouvoir faire, voir et comprendre dans SharesKnowledge. Il sert de base à la conception de l’application. Les choix de développement, d’architecture, de bibliothèques et de stockage sont faits au moment du développement.

Le plan rassemble la proposition de projet et les idées discutées ensuite. Il distingue le premier périmètre à terminer des enrichissements possibles. Toutes les rubriques participent à la vision finale, mais leur profondeur dépendra du temps disponible pour un développement seul.

## 2. Concept et objectif pédagogique

SharesKnowledge est une application mobile d’apprentissage de l’investissement destinée aux débutants. Elle permet de comprendre des notions financières en manipulant des paramètres, en observant des données historiques et en prenant des décisions fictives.

L’expérience repose sur quatre rubriques complémentaires :

| Rubrique | Question à laquelle elle répond |
| --- | --- |
| Learn | Comment fonctionne cette notion ? |
| Perfect Foresight | Que pourrait-on obtenir en connaissant parfaitement le futur ? |
| Past Trader | Qu’aurais-je décidé sans connaître la suite ? |
| Playground | Que se serait-il passé avec mes propres paramètres ? |

La boucle pédagogique recherchée est : découvrir une notion, la manipuler, observer ses conséquences, puis l’essayer dans une autre expérience.

L’application ne permet aucune transaction financière réelle et ne demande aucun accès bancaire ou à un courtier. Les résultats historiques servent à apprendre ; ils ne constituent pas des prévisions de gains futurs.

## 3. Organisation générale et navigation

### 3.1 Accueil

L’accueil présente clairement l’objectif de l’application et donne accès aux quatre rubriques ainsi qu’au profil.

Il contient :

- une présentation courte de SharesKnowledge ;
- une entrée pour chaque rubrique, avec une phrase expliquant son intérêt ;
- un bouton pour reprendre une leçon ou une expérience interrompue, si elle existe ;
- un aperçu de la progression personnelle ;
- un accès aux simulations sauvegardées ;
- une indication visible lorsque l’application fonctionne hors connexion.

À la première ouverture, une introduction courte explique les différences entre démonstration idéale, jeu de décision et simulation libre. Elle peut être ignorée et consultée à nouveau.

### 3.2 Navigation attendue

L’utilisateur doit toujours savoir dans quelle rubrique il se trouve. Il doit pouvoir revenir à l’accueil, ouvrir son profil et retrouver une expérience enregistrée sans perdre involontairement sa progression.

Les écrans fonctionnels envisagés sont : accueil, catalogue de leçons, leçon interactive, sélection de scénario, expérience historique, configuration du Playground, résultat de simulation, simulations sauvegardées et profil. Plusieurs peuvent être regroupés si cela simplifie l’usage.

## 4. Learn : leçons interactives

### 4.1 Catalogue

Chaque leçon présente un titre, une description simple, une durée indicative et son état : non commencée, en cours ou terminée.

Le catalogue doit permettre de reprendre une leçon et de retrouver celles déjà suivies. Une organisation par thèmes ou difficulté pourra être ajoutée si le nombre de leçons le justifie.

### 4.2 Structure d’une leçon

Une leçon suit un parcours court :

1. Une situation concrète et une explication accessible.
2. Une manipulation : modifier une somme, une durée, un taux, une période ou une répartition.
3. Une visualisation qui évolue avec les paramètres.
4. Une explication du résultat observé.
5. Une question de compréhension avec retour explicatif, si le temps le permet.

L’utilisateur peut recommencer une expérience sans perdre son statut de leçon terminée. Les termes nouveaux sont expliqués sur place.

### 4.3 Contenu envisagé

| Leçon | Interaction principale | Ce que l’utilisateur doit comprendre |
| --- | --- | --- |
| Rendement et gain | Modifier un capital et comparer départ et arrivée | La différence entre gain en monnaie et performance en pourcentage |
| Rendement composé | Modifier capital, durée et taux hypothétique | L’effet du temps et du réinvestissement des gains |
| DCA | Comparer investissement initial et versements réguliers | L’influence des dates d’achat et du total versé |
| Volatilité | Comparer des trajectoires de prix | Une même performance finale peut cacher des parcours très différents |
| Baisse maximale ou drawdown | Explorer les sommets et les creux d’un historique | L’ampleur des pertes temporaires subies pendant un investissement |
| Diversification | Modifier la répartition entre plusieurs actifs | L’effet de la concentration sur l’exposition du portefeuille |

Le premier périmètre comprend les leçons essentielles sur le rendement et le rendement composé. DCA, drawdown, volatilité et diversification enrichissent progressivement le catalogue.

Les simulations fondées sur un taux constant doivent être identifiées comme des hypothèses, à distinguer des expériences fondées sur des cours historiques.

## 5. Perfect Foresight : la clairvoyance parfaite

### 5.1 Intention

Cette rubrique montre un scénario idéal où les bons actifs sont choisis aux bonnes dates grâce à une connaissance parfaite du futur. Elle doit être spectaculaire tout en expliquant les limites de cette démonstration.

### 5.2 Scénario principal envisagé

Le parcours reprend l’idée d’un capital de départ de 1 000 € en 2021, avec des réinvestissements successifs dans GameStop, Dogecoin, une période en cash, Carvana, MicroStrategy et AppLovin.

Le résultat d’environ 111 millions d’euros discuté initialement est une illustration à vérifier avant publication. Les dates, cours, conversions de devises et hypothèses doivent être cohérents avant d’afficher un montant définitif. Le scénario ne doit pas être présenté comme une stratégie réellement reproductible.

### 5.3 Parcours utilisateur

1. Lire le principe et les hypothèses de la démonstration.
2. Choisir un capital de départ, ou garder celui proposé.
3. Découvrir la première opération et les dates prévues.
4. Faire avancer le temps et observer cours, capital et gains.
5. Voir la vente puis le réinvestissement dans l’actif suivant.
6. Parcourir les différentes étapes jusqu’au résultat final.
7. Consulter une explication sur la connaissance du futur, le risque et le biais rétrospectif.

### 5.4 Éléments affichés

- l’étape actuelle et la chronologie du parcours ;
- l’actif détenu ou la période d’attente en cash ;
- la date courante, les dates d’achat et de vente ;
- le capital initial, le capital courant, le gain et la performance ;
- une courbe de l’actif et une représentation de l’évolution du capital ;
- un résumé de chaque opération ;
- les hypothèses retenues, notamment concernant frais et devises.

L’utilisateur peut mettre la démonstration en pause, reprendre, revenir sur une étape et recommencer. Les opérations sont scénarisées : il observe un parcours idéal plutôt que d’être évalué sur ses décisions.

### 5.5 Bilan pédagogique

Le bilan explique pourquoi identifier un gagnant après coup est beaucoup plus facile que le choisir avant sa hausse. Il rappelle que le choix de l’actif, les dates d’achat et de vente, les périodes de perte et les conditions d’exécution influencent le résultat.

D’autres parcours, dates de départ ou catégories d’actifs pourront être ajoutés plus tard.

## 6. Past Trader : décider sans connaître le futur

### 6.1 Principe et séparation des scénarios

Past Trader replace l’utilisateur dans une période passée et lui demande de prendre des décisions avec les seules informations disponibles à cet instant.

Les actifs et périodes utilisés doivent être différents de ceux de Perfect Foresight. Un scénario dont la réponse a déjà été montrée ailleurs dans l’application ne doit pas servir à évaluer l’utilisateur comme une première découverte.

### 6.2 Sélection des scénarios

Le catalogue présente des situations, une difficulté indicative et l’état de progression, sans révéler leur issue.

Les scénarios mélangent volontairement : forte hausse, hausse modérée, stagnation, effondrement, hausse suivie d’une chute et chute suivie d’une récupération. L’utilisateur ne doit pas pouvoir déduire que tout actif proposé finira par monter.

Les situations possibles comprennent : prendre ses bénéfices, acheter pendant une baisse, résister à la peur de rater une hausse ou décider après une perte importante.

### 6.3 Deux niveaux de présentation

- **Historique** : le nom de l’actif et la date sont visibles.
- **Blind** : le nom de l’actif est masqué ; la date exacte pourra aussi être masquée. Les informations utiles au scénario restent visibles, puis l’identité est révélée à la fin.

Le mode Blind est un enrichissement. Dans tous les cas, les graphiques, descriptions, indicateurs et échelles ne doivent pas révéler indirectement les cours futurs.

### 6.4 Déroulement d’une partie

1. Découvrir la situation, le capital disponible et les règles.
2. Consulter le graphique limité à la date courante et les informations connues.
3. Choisir d’acheter, vendre, conserver ou attendre selon sa position.
4. Choisir le montant concerné ; la vente partielle pourra être ajoutée ensuite.
5. Faire avancer le temps.
6. Observer les nouveaux cours et les conséquences de la décision.
7. Répéter jusqu’à la fin du scénario.

Chaque décision précise le cours et la date d’exécution retenus. L’utilisateur ne peut pas revenir modifier une décision après avoir vu la suite ; il peut recommencer une nouvelle partie, identifiée comme une répétition.

### 6.5 Informations pendant la partie

- capital disponible en cash ;
- quantité détenue et valeur de la position ;
- valeur totale du portefeuille fictif ;
- gain ou perte et performance à la date courante ;
- historique des décisions déjà prises ;
- progression temporelle sans indication sur la direction future du marché.

L’application empêche les décisions incohérentes : dépenser plus que le cash disponible ou vendre plus que la quantité détenue. Les règles de la partie restent simples et explicites.

### 6.6 Résultat final

Le bilan présente le capital final, le gain ou la perte, la performance, les décisions prises et la plus forte baisse du portefeuille si cet indicateur est disponible.

Le résultat est comparé à une référence adaptée au même scénario, par exemple acheter au début puis conserver. Une comparaison avec un parcours idéal pourra être révélée uniquement à la fin, avec ses hypothèses précises.

Le bilan souligne ce que les décisions ont changé et renvoie vers une leçon pertinente. Un bon résultat isolé ne doit pas être assimilé automatiquement à une bonne maîtrise de l’investissement.

## 7. Playground : expérimenter librement

### 7.1 Configuration

L’utilisateur choisit :

- un actif dans une liste consultable ;
- un capital initial ;
- une date de début et une date de fin ;
- la stratégie : investissement initial, puis DCA lorsque disponible ;
- le montant et la fréquence des versements dans le cas du DCA ;
- éventuellement un actif ou une stratégie de comparaison.

Les favoris et la recherche d’actifs sont des enrichissements possibles. Un catalogue limité d’actifs suffit pour commencer ; le catalogue de 30 instruments évoqué dans le sujet est une possibilité, pas une obligation.

### 7.2 Validation des choix

L’utilisateur reçoit une explication claire si un montant est invalide, si les dates sont incohérentes ou si l’historique demandé n’est pas disponible. L’application ne doit pas afficher un résultat calculé sur une période différente sans le signaler.

Les jours sans cotation sont traités selon une règle visible, par exemple le prochain jour de marché disponible. Une absence de cours ne doit pas être confondue avec un prix nul.

### 7.3 Résultats

- somme totale investie ;
- valeur finale ;
- gain ou perte en monnaie ;
- performance en pourcentage, avec une définition adaptée aux versements ;
- courbe historique et évolution de la valeur simulée ;
- baisse maximale lorsque disponible ;
- résumé des paramètres et des hypothèses.

L’utilisateur peut consulter directement le bilan ou rejouer l’évolution avec les commandes temporelles. Il peut modifier les paramètres, recommencer, sauvegarder le résultat et le retrouver dans son profil.

### 7.4 Comparaisons

Les premières comparaisons peuvent porter sur deux périodes ou sur investissement initial contre investissement régulier. Les comparaisons entre actifs et portefeuilles viendront ensuite.

Chaque comparaison doit préciser les dates et les sommes investies. Si les apports diffèrent, cette différence doit être visible afin de ne pas attribuer tout écart final à la seule performance de la stratégie.

Un usage avec le dernier cours connu pourra indiquer combien de titres un montant permettrait d’acheter. Il ne doit pas simuler un futur certain à partir de ce prix.

## 8. Profil utilisateur et progression

### 8.1 Contenu du profil

Le profil rassemble la progression pédagogique et les expériences effectuées. Une connexion à un compte n’est pas nécessaire au premier périmètre.

Il peut afficher :

- un pseudonyme et un avatar facultatifs ;
- les leçons commencées et terminées ;
- le nombre de simulations Playground terminées ;
- le nombre de scénarios Past Trader distincts terminés ;
- les répétitions d’un scénario, distinguées des premières tentatives ;
- les expériences sauvegardées et leur date ;
- les médailles obtenues et les conditions restant à remplir.

Les indicateurs de performance se consultent par scénario ou comparaison pertinente. Une moyenne de rendements sur des périodes et des risques très différents ne doit pas servir de note globale trompeuse.

### 8.2 Médailles envisagées

| Médaille | Condition fonctionnelle proposée |
| --- | --- |
| Premier pas | Terminer une première leçon |
| Première simulation | Terminer une simulation dans Playground |
| Explorateur | Tester plusieurs actifs ou périodes distincts |
| Investissement régulier | Terminer une expérience DCA |
| Comparateur | Réaliser une comparaison de stratégies |
| Regard sur le risque | Terminer une leçon sur la volatilité ou la baisse maximale |
| Première décision | Terminer un premier scénario Past Trader |
| Sans boule de cristal | Terminer un scénario Blind |

Les seuils exacts seront fixés lors de la conception. Les médailles valorisent l’apprentissage et la diversité des expériences ; elles ne récompensent pas seulement les plus gros gains. Perfect Foresight peut compter comme une découverte pédagogique, mais ses gains scénarisés ne mesurent pas la compétence de l’utilisateur.

### 8.3 Historique personnel

L’utilisateur peut ouvrir une simulation sauvegardée, consulter une partie terminée, reprendre une expérience en cours, renommer une sauvegarde et supprimer un élément avec une confirmation explicite.

Une remise à zéro de la progression peut être proposée, avec confirmation. Le profil et les médailles restent un enrichissement après les fonctions centrales.

## 9. Comportements communs à l’application

### 9.1 Avancée du temps

Perfect Foresight, Past Trader et le rejeu du Playground proposent des commandes **+1 jour**, **+7 jours** et **+1 mois**. Une lecture automatique et une vitesse réglable peuvent être ajoutées ensuite.

La date, le cours, le graphique et la valeur du capital évoluent ensemble. Les jours sans données et les sauts temporels doivent rester compréhensibles. L’animation d’un mois ne doit pas obliger l’utilisateur à regarder trente cycles complets.

Past Trader permet uniquement d’avancer pendant une partie. Le retour sur la chronologie appartient au bilan final. Perfect Foresight et Playground peuvent autoriser une exploration libre puisque leur objectif est différent.

### 9.2 Données et transparence des résultats

Chaque expérience précise la période utilisée, la devise et la date de dernière actualisation. Les cours peuvent être quotidiens ; un flux à la seconde n’est pas nécessaire.

L’application distingue les cours historiques réels, les valeurs calculées et les hypothèses pédagogiques. Elle indique si frais, dividendes ou conversions de devises sont inclus. Un cours en dollars ne doit pas être présenté comme un cours en euros sans conversion ou explication.

### 9.3 Chargement et erreurs

Les situations suivantes disposent d’un affichage adapté : première ouverture, chargement, données disponibles, actualisation, erreur, absence d’historique et absence de sauvegarde.

En cas de difficulté, l’utilisateur reçoit une explication utile et une action possible : réessayer, changer de période ou utiliser une expérience déjà disponible. Un chargement ne doit pas effacer inutilement ce qu’il consultait.

### 9.4 Hors connexion et conservation

Les leçons disponibles, la progression, les sauvegardes et les historiques déjà consultés restent utilisables hors connexion, y compris après fermeture puis réouverture de l’application.

Les données anciennes sont identifiées par leur date de mise à jour. Une nouvelle expérience demandant des données indisponibles explique pourquoi elle ne peut pas démarrer hors connexion.

L’utilisateur retrouve ses expériences, ses préférences et sa progression d’une session à l’autre.

## 10. Identité visuelle et animations

### 10.1 Logo

Le logo retenu repose sur **Sᵏ** : un S bleu avec un k turquoise en exposant. Le S évoque le partage et le k la connaissance qui amplifie sa portée.

La version avec le nom SharesKnowledge sert aux présentations et à l’accueil ; le monogramme sans nom, sur fond transparent, sert aux petits emplacements. La version retenue est sans effet néon.

### 10.2 Présentation générale

L’interface doit être lisible, accessible à un débutant et cohérente entre les rubriques. Les gains et pertes ne sont pas distingués uniquement par la couleur : signes, valeurs et libellés les accompagnent.

Les explications restent proches des informations concernées. L’utilisateur peut identifier rapidement ce qu’il a investi, ce qu’il possède, la date observée et l’action qu’il peut faire.

### 10.3 Animations principales

1. **Cycle soleil et lune** : accompagne l’avancée du temps en arrière-plan sans gêner la lecture.
2. **Progression du graphique** : révèle les nouveaux points en synchronisation avec la date.
3. **Évolution du capital** : fait varier progressivement le montant affiché jusqu’à sa nouvelle valeur.

Une animation du logo pour le chargement constitue un complément : apparition du S, puis du k en exposant, éventuellement avec un léger mouvement répété. Elle conserve les couleurs et le style du logo, sans le transformer en néon.

Les animations doivent rester courtes et pouvoir être réduites pour le confort de lecture. Les valeurs finales demeurent clairement accessibles.

## 11. Priorités de réalisation

Le projet complet est ambitieux pour une personne seule. Il faut terminer des parcours utilisables plutôt que multiplier les rubriques incomplètes.

| Priorité | Contenu | Résultat attendu |
| --- | --- | --- |
| 1. Premier périmètre fonctionnel | Accueil, configuration du Playground, consultation des résultats et sauvegardes ; historique réel ; gestion des montants et dates ; progression temporelle et trois animations ; réutilisation hors connexion | Une expérience complète, conservée entre les sessions, couvrant les obligations du projet |
| 2. Identité pédagogique | Un parcours Perfect Foresight complet et deux leçons interactives essentielles | La différence entre observation historique, hypothèse et clairvoyance devient concrète |
| 3. Jeu de décision | Quelques scénarios Past Trader avec issues variées, décisions et bilan comparatif | L’utilisateur expérimente les décisions sans connaître le futur |
| 4. Progression personnelle | Profil enrichi, statistiques par scénario, médailles et historique des tentatives | L’utilisateur peut suivre son apprentissage |
| 5. Enrichissements | DCA et comparaisons avancées, mode Blind, leçons supplémentaires et nouveaux parcours | Davantage de situations et de liberté d’expérimentation |

Un profil minimal peut exister dès le début pour retrouver les sauvegardes. Les statistiques détaillées et médailles restent secondaires. Les obligations scolaires doivent être satisfaites dès le premier périmètre, sans dépendre des extensions.

## 12. Critères de réussite fonctionnelle

- Un débutant comprend le rôle de chaque rubrique dès l’accueil.
- Une simulation peut être configurée, lancée, comprise, sauvegardée et retrouvée.
- Les erreurs de saisie et les périodes indisponibles sont expliquées.
- Les données anciennes et les hypothèses sont identifiables.
- Les contenus déjà disponibles gardent un intérêt sans connexion, après réouverture.
- Perfect Foresight explique son caractère idéal au lieu de promettre un gain reproductible.
- Past Trader ne révèle aucun cours futur avant la décision et utilise des exemples distincts.
- Les bilans comparent des situations dont les paramètres sont explicités.
- Les compteurs de progression distinguent découvertes, simulations et répétitions.
- Les animations aident à comprendre l’évolution du temps et des valeurs.

## 13. Obligations du sujet

Cette liste conserve les exigences scolaires, sans prescrire leur mise en œuvre :

- Au moins trois écrans significatifs et une navigation entre eux.
- Un formulaire avec validation.
- Une liste dynamique.
- Au moins une API REST externe et conversion JSON vers des objets Dart.
- Persistance de données métier.
- Cache local des données issues d’une API.
- Fonctionnement partiel hors connexion.
- Gestion explicite des états de chargement, de données et d’erreur.
- Au moins une visualisation graphique significative.
- Au moins deux calculs métier ; performance et gain ou perte sont prévus dans le premier périmètre.
- Au moins trois animations pertinentes, dont deux programmées directement.
- Des tests unitaires portant sur la logique métier et ses cas limites.
- Une séparation cohérente des responsabilités et des choix justifiables.
- Un rapport expliquant les choix, les réalisations, les limites et les validations.
- Une démonstration fonctionnelle et la capacité à expliquer le fonctionnement de l’application.

La proposition d’une page doit être validée avant le développement. Le choix définitif des sources de données et de leurs possibilités reste à vérifier pendant le développement. Twelve Data et, si nécessaire, CoinGecko sont les pistes mentionnées dans la proposition, sans engagement sur leurs offres ni leurs limites.

## 14. Évolutions à garder hors du premier périmètre

- Inflation et pouvoir d’achat.
- Risque de change détaillé.
- Dividendes, frais et fiscalité simplifiée.
- Portefeuille composé de plusieurs actifs dans Playground.
- Chaînes libres de réinvestissement entre actifs.
- Objectifs pédagogiques personnalisés.
- Nouveaux scénarios de clairvoyance et de décision.
- Synchronisation de la progression entre appareils.

Ces pistes ne constituent pas des engagements pour la première version. Toute extension doit conserver l’objectif central : apprendre par l’expérience, avec des résultats compréhensibles.
