import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/events/random_event_engine.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

BigNumber n(String value) => BigNumber.parse(value);

void main() {
  group('RandomEventEngine', () {
    final game = GameState(
      secret: 50,
      attempts: 4,
      isComplete: false,
      lastResult: GuessResult.tooLow,
      minimum: 1,
      maximum: 100,
    );

    test('cash burst awards the greater of 100 or ten percent', () {
      final engine = RandomEventEngine(random: Random(1));
      final small = engine.apply(
        progression: ProgressionState(money: n('500')),
        game: game,
        type: RandomEventType.cashBurst,
      );
      expect(small.progression.money.toString(), '600');
      expect(small.progression.moneyEarned.toString(), '100');

      final large = engine.apply(
        progression: ProgressionState(money: n('2000')),
        game: game,
        type: RandomEventType.cashBurst,
      );
      expect(large.progression.money.toString(), '2200');
      expect(large.progression.moneyEarned.toString(), '200');
    });

    test('Nebula Rain awards an inclusive random amount from 10 to 50', () {
      final result = RandomEventEngine(random: Random(4)).apply(
        progression: ProgressionState(),
        game: game,
        type: RandomEventType.nebulaRain,
      );
      final reward = int.parse(result.progression.nebula.toString());
      expect(reward, inInclusiveRange(10, 50));
      expect(result.progression.nebulaEarned, result.progression.nebula);
    });

    test('Jackpot scales by one thousand times the current maximum', () {
      final result = RandomEventEngine().apply(
        progression: ProgressionState(),
        game: game,
        type: RandomEventType.jackpot,
      );
      expect(result.progression.money.toString(), '100000');
      expect(result.progression.moneyEarned.toString(), '100000');
    });

    test('Streak Surge adds two and preserves the best streak', () {
      final result = RandomEventEngine().apply(
        progression: ProgressionState(currentStreak: 3, bestStreak: 8),
        game: game,
        type: RandomEventType.streakSurge,
      );
      expect(result.progression.currentStreak, 5);
      expect(result.progression.bestStreak, 8);
    });

    test(
      'Range Shuffle changes only the target within the active interval',
      () {
        final result = RandomEventEngine(random: Random(12)).apply(
          progression: ProgressionState(),
          game: game,
          type: RandomEventType.rangeShuffle,
        );
        expect(result.game.secret, inInclusiveRange(1, 100));
        expect(result.game.attempts, game.attempts);
        expect(result.game.minimum, game.minimum);
        expect(result.game.maximum, game.maximum);
        expect(result.game.lastResult, game.lastResult);
        expect(result.progression.money, n('0'));
      },
    );

    test(
      'Tax Refund uses five percent of lifetime money spent with a 100 floor',
      () {
        final small = RandomEventEngine().apply(
          progression: ProgressionState(moneySpent: n('1000')),
          game: game,
          type: RandomEventType.taxRefund,
        );
        expect(small.progression.money.toString(), '100');
        expect(small.progression.moneyEarned.toString(), '100');

        final large = RandomEventEngine().apply(
          progression: ProgressionState(moneySpent: n('10000')),
          game: game,
          type: RandomEventType.taxRefund,
        );
        expect(large.progression.money.toString(), '500');
        expect(large.progression.moneyEarned.toString(), '500');
      },
    );

    test('Cosmic Gift awards 100 Nebula', () {
      final result = RandomEventEngine().apply(
        progression: ProgressionState(),
        game: game,
        type: RandomEventType.cosmicGift,
      );
      expect(result.progression.nebula.toString(), '100');
      expect(result.progression.nebulaEarned.toString(), '100');
    });

    test('every applied event increments the count and stores its save ID', () {
      final result = RandomEventEngine().apply(
        progression: ProgressionState(randomEventsTriggered: 4),
        game: game,
        type: RandomEventType.cosmicGift,
      );
      expect(result.progression.randomEventsTriggered, 5);
      expect(result.progression.lastRandomEventId, 'cosmic_gift');
      expect(
        result.progression
            .copyWith(clearLastRandomEventId: true)
            .lastRandomEventId,
        isNull,
      );
    });

    test('Streak Surge state survives save and reload', () {
      final surged = RandomEventEngine().apply(
        progression: ProgressionState(currentStreak: 3, bestStreak: 3),
        game: game,
        type: RandomEventType.streakSurge,
      ).progression;
      final restored = ProgressionState.fromJson(
        Map<String, dynamic>.from(surged.toJson()),
      );
      expect(restored.currentStreak, 5);
      expect(restored.bestStreak, 5);
      expect(restored.correctGuesses, 0);
    });

    test('Lua event IDs are closed and unknown IDs are rejected', () {
      expect(randomEventTypeFromLuaId('CASH_BURST'), RandomEventType.cashBurst);
      expect(
        randomEventTypeFromLuaId('COSMIC_GIFT'),
        RandomEventType.cosmicGift,
      );
      expect(randomEventTypeFromLuaId('UNTRUSTED_REWARD'), isNull);
      expect(randomEventTypeFromLuaId(null), isNull);
    });

    test('old saves default the new event statistics safely', () {
      final oldSave = ProgressionState().toJson()
        ..remove('moneySpent')
        ..remove('randomEventsTriggered')
        ..remove('lastRandomEventId');
      final restored = ProgressionState.fromJson(
        Map<String, dynamic>.from(oldSave),
      );
      expect(restored.moneySpent, n('0'));
      expect(restored.randomEventsTriggered, 0);
      expect(restored.lastRandomEventId, isNull);
    });

    test('save rejects random event IDs outside the approved catalog', () {
      final invalidSave = ProgressionState().toJson()
        ..['lastRandomEventId'] = 'admin_override';
      expect(
        () => ProgressionState.fromJson(Map<String, dynamic>.from(invalidSave)),
        throwsFormatException,
      );
    });

    test('new event statistics round trip through the save model', () {
      final state = ProgressionState(
        moneySpent: n('12345'),
        randomEventsTriggered: 7,
        lastRandomEventId: 'nebula_rain',
      );
      final restored = ProgressionState.fromJson(
        Map<String, dynamic>.from(state.toJson()),
      );
      expect(restored.moneySpent, n('12345'));
      expect(restored.randomEventsTriggered, 7);
      expect(restored.lastRandomEventId, 'nebula_rain');
    });
  });
}
