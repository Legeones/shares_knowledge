// Fil d'actualités de la partie Past Trader 2018-2020.
//
// Règles d'écriture : des faits réels et datés, racontés comme on les
// connaissait CE jour-là, sans indice sur la suite.
// 'major' : true → la lecture automatique se met en pause (« flash info »).
// 'symbols' : actifs concernés (affichés aussi sur la fiche de l'actif).
//
// À modifier ici, puis régénérer avec :
//   dart run tool/build_past_trader_news.dart

const news = [
  // --- Avant le début de la partie : le contexte ---------------------------
  {
    'date': '2017-12-17',
    'category': 'crypto',
    'title': 'Le bitcoin frôle les 20 000 \$',
    'body':
        'Nouveau record : le bitcoin a été multiplié par plus de 15 depuis '
        'janvier. Le grand public s’y intéresse massivement.',
    'symbols': ['BTC/USD'],
  },
  {
    'date': '2017-12-22',
    'category': 'politique',
    'title': 'Trump signe une grande réforme fiscale',
    'body':
        'L’impôt sur les bénéfices des entreprises américaines passe de 35 % '
        'à 21 %. Wall Street salue une hausse attendue des bénéfices.',
    'symbols': ['SPY', 'QQQ'],
  },
  // --- 2018 ------------------------------------------------------------------
  {
    'date': '2018-01-26',
    'category': 'crypto',
    'title': 'Piratage géant d’une plateforme crypto japonaise',
    'body':
        'Coincheck se fait dérober l’équivalent de 530 millions de dollars '
        'en cryptomonnaies, l’un des plus gros vols de l’histoire du secteur.',
    'symbols': ['BTC/USD', 'ETH/USD'],
  },
  {
    'date': '2018-02-05',
    'category': 'economie',
    'major': true,
    'title': 'Wall Street dévisse : le Dow Jones perd 1 175 points',
    'body':
        'Le Dow Jones chute de 4,6 %, sa plus forte baisse en points de son '
        'histoire. Les investisseurs craignent une remontée de l’inflation '
        'et des taux d’intérêt.',
    'symbols': ['SPY', 'QQQ'],
  },
  {
    'date': '2018-03-01',
    'category': 'politique',
    'title': 'Trump annonce des droits de douane sur l’acier et l’aluminium',
    'body':
        '25 % sur l’acier et 10 % sur l’aluminium importés. Les partenaires '
        'commerciaux des États-Unis promettent des représailles.',
    'symbols': ['SPY', 'BA'],
  },
  {
    'date': '2018-03-22',
    'category': 'politique',
    'major': true,
    'title': 'Trump vise jusqu’à 60 milliards de dollars de produits chinois',
    'body':
        'La Maison Blanche prépare des droits de douane contre la Chine, '
        'accusée de pratiques commerciales déloyales. Pékin menace de '
        'répliquer. Les marchés reculent.',
    'symbols': ['SPY', 'QQQ', 'AAPL', 'BA'],
  },
  {
    'date': '2018-07-06',
    'category': 'politique',
    'major': true,
    'title': 'La guerre commerciale est lancée',
    'body':
        '34 milliards de dollars de produits chinois sont désormais taxés à '
        '25 % à l’entrée des États-Unis. La Chine applique immédiatement les '
        'mêmes droits sur des produits américains.',
    'symbols': ['SPY', 'AAPL', 'BA'],
  },
  {
    'date': '2018-08-02',
    'category': 'entreprise',
    'title': 'Apple vaut 1 000 milliards de dollars',
    'body':
        'Première entreprise américaine à franchir ce seuil, portée par des '
        'résultats meilleurs que prévu.',
    'symbols': ['AAPL'],
  },
  {
    'date': '2018-08-07',
    'category': 'entreprise',
    'major': true,
    'title':
        'Elon Musk : « Financement assuré » pour retirer Tesla de la Bourse',
    'body':
        'Dans un tweet, le patron de Tesla dit envisager de racheter toutes '
        'les actions à 420 \$ pièce. L’action bondit ; le gendarme boursier '
        'américain (SEC) s’interroge sur la réalité de ce financement.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2018-09-29',
    'category': 'entreprise',
    'title': 'Musk quitte la présidence du conseil de Tesla',
    'body':
        'Pour régler les poursuites de la SEC liées à son tweet, Elon Musk et '
        'Tesla paient chacun 20 millions de dollars d’amende. Musk reste '
        'directeur général.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2018-10-03',
    'category': 'banqueCentrale',
    'title': 'La Fed est « encore loin » de la fin de ses hausses de taux',
    'body':
        'Pour son président Jerome Powell, les taux sont encore loin de leur '
        'niveau « neutre ». Les taux des obligations montent.',
    'symbols': ['SPY', 'TLT'],
  },
  {
    'date': '2018-10-10',
    'category': 'economie',
    'title': 'Le S&P 500 chute de 3,3 % en une séance',
    'body':
        'Les valeurs technologiques mènent la baisse, sur fond de hausse des '
        'taux et de tensions commerciales.',
    'symbols': ['SPY', 'QQQ', 'AMZN', 'NVDA'],
  },
  {
    'date': '2018-10-29',
    'category': 'entreprise',
    'title': 'Un Boeing 737 MAX de Lion Air s’écrase en Indonésie',
    'body':
        'L’accident fait 189 morts, quelques minutes après le décollage. '
        'L’avion était neuf.',
    'symbols': ['BA'],
  },
  {
    'date': '2018-11-16',
    'category': 'entreprise',
    'title': 'Nvidia plonge de 19 %',
    'body':
        'Ses résultats déçoivent : des stocks de cartes graphiques invendues '
        's’accumulent depuis la fin de la ruée sur le minage de cryptomonnaies.',
    'symbols': ['NVDA'],
  },
  {
    'date': '2018-11-20',
    'category': 'crypto',
    'major': true,
    'title': 'Le bitcoin passe sous les 4 500 \$',
    'body':
        'La cryptomonnaie a perdu plus des trois quarts de sa valeur depuis '
        'son record de décembre 2017.',
    'symbols': ['BTC/USD', 'ETH/USD'],
  },
  {
    'date': '2018-12-01',
    'category': 'politique',
    'title': 'Trêve commerciale de 90 jours entre Trump et Xi Jinping',
    'body':
        'Au sommet du G20, les deux présidents s’accordent pour suspendre '
        'les nouvelles hausses de droits de douane le temps de négocier.',
    'symbols': ['SPY', 'AAPL'],
  },
  {
    'date': '2018-12-19',
    'category': 'banqueCentrale',
    'major': true,
    'title': 'La Fed relève encore ses taux, Wall Street décroche',
    'body':
        'Quatrième hausse de l’année (taux entre 2,25 et 2,50 %) et deux '
        'autres sont prévues en 2019. Les marchés espéraient une pause.',
    'symbols': ['SPY', 'QQQ', 'TLT'],
  },
  {
    'date': '2018-12-24',
    'category': 'economie',
    'title': 'Pire veille de Noël de l’histoire à Wall Street',
    'body':
        'Le S&P 500 perd encore 2,7 %. Il a reculé de près de 20 % depuis '
        'son record de septembre. Le gouvernement américain est en '
        '« shutdown » depuis le 22 décembre.',
    'symbols': ['SPY', 'QQQ'],
  },
  {
    'date': '2018-12-26',
    'category': 'economie',
    'title': 'Le Dow Jones bondit de plus de 1 000 points',
    'body':
        'Hausse de 5 % en une séance, un record en points. Les investisseurs '
        'se demandent s’il s’agit d’un simple rebond.',
    'symbols': ['SPY', 'QQQ'],
  },
  // --- 2019 ------------------------------------------------------------------
  {
    'date': '2019-01-03',
    'category': 'entreprise',
    'major': true,
    'title': 'Apple revoit ses ventes à la baisse, l’action chute de 10 %',
    'body':
        'Une première depuis 2002 : Apple abaisse ses prévisions de chiffre '
        'd’affaires, à cause de ventes d’iPhone décevantes en Chine.',
    'symbols': ['AAPL', 'QQQ'],
  },
  {
    'date': '2019-01-04',
    'category': 'banqueCentrale',
    'title': 'Powell : la Fed sera « patiente »',
    'body':
        'Le président de la Fed se dit prêt à ralentir les hausses de taux. '
        'Wall Street rebondit fortement.',
    'symbols': ['SPY', 'TLT'],
  },
  {
    'date': '2019-03-10',
    'category': 'entreprise',
    'major': true,
    'title': 'Deuxième crash d’un Boeing 737 MAX',
    'body':
        'Un avion d’Ethiopian Airlines s’écrase peu après le décollage : '
        '157 morts. C’est le deuxième accident de ce modèle en cinq mois.',
    'symbols': ['BA'],
  },
  {
    'date': '2019-03-13',
    'category': 'entreprise',
    'title': 'Les 737 MAX cloués au sol dans le monde entier',
    'body':
        'Après l’Europe et la Chine, les États-Unis interdisent à leur tour '
        'les vols de l’avion vedette de Boeing.',
    'symbols': ['BA'],
  },
  {
    'date': '2019-04-18',
    'category': 'entreprise',
    'title': 'Zoom entre en Bourse et s’envole de 72 %',
    'body':
        'Introduite à 36 \$, l’action de la société de visioconférence finit '
        'sa première journée à 62 \$. Zoom est déjà rentable, chose rare '
        'pour une jeune entreprise technologique.',
    'symbols': ['ZM'],
  },
  {
    'date': '2019-05-05',
    'category': 'politique',
    'major': true,
    'title': 'Trump relance la guerre commerciale par un tweet',
    'body':
        'Les droits de douane sur 200 milliards de dollars de produits '
        'chinois passeront de 10 % à 25 % dans cinq jours. Les négociations '
        'semblaient pourtant avancer.',
    'symbols': ['SPY', 'QQQ', 'AAPL'],
  },
  {
    'date': '2019-07-31',
    'category': 'banqueCentrale',
    'major': true,
    'title': 'La Fed baisse ses taux, une première depuis 2008',
    'body':
        'Baisse de 0,25 point pour soutenir l’économie face au ralentissement '
        'mondial et à la guerre commerciale.',
    'symbols': ['SPY', 'TLT', 'GLD'],
  },
  {
    'date': '2019-08-01',
    'category': 'politique',
    'title': 'Nouveaux droits de douane sur 300 milliards de produits chinois',
    'body':
        'Trump annonce une taxe de 10 % sur la quasi-totalité des importations '
        'chinoises restantes, téléphones et ordinateurs compris.',
    'symbols': ['AAPL', 'SPY'],
  },
  {
    'date': '2019-08-05',
    'category': 'geopolitique',
    'title': 'Guerre des monnaies : la Chine laisse filer le yuan',
    'body':
        'Le yuan passe sous les 7 pour un dollar et Washington accuse Pékin '
        'de manipuler sa monnaie. Le Dow Jones perd 767 points.',
    'symbols': ['SPY', 'GLD'],
  },
  {
    'date': '2019-08-14',
    'category': 'economie',
    'major': true,
    'title': 'Inversion de la courbe des taux, signal de récession',
    'body':
        'L’État américain emprunte plus cher à 2 ans qu’à 10 ans : par le '
        'passé, ce signal a souvent précédé une récession. Le Dow Jones perd '
        '800 points.',
    'symbols': ['SPY', 'TLT', 'GLD'],
  },
  {
    'date': '2019-09-16',
    'category': 'geopolitique',
    'title': 'Le pétrole bondit après une attaque en Arabie saoudite',
    'body':
        'Des drones ont frappé le 14 septembre les plus grandes installations '
        'pétrolières saoudiennes. Le prix du baril bondit de près de 15 %.',
    'symbols': ['XOM'],
  },
  {
    'date': '2019-10-24',
    'category': 'entreprise',
    'title': 'Tesla surprend avec un bénéfice, l’action gagne 17 %',
    'body':
        'Alors que beaucoup attendaient une perte, Tesla annonce un bénéfice '
        'trimestriel et une production en hausse.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2019-10-30',
    'category': 'banqueCentrale',
    'title': 'Troisième baisse des taux de la Fed en 2019',
    'body': 'Les taux directeurs sont ramenés entre 1,50 et 1,75 %.',
    'symbols': ['SPY', 'TLT'],
  },
  {
    'date': '2019-12-13',
    'category': 'politique',
    'major': true,
    'title': 'Accord commercial « de phase 1 » entre Washington et Pékin',
    'body':
        'Les États-Unis renoncent à de nouveaux droits de douane ; la Chine '
        's’engage à acheter davantage de produits américains.',
    'symbols': ['SPY', 'QQQ', 'AAPL'],
  },
  {
    'date': '2019-12-13',
    'category': 'geopolitique',
    'title': 'Victoire de Boris Johnson : le Brexit aura lieu',
    'body':
        'Avec une large majorité, le Premier ministre britannique fera sortir '
        'le Royaume-Uni de l’Union européenne le 31 janvier.',
    'symbols': ['EWQ'],
  },
  {
    'date': '2019-12-16',
    'category': 'entreprise',
    'title': 'Boeing suspend la production du 737 MAX',
    'body':
        'L’avion est toujours interdit de vol, sans date de retour. Les '
        'compagnies aériennes réclament des compensations.',
    'symbols': ['BA'],
  },
  {
    'date': '2019-12-31',
    'category': 'sante',
    'title': 'Pneumonie d’origine inconnue à Wuhan',
    'body':
        'La Chine signale à l’Organisation mondiale de la santé plusieurs cas '
        'de pneumonie inexpliquée dans la ville de Wuhan.',
    'symbols': <String>[],
  },
  // --- 2020 ------------------------------------------------------------------
  {
    'date': '2020-01-03',
    'category': 'geopolitique',
    'title': 'Les États-Unis tuent un général iranien',
    'body':
        'Qassem Soleimani est tué par une frappe américaine en Irak. L’Iran '
        'promet de se venger ; le pétrole et l’or montent.',
    'symbols': ['XOM', 'GLD'],
  },
  {
    'date': '2020-01-23',
    'category': 'sante',
    'major': true,
    'title': 'Wuhan, 11 millions d’habitants, placée en quarantaine',
    'body':
        'Un nouveau coronavirus se propage en Chine. Les transports de la '
        'ville sont arrêtés. Des cas apparaissent dans d’autres pays.',
    'symbols': ['SPY', 'BA', 'XOM'],
  },
  {
    'date': '2020-01-31',
    'category': 'geopolitique',
    'title': 'Le Royaume-Uni quitte l’Union européenne',
    'body': 'Une période de transition s’ouvre jusqu’à fin 2020.',
    'symbols': ['EWQ'],
  },
  {
    'date': '2020-02-04',
    'category': 'entreprise',
    'title': 'Tesla s’emballe',
    'body':
        'L’action a plus que doublé depuis le début du mois de décembre, '
        'portée par de bons résultats et la nouvelle usine de Shanghai.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2020-02-24',
    'category': 'sante',
    'major': true,
    'title': 'Le virus gagne l’Europe, Wall Street chute de 3 %',
    'body':
        'Des villes italiennes sont confinées. Le Dow Jones perd plus de '
        '1 000 points. L’Organisation mondiale de la santé parle d’un risque '
        'de pandémie.',
    'symbols': ['SPY', 'EWQ', 'BA'],
  },
  {
    'date': '2020-03-03',
    'category': 'banqueCentrale',
    'title': 'Baisse des taux en urgence par la Fed',
    'body':
        'Baisse de 0,5 point, sans attendre sa réunion prévue : une première '
        'depuis la crise de 2008.',
    'symbols': ['SPY', 'TLT', 'GLD'],
  },
  {
    'date': '2020-03-09',
    'category': 'geopolitique',
    'major': true,
    'title': 'Guerre des prix du pétrole, Wall Street s’effondre de 7,6 %',
    'body':
        'L’Arabie saoudite et la Russie ne s’entendent pas pour réduire leur '
        'production : le baril perd environ un quart de sa valeur. Les '
        'cotations sont suspendues 15 minutes pour la première fois depuis 1997.',
    'symbols': ['XOM', 'SPY'],
  },
  {
    'date': '2020-03-11',
    'category': 'sante',
    'title': 'L’OMS déclare une pandémie',
    'body':
        'Le Covid-19 touche plus de 100 pays. Les États-Unis suspendent la '
        'plupart des voyages depuis l’Europe.',
    'symbols': ['SPY', 'BA'],
  },
  {
    'date': '2020-03-12',
    'category': 'economie',
    'major': true,
    'title': 'Jeudi noir : le S&P 500 perd 9,5 %, le bitcoin s’effondre',
    'body':
        'Pire séance à Wall Street depuis 1987. Même les valeurs refuges sont '
        'vendues pour récupérer du cash : le bitcoin perd près de 40 % en '
        'une journée.',
    'symbols': ['SPY', 'QQQ', 'BTC/USD', 'ETH/USD', 'GLD'],
  },
  {
    'date': '2020-03-15',
    'category': 'banqueCentrale',
    'major': true,
    'title': 'La Fed ramène ses taux à zéro',
    'body':
        'Taux entre 0 et 0,25 %, et 700 milliards de dollars d’achats '
        'd’obligations. Le lendemain, le S&P 500 perd encore 12 %.',
    'symbols': ['SPY', 'TLT', 'GLD'],
  },
  {
    'date': '2020-03-23',
    'category': 'banqueCentrale',
    'title': 'La Fed promet des achats « sans limite »',
    'body':
        'La banque centrale achètera autant d’obligations que nécessaire pour '
        'faire fonctionner les marchés. La moitié de la planète est confinée.',
    'symbols': ['SPY', 'TLT'],
  },
  {
    'date': '2020-03-27',
    'category': 'politique',
    'title': 'Plan de relance américain de 2 200 milliards de dollars',
    'body':
        'Chèques aux ménages, aides aux entreprises, chômage renforcé : le '
        'plus grand plan de soutien de l’histoire des États-Unis.',
    'symbols': ['SPY'],
  },
  {
    'date': '2020-04-20',
    'category': 'economie',
    'major': true,
    'title': 'Le prix du pétrole devient négatif',
    'body':
        'Une première historique : le baril américain s’échange à −37 \$. Plus '
        'personne n’a de place pour stocker le pétrole que plus personne '
        'n’utilise.',
    'symbols': ['XOM'],
  },
  {
    'date': '2020-04-22',
    'category': 'entreprise',
    'title': 'Zoom revendique 300 millions de participants par jour',
    'body':
        'Contre 10 millions en décembre : écoles, entreprises et familles se '
        'retrouvent en visioconférence.',
    'symbols': ['ZM'],
  },
  {
    'date': '2020-05-18',
    'category': 'sante',
    'title': 'Premiers résultats encourageants pour un vaccin',
    'body':
        'Moderna annonce des anticorps chez ses premiers volontaires. Le Dow '
        'Jones gagne plus de 900 points.',
    'symbols': ['SPY', 'BA'],
  },
  {
    'date': '2020-06-08',
    'category': 'economie',
    'title': 'Les États-Unis officiellement en récession',
    'body':
        'Selon l’organisme chargé de la dater, la récession a commencé en '
        'février, mettant fin à 128 mois de croissance.',
    'symbols': ['SPY'],
  },
  {
    'date': '2020-07-21',
    'category': 'politique',
    'title': 'Plan de relance européen de 750 milliards d’euros',
    'body':
        'Pour la première fois, les pays de l’Union européenne vont emprunter '
        'ensemble pour financer la reprise.',
    'symbols': ['EWQ'],
  },
  {
    'date': '2020-07-31',
    'category': 'entreprise',
    'title': 'Apple bondit de 10 % après des résultats record',
    'body':
        'Malgré la pandémie, les ventes progressent. Apple annonce aussi la '
        'division de son action par quatre.',
    'symbols': ['AAPL'],
  },
  {
    'date': '2020-08-11',
    'category': 'entreprise',
    'title': 'Tesla divise son action par cinq',
    'body':
        'Chaque action deviendra cinq actions de valeur cinq fois plus '
        'petite. La valeur de l’entreprise ne change pas, mais l’action '
        'devient plus accessible.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2020-08-24',
    'category': 'entreprise',
    'title': 'ExxonMobil sort du Dow Jones après 92 ans',
    'body':
        'Le plus ancien membre de l’indice est remplacé, symbole du déclin '
        'du poids du pétrole dans l’économie.',
    'symbols': ['XOM'],
  },
  {
    'date': '2020-08-27',
    'category': 'banqueCentrale',
    'title': 'La Fed accepte une inflation un peu plus forte',
    'body':
        'Nouvelle stratégie : la banque centrale visera une inflation de 2 % '
        'en moyenne. Les taux devraient rester bas longtemps.',
    'symbols': ['TLT', 'GLD', 'SPY'],
  },
  {
    'date': '2020-09-01',
    'category': 'entreprise',
    'title': 'Zoom s’envole de 40 % en une séance',
    'body':
        'Son chiffre d’affaires a plus que quadruplé en un an. L’entreprise '
        'vaut désormais plus qu’IBM.',
    'symbols': ['ZM'],
  },
  {
    'date': '2020-09-08',
    'category': 'entreprise',
    'title': 'Tesla chute de 21 %',
    'body':
        'L’entreprise n’a pas été choisie pour entrer dans l’indice S&P 500, '
        'contrairement à ce qu’espéraient beaucoup d’investisseurs.',
    'symbols': ['TSLA'],
  },
  {
    'date': '2020-10-21',
    'category': 'crypto',
    'title': 'PayPal va permettre d’acheter des cryptomonnaies',
    'body':
        'Ses millions d’utilisateurs pourront acheter, détenir et vendre du '
        'bitcoin directement dans l’application.',
    'symbols': ['BTC/USD', 'ETH/USD'],
  },
  {
    'date': '2020-11-07',
    'category': 'politique',
    'major': true,
    'title': 'Joe Biden élu président des États-Unis',
    'body':
        'Quatre jours après le vote, les médias américains le déclarent '
        'vainqueur. Donald Trump conteste le résultat.',
    'symbols': ['SPY'],
  },
  {
    'date': '2020-11-09',
    'category': 'sante',
    'major': true,
    'title': 'Pfizer et BioNTech : un vaccin efficace à plus de 90 %',
    'body':
        'Les valeurs qui souffraient du Covid (compagnies aériennes, Boeing, '
        'pétrole) s’envolent ; celles qui en profitaient reculent : Zoom perd '
        '17 % dans la journée.',
    'symbols': ['SPY', 'BA', 'XOM', 'ZM', 'EWQ'],
  },
  {
    'date': '2020-11-16',
    'category': 'entreprise',
    'title': 'Tesla va entrer dans le S&P 500',
    'body':
        'L’entrée est prévue le 21 décembre : les fonds qui suivent l’indice '
        'devront acheter des actions Tesla.',
    'symbols': ['TSLA', 'SPY'],
  },
  {
    'date': '2020-11-18',
    'category': 'entreprise',
    'title': 'Le 737 MAX autorisé à revoler aux États-Unis',
    'body':
        'Après vingt mois d’interdiction et des modifications du logiciel '
        'mis en cause dans les deux accidents.',
    'symbols': ['BA'],
  },
  {
    'date': '2020-11-30',
    'category': 'crypto',
    'title': 'Le bitcoin dépasse son record de 2017',
    'body':
        'Trois ans après son précédent sommet, il retrouve les 19 800 \$. Des '
        'entreprises et des fonds commencent à en acheter.',
    'symbols': ['BTC/USD'],
  },
  {
    'date': '2020-12-11',
    'category': 'sante',
    'title': 'Premier vaccin contre le Covid autorisé aux États-Unis',
    'body': 'Les premières vaccinations commencent trois jours plus tard.',
    'symbols': ['SPY'],
  },
  {
    'date': '2020-12-16',
    'category': 'crypto',
    'title': 'Le bitcoin franchit les 20 000 \$',
    'body': 'Un seuil symbolique jamais atteint auparavant.',
    'symbols': ['BTC/USD'],
  },
  {
    'date': '2020-12-21',
    'category': 'entreprise',
    'title': 'Tesla fait son entrée dans le S&P 500',
    'body':
        'Elle y entre directement parmi les plus grosses entreprises de '
        'l’indice.',
    'symbols': ['TSLA', 'SPY'],
  },
];
