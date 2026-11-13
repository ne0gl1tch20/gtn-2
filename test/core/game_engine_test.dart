import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';

class FixedRandom implements Random {
  FixedRandom(this.value);
  final int value;

  @override
  bool nextBool() => value.isOdd;

  @override
  double nextDouble() => value.toDouble();

  @override
  int nextInt(int max) => value % max;
}

void main() {
  group('GameEngine', () {
    test('creates a game inside the configured range', () {
      final engine = GameEngine(random: FixedRandom(41));
      expect(engine.newGame().secret, 42);
    });

    test('tracks attempts and feedback', () {
      final engine = GameEngine(random: FixedRandom(41));
      final initial = engine.newGame();
      final low = engine.guess(initial, 10);
      expect(low.lastResult, GuessResult.tooLow);
      expect(low.attempts, 1);
      final high = engine.guess(low, 90);
      expect(high.lastResult, GuessResult.tooHigh);
      expect(high.attempts, 2);
      final won = engine.guess(high, 42);
      expect(won.lastResult, GuessResult.correct);
      expect(won.isComplete, isTrue);
      expect(won.attempts, 3);
    });

    test(
      'continues to the next target and keeps lifetime attempts after a win',
      () {
        final engine = GameEngine(random: FixedRandom(41));
        final initial = engine.newGame();
        final completed = engine.guess(initial, 42);
        final nextGame = GameEngine(random: FixedRandom(10)).newGame();

        final continued = engine.continueAfterCorrect(completed, nextGame);

        expect(continued.secret, 11);
        expect(continued.attempts, 1);
        expect(continued.isComplete, isFalse);
        expect(continued.lastResult, GuessResult.correct);
        expect(continued.minimum, 1);
        expect(continued.maximum, 100);
      },
    );

    test(
      'bot success advances the target without consuming player attempts',
      () {
        final engine = GameEngine(random: FixedRandom(41));
        final initial = engine.newGame();
        final completed = engine.guess(initial, 42);
        final nextGame = GameEngine(random: FixedRandom(10)).newGame();

        final continued = engine.continueAfterCorrect(
          completed,
          nextGame,
          attempts: 7,
        );

        expect(continued.secret, 11);
        expect(continued.attempts, 7);
        expect(continued.isComplete, isFalse);
      },
    );

    test('rejects advancing a game that was not won', () {
      final engine = GameEngine(random: FixedRandom(41));
      final initial = engine.newGame();
      final missed = engine.guess(initial, 10);
      expect(
        () => engine.continueAfterCorrect(missed, engine.newGame()),
        throwsArgumentError,
      );
    });

    test('clamps guesses below and above the active range like GTN1', () {
      final engine = GameEngine(random: FixedRandom(41));
      final initial = engine.newGame();

      final below = engine.guess(initial, -10);
      expect(below.lastResult, GuessResult.tooLow);
      expect(below.attempts, 1);

      final above = engine.guess(below, 150);
      expect(above.lastResult, GuessResult.tooHigh);
      expect(above.attempts, 2);
    });

    test('clamped edge guesses can match a target at the range boundary', () {
      final engine = GameEngine();
      final minimumTarget = engine.restore(
        secret: 1,
        attempts: 0,
        isComplete: false,
      );
      final maximumTarget = engine.restore(
        secret: 100,
        attempts: 0,
        isComplete: false,
      );

      expect(engine.guess(minimumTarget, -10).lastResult, GuessResult.correct);
      expect(engine.guess(maximumTarget, 150).lastResult, GuessResult.correct);
    });

    test('allows a single-value range as a valid GTN1 range', () {
      final engine = GameEngine(minimum: 7, maximum: 7);
      final game = engine.newGame();

      expect(game.secret, 7);
      expect(game.minimum, 7);
      expect(game.maximum, 7);
      expect(engine.guess(game, 7).lastResult, GuessResult.correct);
    });

    test('does not accept another guess after a completed round', () {
      final engine = GameEngine(random: FixedRandom(41));
      final initial = engine.newGame();
      final won = engine.guess(initial, 42);

      expect(engine.guess(won, 20), same(won));
    });

    test('Range Scout narrows and enforces the active guess interval', () {
      final engine = GameEngine();
      final game = engine.restore(
        secret: 75,
        attempts: 1,
        isComplete: false,
        savedMinimum: 1,
        savedMaximum: 100,
      );
      final afterMiss = engine.guess(game, 50);
      final narrowed = engine.applyRangeScoutHint(afterMiss, 50);
      expect(narrowed.minimum, 51);
      expect(narrowed.maximum, 100);
      final clampedMiss = engine.guess(narrowed, 50);
      expect(clampedMiss.lastResult, GuessResult.tooLow);
      expect(clampedMiss.attempts, narrowed.attempts + 1);
      expect(engine.guess(narrowed, 75).lastResult, GuessResult.correct);
      final lastPossible = engine.applyRangeScoutHint(
        engine.guess(
          engine.restore(
            secret: 75,
            attempts: 1,
            isComplete: false,
            savedMinimum: 1,
            savedMaximum: 75,
          ),
          74,
        ),
        74,
      );
      expect(lastPossible.minimum, 75);
      expect(lastPossible.maximum, 75);
      expect(engine.guess(lastPossible, 75).lastResult, GuessResult.correct);
    });

    test('rejects invalid restored state', () {
      final engine = GameEngine(random: FixedRandom(0));
      expect(
        () => engine.restore(secret: 101, attempts: 0, isComplete: false),
        throwsArgumentError,
      );
    });
  });
}
