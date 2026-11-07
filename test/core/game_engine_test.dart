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

    test('does not count invalid guesses or guesses after winning', () {
      final engine = GameEngine(random: FixedRandom(41));
      final initial = engine.newGame();
      final invalid = engine.guess(initial, 101);
      expect(invalid.lastResult, GuessResult.outOfRange);
      expect(invalid.attempts, 0);
      final won = engine.guess(initial, 42);
      expect(engine.guess(won, 20), same(won));
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
