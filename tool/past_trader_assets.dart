// Contenu de la partie Past Trader « 2018-2020 » : période et actifs
// proposés. Les descriptions ne disent que ce qu'on savait au début de 2018.
//
// À modifier ici, puis régénérer avec :
//   dart run tool/build_past_trader.dart

const game = {
  'id': 'free_2018_2020',
  'title': '2018 – 2020 : trois ans de marché',
  'intro':
      'Nous sommes le 2 janvier 2018. Tu disposes de 10 000 \$ et de trois '
      'ans devant toi. Achète, vends, change d’avis, garde du cash : comme '
      'dans la vraie vie, tu ne connais que le passé et l’actualité du jour.',
  'start': '2018-01-02',
  'end': '2020-12-31',
  // Six mois d'historique visibles avant le début, pour se faire une idée.
  'historyFrom': '2017-07-03',
  'initialCash': 10000,
};

const assets = [
  {
    'symbol': 'SPY',
    'name': 'S&P 500',
    'type': 'etf',
    'description':
        'Les 500 plus grandes entreprises américaines dans un seul produit.',
  },
  {
    'symbol': 'QQQ',
    'name': 'Nasdaq-100',
    'type': 'etf',
    'description':
        'Les 100 plus grandes entreprises non financières du Nasdaq, surtout '
        'technologiques.',
  },
  {
    'symbol': 'EWQ',
    'name': 'Actions françaises',
    'type': 'etf',
    'description':
        'Les grandes entreprises françaises (ETF MSCI France, proche du '
        'CAC 40), coté en dollars.',
  },
  {
    'symbol': 'GLD',
    'name': 'Or',
    'type': 'etf',
    'description': 'Suit le prix de l’or, souvent vu comme une valeur refuge.',
  },
  {
    'symbol': 'TLT',
    'name': 'Obligations d’État US',
    'type': 'etf',
    'description':
        'Obligations de l’État américain à plus de 20 ans : leur prix monte '
        'quand les taux d’intérêt baissent.',
  },
  {
    'symbol': 'AAPL',
    'name': 'Apple',
    'type': 'stock',
    'description': 'iPhone, Mac et services.',
  },
  {
    'symbol': 'AMZN',
    'name': 'Amazon',
    'type': 'stock',
    'description': 'Commerce en ligne et cloud (AWS).',
  },
  {
    'symbol': 'TSLA',
    'name': 'Tesla',
    'type': 'stock',
    'description':
        'Voitures électriques. L’entreprise n’a encore jamais dégagé de '
        'bénéfice sur une année entière.',
  },
  {
    'symbol': 'NVDA',
    'name': 'Nvidia',
    'type': 'stock',
    'description':
        'Processeurs graphiques pour les jeux vidéo, les centres de données… '
        'et le minage de cryptomonnaies.',
  },
  {
    'symbol': 'BA',
    'name': 'Boeing',
    'type': 'stock',
    'description': 'Avions de ligne (737, 787) et défense.',
  },
  {
    'symbol': 'XOM',
    'name': 'ExxonMobil',
    'type': 'stock',
    'description':
        'Pétrole et gaz : l’une des plus grandes compagnies au monde.',
  },
  {
    'symbol': 'KO',
    'name': 'Coca-Cola',
    'type': 'stock',
    'description': 'Boissons. Entreprise réputée stable.',
  },
  {
    'symbol': 'ZM',
    'name': 'Zoom',
    'type': 'stock',
    'description':
        'Visioconférence pour entreprises. Cotée en Bourse à partir '
        'd’avril 2019.',
  },
  {
    'symbol': 'BTC/USD',
    'name': 'Bitcoin',
    'type': 'crypto',
    'description':
        'Première cryptomonnaie, cotée tous les jours. Sa valeur a été '
        'multipliée par plus de 10 en 2017.',
  },
  {
    'symbol': 'ETH/USD',
    'name': 'Ethereum',
    'type': 'crypto',
    'description':
        'Deuxième cryptomonnaie, plateforme de « contrats intelligents ». '
        'Données disponibles à partir du 17 janvier 2018.',
  },
  {
    'symbol': 'DOGE/USD',
    'name': 'Dogecoin',
    'type': 'crypto',
    'description':
        'Cryptomonnaie née d’un mème. Données disponibles à partir de '
        'mars 2020.',
  },
];
