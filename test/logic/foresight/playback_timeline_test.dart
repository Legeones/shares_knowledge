import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shares_knowledge/logic/foresight/foresight.dart';
import 'package:shares_knowledge/models/foresight/foresight.dart';

/// Le parcours des années 1990 : des étapes de quelques semaines à 10 ans.
final scenario = ForesightScenario.fromJson(
  jsonDecode(
    File('assets/scenarios/foresight/foresight_1990s.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

void main() {
  final run = ForesightRun(scenario);
  final timeline = PlaybackTimeline(run);

  test('temps d’écran : au moins 4 s, 2,5 s par an, au plus 15 s', () {
    expect(PlaybackTimeline.stepMillis(0), 4000); // minimum
    expect(PlaybackTimeline.stepMillis(20), 4137); // 3 semaines
    expect(PlaybackTimeline.stepMillis(365), 6500); // 1 an
    expect(PlaybackTimeline.stepMillis(3650), 15000); // 10 ans : plafond
  });

  test('chaque étape a son temps, même très courte', () {
    // Une étape par segment : le total est la somme des temps d'écran.
    final expected = scenario.steps.length * 4000;
    expect(timeline.total.inMilliseconds, greaterThan(expected));
    expect(
      timeline.total.inMilliseconds,
      lessThanOrEqualTo(scenario.steps.length * 15000),
    );
  });

  test('début et fin de la lecture', () {
    expect(timeline.dayAt(Duration.zero), 0);
    expect(timeline.dayAt(timeline.total), run.days.length - 1);
  });

  test('l’étape courte de Tesla dure au moins 4 s à l’écran', () {
    final tesla = scenario.steps.indexWhere(
      (s) => s is AssetStep && s.name == 'Tesla',
    );
    final first = run.days.indexWhere((d) => d.stepIndex == tesla);
    final last = run.days.lastIndexWhere((d) => d.stepIndex == tesla);
    final shown = timeline.timeOf(last) - timeline.timeOf(first);
    expect(shown.inMilliseconds, greaterThanOrEqualTo(4000 - 50));
  });

  test('timeOf est l’inverse de dayAt (pour reprendre la lecture)', () {
    for (final index in [0, 100, 2000, run.days.length ~/ 2]) {
      expect(timeline.dayAt(timeline.timeOf(index)), index);
    }
  });
}
