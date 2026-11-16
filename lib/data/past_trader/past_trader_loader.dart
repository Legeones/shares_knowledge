import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/past_trader/past_trader.dart';

/// Lit la partie Past Trader embarquée (16 actifs, 2017-2020).
Future<TraderGameData> loadPastTraderGame() async {
  final text = await rootBundle.loadString(
    'assets/scenarios/past_trader_2018_2020.json',
  );
  return TraderGameData.fromJson(jsonDecode(text) as Map<String, dynamic>);
}
