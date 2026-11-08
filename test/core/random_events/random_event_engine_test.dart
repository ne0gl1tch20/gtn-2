import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/core/random_events/random_event_engine.dart';

class _FixedRandom implements Random {
  _FixedRandom({this.roll = 0, this.index = 0});

  final double roll;
  final int index;

  @override
  bool nextBool() => roll < 0.5;

  @override
  double nextDouble() => roll;

  @override
  int nextInt(int max) => index % max;
}

void main() {
  group('GTN1 random-event selector', () {
    test('uses the original 35 percent trigger chance', () {
      expect(
        RandomEventSelector(random: _FixedRandom(roll: 0.349)).roll(),
        RandomEventType.cashBurst,
      );
      expect(
        RandomEventSelector(random: _FixedRandom(roll: 0.35)).roll(),
        isNull,
      );
    });

    test('selects from all seven GTN1 event types', () {
      final selected = RandomEventSelector(
        random: _FixedRandom(roll: 0, index: 6),
      ).roll();

      expect(selected, RandomEventType.cosmicGift);
      expect(RandomEventSelector.eventTypes, hasLength(7));
    });
  });

  group('GTN1 random-event rewards', () {
    final base = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000),
      moneySpent: BigNumber.fromInt(10000),
      currentStreak: 4,
      bestStreak: 5,
    );

    RandomEventResult apply(RandomEventType type, {int index = 0}) =>
        RandomEventEngine(random: _FixedRandom(index: index)).apply(
          progression: base,
          currentRangeMin: 10,
          currentRangeMax: 100,
          event: type,
        );

    test('Cash Burst grants the greater of 100 Money or 10 percent', () {
      final result = apply(RandomEventType.cashBurst);

      expect(result.progression.money.toString(), '1100');
      expect(result.progression.moneyEarned.toString(), '100');
    });

    test('Nebula Rain grants a random integer from 10 through 50', () {
      final result = apply(RandomEventType.nebulaRain, index: 40);

      expect(result.progression.nebula.toString(), '50');
      expect(result.progression.nebulaEarned.toString(), '50');
    });

    test('Jackpot scales with the current maximum range', () {
      final result = apply(RandomEventType.jackpot);

      expect(result.progression.money.toString(), '101000');
      expect(result.progression.moneyEarned.toString(), '100000');
    });

    test('Streak Surge adds two and updates the best streak', () {
      final result = apply(RandomEventType.streakSurge);

      expect(result.progression.currentStreak, 6);
      expect(result.progression.bestStreak, 6);
    });

    test('Range Shuffle chooses a secret inside the inclusive current range', () {
      final result = apply(RandomEventType.rangeShuffle, index: 10);

      expect(result.newSecret, 20);
    });

    test('Tax Refund grants the greater of 100 Money or five percent spent', () {
      final result = apply(RandomEventType.taxRefund);

      expect(result.progression.money.toString(), '1500');
      expect(result.progression.moneyEarned.toString(), '500');
    });

    test('Cosmic Gift grants 100 Nebula', () {
      final result = apply(RandomEventType.cosmicGift);

      expect(result.progression.nebula.toString(), '100');
      expect(result.progression.nebulaEarned.toString(), '100');
    });

    test('every applied event persists its ID and increments the event count', () {
      for (final event in RandomEventType.values) {
        final result = apply(event);

        expect(result.progression.legacySystems.lastRandomEventId, event.id);
        expect(result.progression.legacySystems.randomEventsTriggered, 1);
      }
    });

    test('rejects an invalid active range', () {
      expect(
        () => RandomEventEngine().apply(
          progression: base,
          currentRangeMin: 0,
          currentRangeMax: 100,
          event: RandomEventType.rangeShuffle,
        ),
        throwsArgumentError,
      );
    });
  });
}
