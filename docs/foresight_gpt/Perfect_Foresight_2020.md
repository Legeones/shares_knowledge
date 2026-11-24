# Perfect Foresight — décennie de départ : années 2020

PÉRIODE : du 2021-01-04 au 2026-10-05. Capital initial : **1 000 $**.

Parcours narratif spectaculaire construit rétrospectivement, **pas un maximum mathématique démontré**. Les dates sont des candidats proches de zones de retournement, sauf les achats initiaux imposés, les transitions entre gagnants et les sorties à la borne finale. Aucun calcul d’impôts ni de retraits pour vivre.

Les multiplicateurs sont des **ordres de grandeur provisoires**, arrondis à partir des historiques publics consultés ; ce ne sont pas des rendements calculés sur ta série quotidienne. Certaines sources ajustent aussi les dividendes : leurs niveaux ne doivent pas être copiés directement. Le résultat définitif doit utiliser exclusivement `clôture ajustée des divisions à la vente / clôture ajustée des divisions à l’achat`, sans dividendes. Le cash est en dollars, non rémunéré, avec un multiplicateur de 1.

Les changements de position suivent le calendrier des séances américaines, y compris pour la cryptomonnaie : les week-ends crypto ne servent pas à ajouter des étapes. Une position vendue est liquidée à sa clôture ; les dollars restent disponibles jusqu’à l’achat à la clôture de la séance suivante. Les jours fériés expliquent le passage du 24 au 26 décembre 2018 et, quand applicable, du 18 au 20 juin 2024. Aucun achat n’est fait à l’ouverture ni au prix de souscription d’une introduction.

Borne récente retenue : **5 octobre 2026**, dernière séance complète dont une clôture du dernier actif a été vérifiée le 6 octobre 2026. Cette borne ne constitue pas une prévision et n’est pas nécessairement un sommet.

## A) Tableau récapitulatif

| N° | Actif (symbole) | Achat / début | Vente / fin | Multiplicateur estimé | Événement clé |
| --- | --- | --- | --- | --- | --- |
| 1 | Tesla (TSLA) | 2021-01-04 | 2021-01-26 | ≈ × 1,21 | Voiture électrique et entrée dans le S&P 500 |
| 2 | Dogecoin (DOGE/USD) | 2021-01-27 | 2021-05-07 | ≈ × 90 | Mèmes, réseaux sociaux et fièvre Dogecoin |
| 3 | Cash en USD | 2021-05-10 | 2021-07-19 | × 1 | Correction crypto du printemps 2021 |
| 4 | Nvidia (NVDA) | 2021-07-20 | 2021-11-08 | ≈ × 1,7 | Calcul graphique et centres de données |
| 5 | Cash en USD | 2021-11-09 | 2022-10-13 | × 1 | Inflation, hausse des taux et baisse de 2022 |
| 6 | Nvidia (NVDA) | 2022-10-14 | 2024-06-18 | ≈ × 12,1 | Ruée vers les équipements de l’IA |
| 7 | Palantir (PLTR) | 2024-06-20 | 2025-02-18 | ≈ × 4,9 | Logiciels d’IA et réévaluation de Palantir |
| 8 | Cash en USD | 2025-02-19 | 2025-04-07 | × 1 | Correction et droits de douane de 2025 |
| 9 | Palantir (PLTR) | 2025-04-08 | 2026-10-05 | ≈ × 2,45 | Reprise de Palantir et borne d’observation |

## B) Résultat estimé avec sorties de capital

**Avec la règle de cash-out ci-dessous, les 1 000 $ produisent environ 7,6 millions de dollars de patrimoine total.** Le multiplicateur patrimonial est d’environ **× 7 590**. À la clôture finale, tout le solde est également retiré : le capital de trading est donc nul et le patrimoine est constitué des dollars sortis du parcours.

### Règle de cash-out retenue

- Avant une prochaine détention d’actions commençant avant 1990 : conserver au maximum **10 000 $** à réinvestir.
- Avant une prochaine détention d’actions commençant à partir de 1990 : conserver au maximum **1 000 000 $** à réinvestir.
- Avant Dogecoin : conserver au maximum **100 000 $** à réinvestir.
- Si le capital disponible est inférieur à ce plafond, le conserver intégralement. Retirer définitivement le surplus dès la vente de l’actif précédent ; il reste hors du portefeuille simulé et ne génère aucun rendement.
- À la dernière vente : retirer l’intégralité du solde.

**Ces plafonds sont des paramètres pédagogiques choisis pour cette version, pas des seuils de liquidité démontrés.** La connaissance du futur permet ici d’identifier la prochaine détention et de conserver une réserve pour celle-ci. Il n’existe pas de montant minimal magique à conserver : un plafond plus bas sécurise davantage d’argent, mais réduit les gains futurs.

Pour une limite réellement adaptée à chaque actif, utiliser aussi ses volumes : réduire le montant réinvesti à une fraction configurable, par exemple **1 % du volume quotidien moyen en dollars des 20 séances précédentes**. Ce pourcentage est lui aussi une convention et ne garantit pas une exécution à la clôture ; il ne peut pas être appliqué numériquement ici sans tes volumes. Les montants suivants appliquent uniquement les plafonds fixes ci-dessus.

### Sorties de capital estimées

| Après étape | Date de vente | Argent retiré | Réserve pour la suite | Retraits cumulés |
| --- | --- | --- | --- | --- |
| 6 | 2024-06-18 | ≈ 1 240 073 $ | ≈ 1 000 000 $ | ≈ 1 240 073 $ |
| 7 | 2025-02-18 | ≈ 3 900 000 $ | ≈ 1 000 000 $ | ≈ 5 140 073 $ |
| 9 | 2026-10-05 | ≈ 2 450 000 $ | ≈ 0 $ | ≈ 7 590 073 $ |

Les montants sont arrondis ; ils devront être recalculés avec les cours du fournisseur. Ces cash-outs sont des sorties de capital, **pas des impôts ni des dépenses pour vivre**. Retirer ne modifie pas la performance historique d’une étape, mais modifie le montant qui lui est exposé : on ne peut donc plus multiplier tous les rendements pour obtenir le patrimoine final.

### Opérations de cash-out pour l’application

Ce bloc est séparé du parcours C afin de conserver exactement son schéma. L’application doit recalculer ces montants avec les vrais rendements avant de les appliquer ; les dollars retirés ne sont jamais réinvestis.

```json
[
  {
    "afterStep": 6,
    "date": "2024-06-18",
    "cashOut": 1240073.0,
    "keepForNextAsset": 1000000.0,
    "cumulativeCashOut": 1240073.0
  },
  {
    "afterStep": 7,
    "date": "2025-02-18",
    "cashOut": 3900000.0,
    "keepForNextAsset": 1000000.0,
    "cumulativeCashOut": 5140073.0
  },
  {
    "afterStep": 9,
    "date": "2026-10-05",
    "cashOut": 2450000.0,
    "keepForNextAsset": 0.0,
    "cumulativeCashOut": 7590073.0
  }
]
```

### Comparaison sans cash-out

Le multiplicateur théorique brut du tableau A est d’environ **× 26 892**, soit environ **26,9 millions de dollars** pour 1 000 $. Cette comparaison sans sorties de capital n’est pas le patrimoine à afficher pour la version avec cash-out.

Le calcul suppose des fractions d’actions, le réinvestissement intégral de la réserve conservée, aucune commission, aucun écart d’exécution et aucune contrainte de règlement-livraison. Il ne suppose ni emprunt, ni vente à découvert, ni produit à effet de levier. Les fractions d’actions et l’achat dès la séance suivante sont des conventions de simulation, particulièrement pour les périodes anciennes.

**Pourquoi c’est impossible à reproduire :** il faut connaître les futurs gagnants, les crises et les bonnes dates avant qu’ils ne soient visibles. De plus, le calcul conserve les prix historiques même quand le portefeuille devient gigantesque : à cette échelle, acheter ou vendre tout le capital déplacerait les cours et pourrait demander davantage de titres que le marché n’en offre. Ce résultat est une expérience sur des séries de prix, pas une richesse réellement négociable.

## C) Parcours JSON

```json
[
  {
    "kind": "asset",
    "symbol": "TSLA",
    "name": "Tesla",
    "buy": "2021-01-04",
    "sell": "2021-01-26",
    "story": "Tesla devient l’un des symboles de l’enthousiasme pour la voiture électrique. Nous quittons ensuite le titre pour profiter d’une autre fièvre spéculative.",
    "context": "Les véhicules électriques attirent les investisseurs et Tesla entre dans le S&P 500 en décembre 2020. Début 2021, les réseaux sociaux deviennent également un lieu central de mobilisation boursière.",
    "whyEnter": "Le futur nous apprend que Tesla va bénéficier d’une forte hausse des attentes autour de la voiture électrique. Nous prenons position avant la transition vers l’étape Dogecoin.",
    "whyLeave": "Le futur nous apprend que Dogecoin va connaître une accélération spectaculaire à partir de la fin janvier 2021. Nous vendons Tesla pour y transférer tout le capital à la séance suivante.",
    "lessonTitle": "Le prix anticipe le futur",
    "lesson": "Le cours d’une action reflète en partie les résultats que les investisseurs espèrent obtenir plus tard. Il peut donc monter beaucoup plus vite que les bénéfices actuels, puis corriger si les attentes deviennent trop ambitieuses."
  },
  {
    "kind": "asset",
    "symbol": "DOGE/USD",
    "name": "Dogecoin",
    "buy": "2021-01-27",
    "sell": "2021-05-07",
    "story": "Une cryptomonnaie née autour d’un mème devient un phénomène mondial. Nous suivons l’envolée de Dogecoin, puis sortons avant le retournement de mai 2021.",
    "context": "Les réseaux sociaux et les interventions publiques d’Elon Musk attirent l’attention sur Dogecoin. Son passage dans Saturday Night Live, le 8 mai 2021, s’inscrit dans cette période de fièvre spéculative.",
    "whyEnter": "Le futur nous apprend que l’attention autour de Dogecoin va provoquer une envolée majeure. Nous achetons avant l’accélération de fin janvier, avec une connaissance du futur inaccessible dans la réalité.",
    "whyLeave": "Le futur nous apprend que la zone du sommet arrive au début de mai. Nous vendons à la clôture quotidienne retenue du 7 mai, et non au plus haut atteint à l’intérieur d’une journée.",
    "lessonTitle": "L’emballement collectif",
    "lesson": "Un actif peut monter parce que chacun espère le revendre plus cher au prochain acheteur. Cet enthousiasme peut disparaître rapidement, et une cryptomonnaie ne donne pas un droit aux bénéfices d’une entreprise."
  },
  {
    "kind": "cash",
    "from": "2021-05-10",
    "to": "2021-07-19",
    "story": "Le portefeuille quitte Dogecoin avant sa forte correction. Il laisse passer plusieurs semaines de turbulence avant de revenir aux actions.",
    "context": "Le marché des cryptomonnaies traverse une importante correction au printemps 2021. Des annonces et des mouvements de confiance provoquent des variations rapides.",
    "whyEnter": "Le futur nous apprend que l’euphorie crypto va laisser place à une baisse importante. Nous conservons le capital en dollars pour garder la possibilité de changer de marché.",
    "whyLeave": "Le futur nous apprend que Nvidia offre une nouvelle phase de progression à partir de l’été. Nous préparons un achat à la prochaine séance américaine.",
    "lessonTitle": "Le cash comme option",
    "lesson": "Le cash permet de saisir une opportunité sans devoir vendre d’abord un actif qui a chuté. Cette souplesse a un coût : pendant l’attente, le portefeuille peut manquer une hausse ailleurs."
  },
  {
    "kind": "asset",
    "symbol": "NVDA",
    "name": "Nvidia",
    "buy": "2021-07-20",
    "sell": "2021-11-08",
    "story": "Nvidia profite d’une nouvelle vague d’enthousiasme pour le calcul graphique. Le parcours revend avant la baisse des valeurs de croissance de 2022.",
    "context": "Les usages du calcul graphique se multiplient et les investisseurs s’intéressent aux centres de données. Les divisions d’actions peuvent également attirer l’attention, sans créer de richesse à elles seules.",
    "whyEnter": "Le futur nous apprend que le titre va progresser pendant les mois suivants. Nous achetons après la correction de l’été 2021.",
    "whyLeave": "Le futur nous apprend que la période suivante sera moins favorable aux valeurs de croissance. Nous vendons près d’une zone haute estimée, avant leur réévaluation en 2022.",
    "lessonTitle": "Une division d’actions",
    "lesson": "Une division augmente le nombre d’actions tout en réduisant proportionnellement leur prix. Elle ne multiplie pas la valeur du portefeuille : les anciens cours doivent être ajustés pour comparer correctement les dates."
  },
  {
    "kind": "cash",
    "from": "2021-11-09",
    "to": "2022-10-13",
    "story": "Le portefeuille attend en cash pendant la fin de l’euphorie et la baisse de 2022. Il revient ensuite vers Nvidia avant l’explosion de la demande liée à l’IA.",
    "context": "L’inflation revient au premier plan et la Réserve fédérale relève ses taux en 2022. La guerre en Ukraine ajoute de l’incertitude, tandis que les valeurs de croissance et les cryptomonnaies souffrent.",
    "whyEnter": "Le futur nous apprend que plusieurs actifs appréciés pendant l’euphorie vont subir de fortes baisses. Nous choisissons une pause longue pour préserver le capital, en acceptant de manquer certaines hausses intermédiaires.",
    "whyLeave": "Le futur nous apprend que Nvidia approche d’un creux avant une transformation de sa demande. Nous préparons un achat à la séance suivante, avant que l’IA générative ne devienne un thème boursier incontournable.",
    "lessonTitle": "Les taux d’intérêt",
    "lesson": "Des taux plus élevés rendent l’emprunt plus coûteux et augmentent le rendement exigé par les investisseurs. Les entreprises dont les bénéfices sont surtout attendus dans un futur lointain peuvent alors voir leur valorisation diminuer."
  },
  {
    "kind": "asset",
    "symbol": "NVDA",
    "name": "Nvidia",
    "buy": "2022-10-14",
    "sell": "2024-06-18",
    "story": "Nvidia devient un fournisseur essentiel de la ruée vers l’intelligence artificielle. Nous accompagnons cette vague avant de transférer le capital vers les logiciels.",
    "context": "L’IA générative accroît les besoins en calcul des centres de données. Les processeurs graphiques de Nvidia occupent une place importante dans l’entraînement et l’utilisation de ces modèles.",
    "whyEnter": "Le futur nous apprend que la demande pour les équipements de calcul de Nvidia va fortement augmenter. Nous achetons après la baisse de 2022, avant que cette demande ne transforme ses résultats.",
    "whyLeave": "Le futur nous apprend que le parcours peut désormais profiter d’une autre phase de croissance liée à l’IA. Nous vendons près de la zone haute de juin 2024 pour acheter Palantir à la séance suivante, sans qualifier cette date de sommet définitif de Nvidia.",
    "lessonTitle": "Les fournisseurs d’une ruée technologique",
    "lesson": "Une entreprise peut profiter d’une innovation en vendant les outils nécessaires à ceux qui la développent. Ce rôle de fournisseur peut être lucratif, mais il expose aussi aux changements de demande et à la concurrence."
  },
  {
    "kind": "asset",
    "symbol": "PLTR",
    "name": "Palantir",
    "buy": "2024-06-20",
    "sell": "2025-02-18",
    "story": "Palantir porte le thème de l’IA vers les logiciels utilisés par les organisations. Nous suivons sa forte progression puis sortons avant la correction du printemps 2025.",
    "context": "Les entreprises cherchent à utiliser leurs données et des modèles d’IA dans leurs opérations. Palantir développe notamment sa plateforme AIP pour relier ces technologies à des usages concrets.",
    "whyEnter": "Le futur nous apprend que Palantir va bénéficier d’une forte réévaluation par les investisseurs. Nous achetons avant cette phase d’enthousiasme pour ses logiciels d’IA.",
    "whyLeave": "Le futur nous apprend que l’envolée de début 2025 va être suivie d’une correction. Nous vendons dans la zone du sommet local estimé de février, avant de rester en cash.",
    "lessonTitle": "La hausse des multiples de valorisation",
    "lesson": "Une action peut monter parce que les bénéfices progressent, mais aussi parce que les investisseurs acceptent de payer plus cher chaque dollar de bénéfice ou de chiffre d’affaires. Ce second moteur peut s’inverser rapidement quand la confiance diminue."
  },
  {
    "kind": "cash",
    "from": "2025-02-19",
    "to": "2025-04-07",
    "story": "Le portefeuille attend pendant la correction du printemps 2025. Il laisse passer les turbulences liées aux annonces sur les droits de douane.",
    "context": "Les annonces commerciales américaines d’avril 2025 secouent les marchés mondiaux. Les investisseurs réévaluent leurs hypothèses sur les coûts, les échanges et la croissance.",
    "whyEnter": "Le futur nous apprend que conserver Palantir après la hausse de février exposerait le portefeuille à une forte correction. Nous gardons du cash pendant cette période d’incertitude commerciale.",
    "whyLeave": "Le futur nous apprend qu’une nouvelle phase de progression devient possible après ces turbulences. Nous préparons le retour sur Palantir à la séance suivante, sans supposer que toutes les inquiétudes sont réglées.",
    "lessonTitle": "Les droits de douane",
    "lesson": "Un droit de douane est une taxe sur un produit importé. Il peut augmenter les coûts et perturber les échanges ; les marchés peuvent donc réagir avant même que ses effets apparaissent dans les comptes des entreprises."
  },
  {
    "kind": "asset",
    "symbol": "PLTR",
    "name": "Palantir",
    "buy": "2025-04-08",
    "sell": "2026-10-05",
    "story": "Le portefeuille revient sur Palantir après la correction et conserve cette dernière position jusqu’à la borne vérifiée. Le montant final transforme quelques décisions rétrospectives en une fortune purement théorique.",
    "context": "Les logiciels d’IA restent un thème important pour les investisseurs. Le titre connaît encore des fluctuations : cette dernière détention ne suppose pas une hausse continue.",
    "whyEnter": "Le futur nous apprend que Palantir va regagner du terrain après le choc du printemps 2025. Nous revenons après la correction avec une certitude que personne ne pouvait avoir à cette date.",
    "whyLeave": "Le futur nous apprend que le 5 octobre 2026 est la dernière séance complète vérifiée pour ce scénario. Nous liquidons à cette borne d’observation, sans affirmer qu’il s’agit du meilleur sommet possible.",
    "lessonTitle": "Le biais de connaissance du futur",
    "lesson": "Choisir aujourd’hui les gagnants et leurs dates d’achat donne l’impression que les décisions étaient évidentes. En réalité, on connaissait aussi des concurrents et des scénarios qui ont échoué : cette sélection rétrospective ne démontre aucune capacité à prévoir."
  }
]
```

## D) Incertitudes et vérifications nécessaires

- Vérifier chaque date dans les clôtures quotidiennes du fournisseur. Les dates proposées ne sont pas certifiées comme les meilleurs extrema ; déplacer une frontière impose de déplacer aussi le début de l’étape suivante.
- Recalculer tous les multiplicateurs et le total avec la colonne ajustée uniquement des divisions. Un historique « Adjusted Close » intégrant les dividendes ne respecte pas la convention demandée.
- Confirmer l’absence de trous dans chaque historique, ainsi que la correspondance entre les symboles actuels et les séries anciennes. Je n’ai pas accès au catalogue ni aux cours de ton fournisseur.
- Les explications d’entrée et de sortie sont des choix rétrospectifs de scénario ; elles ne démontrent pas qu’un événement explique à lui seul un mouvement de cours.
- Le cash protège le montant nominal dans cette simulation, mais ne produit aucun intérêt. Les longues pauses peuvent manquer d’autres hausses : le parcours privilégie la lisibilité et le nombre d’étapes autorisé.
- Les plafonds de cash-out portent sur la réserve réinvestie à chaque changement d’actif, pas sur la valeur de la position chaque jour. Une position gagnante peut dépasser son plafond pendant la détention ; une limite quotidienne stricte nécessiterait des ventes partielles supplémentaires et une nouvelle simulation.
- **DOGE/USD : confirmer la clôture et son fuseau horaire pour le 27 janvier et le 7 mai 2021.** Des marchés ou agrégateurs différents donnent des clôtures différentes ; ne pas confondre clôture et record intrajournalier. Le symbole JSON est celui demandé ; certaines sources le notent DOGE-USD.
- **Alternative technique si le symbole crypto n’est pas reconnu : mapper DOGE/USD vers l’identifiant réel du fournisseur.** Si la série est absente malgré la disponibilité annoncée, TSLA peut occuper cette même fenêtre, mais il faut recalculer le résultat et retirer l’histoire Dogecoin : son rendement n’est pas comparable.
- Confirmer les clôtures de Palantir du 20 juin 2024, du 18 février 2025, du 8 avril 2025 et du 5 octobre 2026. Les reprises de cours dans des articles peuvent être datées ou synchronisées différemment ; l’historique du fournisseur doit primer.
- La dernière position Palantir traverse aussi des baisses entre 2025 et 2026. La borne finale est vérifiée, mais cette détention n’optimise pas toutes les oscillations intermédiaires ; obtenir le maximum réel impose une recherche sur l’ensemble des séries et sous les contraintes de durée et de nombre d’étapes.

### Sources consultées

Les sources institutionnelles étayent les événements et les divisions ; les historiques publics servent de repères pour les fenêtres et les ordres de grandeur. **Ces références ne remplacent pas la vérification de chaque transaction dans tes propres données.**

- [Calendrier NYSE, dont le jour férié Juneteenth](https://www.nyse.com/trade/hours-calendars).
- [Apple : historique de clôtures, notamment fin 2007](https://finance.yahoo.com/quote/AAPL/history/?filter=history&frequency=1d&interval=1d&period1=315561600&period2=1471849200).
- [Nvidia : résultats et division de 2024](https://nvidianews.nvidia.com/news/nvidia-announces-financial-results-for-first-quarter-fiscal-2025).
- [Fed : relèvement des taux du 16 mars 2022](https://www.federalreserve.gov/newsevents/pressreleases/monetary20220316a.htm).
- [SEC : annonce des résultats Palantir du 3 février 2025](https://www.sec.gov/Archives/edgar/data/1321655/000132165525000007/pltr-20250203.htm).
- [Palantir : rapport annuel 2025, présentation d’AIP](https://investors.palantir.com/files/2025%20FY%20PLTR%2010-K.pdf?mod=article_inline).
- [Dogecoin : clôtures quotidiennes de 2021, à comparer au fournisseur](https://maketo.com/dogecoin/historical-returns/2021).
- [Palantir : clôture du 5 octobre 2026 et distinction Close/Adj Close](https://fr.finance.yahoo.com/quote/PLTR/history/).
- [Nvidia : historique de clôtures, notamment juin 2024](https://finance.yahoo.com/quote/NVDA/history/?period1=1613687279&period2=1771453658).
- [Tesla : historique de clôtures 2020–2021](https://finance.yahoo.com/quote/TSLA/history/?filter=history&frequency=1d&includeAdjustedClose=true&interval=1d&period1=1277769600&period2=1627776000).
