import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/data/past_trader/news_source.dart';
import 'package:shares_knowledge/logic/past_trader/news_feed.dart';
import 'package:shares_knowledge/logic/time_cursor.dart';
import 'package:shares_knowledge/models/past_trader/news.dart';
import 'package:shares_knowledge/providers/past_trader/trader_game_controller.dart';

import '../helpers.dart';
import 'trading_test.dart' show fakeData;

NewsItem item(DateTime date, String title, {bool major = false}) => NewsItem(
  date: date,
  category: NewsCategory.economie,
  major: major,
  title: title,
  body: '',
  symbols: const ['ACT'],
);

void main() {
  final feed = NewsFeed([
    item(d(2024, 1, 3), 'C', major: true),
    item(d(2023, 12, 30), 'A'),
    item(d(2024, 1, 2), 'B'),
  ]);

  test('jamais d’actualité future, la plus récente en premier', () {
    expect(feed.until(d(2024, 1, 2)).map((n) => n.title), ['B', 'A']);
    expect(feed.until(d(2023, 1, 1)), isEmpty);
  });

  test('les nouvelles révélées par une avancée du temps', () {
    // 02/01 exclu (déjà vu), 03/01 inclus.
    expect(feed.between(d(2024, 1, 2), d(2024, 1, 3)).map((n) => n.title), [
      'C',
    ]);
  });

  test('actualités d’un actif', () {
    expect(feed.forSymbol('ACT', d(2024, 1, 3)), hasLength(3));
    expect(feed.forSymbol('AUTRE', d(2024, 1, 3)), isEmpty);
  });

  group('contrôleur de partie', () {
    late TraderGameController controller;
    setUp(() => controller = TraderGameController(fakeData(), feed));

    test('non lues : le contexte d’avant la partie compte', () {
      expect(controller.unreadCount, 1); // A (30/12)
      controller.markNewsRead();
      expect(controller.unreadCount, 0);
      controller.advance(TimeStep.day); // B
      expect(controller.unreadCount, 1);
    });

    test('seules les nouvelles majeures déclenchent un flash, une fois', () {
      controller.advance(TimeStep.day); // B (pas majeure)
      expect(controller.hasFlash, isFalse);
      controller.advance(TimeStep.day); // C (majeure)
      expect(controller.takeFlashes().map((n) => n.title), ['C']);
      expect(controller.hasFlash, isFalse);
    });
  });

  test('le vrai fil embarqué se lit et reste dans la période', () {
    final real = parseNews(
      File('assets/scenarios/past_trader_news.json').readAsStringSync(),
    );
    expect(real.length, greaterThan(50));
    expect(real.where((n) => n.major), isNotEmpty);
    expect(real.every((n) => n.date.isBefore(d(2021, 1, 1))), isTrue);
  });
}
