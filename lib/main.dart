import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/api/twelve_data_api.dart';
import 'data/local/app_database.dart';
import 'data/local/price_cache_dao.dart';
import 'data/playground/saved_simulation_dao.dart';
import 'data/past_trader/news_source.dart';
import 'data/foresight/foresight_loader.dart';
import 'data/past_trader/past_trader_loader.dart';
import 'data/past_trader/trader_attempt_dao.dart';
import 'logic/past_trader/news_feed.dart';
import 'data/repositories/price_repository.dart';
import 'providers/connectivity_provider.dart';
import 'providers/learn/lesson_progress_provider.dart';
import 'providers/playground/playground_provider.dart';
import 'providers/playground/saves_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/past_trader/trader_attempts_provider.dart';
import 'providers/past_trader/trader_save_provider.dart';
import 'data/wallet/wallet_dao.dart';
import 'providers/wallet/wallet_provider.dart';

Future<void> main() async {
  // Nécessaire pour SQLite avant runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsProvider(prefs);
  final lessonProgress = LessonProgressProvider(prefs);
  final saves = SavesProvider(SavedSimulationDao(db));
  await saves.load(); // les compteurs de l'accueil sont prêts dès l'affichage
  final attempts = TraderAttemptsProvider(TraderAttemptDao(db));
  await attempts.load();
  final foresight = await loadForesightCatalog(); // fichiers embarqués
  final pastTrader = await loadPastTraderGame();
  final news = NewsFeed(await const AssetNewsSource().load());
  final priceRepository = PriceRepository(
    TwelveDataApi(apiKey: twelveDataApiKey),
    PriceCacheDao(db),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: priceRepository),
        Provider.value(value: foresight),
        Provider.value(value: pastTrader),
        Provider.value(value: news),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: lessonProgress),
        ChangeNotifierProvider.value(value: saves),
        ChangeNotifierProvider.value(value: attempts),
        ChangeNotifierProvider(create: (_) => TraderSaveProvider(prefs)),
        // Chargé à la première ouverture de « Mon portefeuille ».
        ChangeNotifierProvider(
          create: (_) => WalletProvider(WalletDao(db), priceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaygroundProvider(
            priceRepository,
            // Chaque nouvelle simulation réussie met à jour le profil.
            onNewRunSucceeded: settings.recordPlaygroundRun,
          ),
        ),
      ],
      child: const SharesKnowledgeApp(),
    ),
  );
}
