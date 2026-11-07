import 'dart:math';

enum GuessResult { tooLow, tooHigh, correct, outOfRange }

class GameState {
  const GameState({
    required this.secret,
    required this.attempts,
    required this.isComplete,
    this.lastResult,
    this.minimum = 1,
    this.maximum = 100,
  });

  final int secret;
  final int attempts;
  final bool isComplete;
  final GuessResult? lastResult;
  final int minimum;
  final int maximum;
}

class GameEngine {
  GameEngine({
    Random? random,
    int minimum = 1,
    int maximum = 100,
  })  : _random = random ?? Random.secure(),
        minimum = minimum,
        maximum = maximum {
    if (minimum >= maximum) {
      throw ArgumentError('minimum must be less than maximum.');
    }
  }

  final Random _random;
  final int minimum;
  final int maximum;

  GameState newGame() => GameState(
        secret: minimum + _random.nextInt(maximum - minimum + 1),
        attempts: 0,
        isComplete: false,
        minimum: minimum,
        maximum: maximum,
      );

  GameState restore({
    required int secret,
    required int attempts,
    required bool isComplete,
    int? savedMinimum,
    int? savedMaximum,
  }) {
    final restoredMinimum = savedMinimum ?? minimum;
    final restoredMaximum = savedMaximum ?? maximum;
    if (restoredMinimum < 1 ||
        restoredMaximum > 200 ||
        restoredMinimum > restoredMaximum ||
        secret < restoredMinimum ||
        secret > restoredMaximum ||
        attempts < 0) {
      throw ArgumentError('Saved game state is invalid.');
    }
    return GameState(
      secret: secret,
      attempts: attempts,
      isComplete: isComplete,
      minimum: restoredMinimum,
      maximum: restoredMaximum,
    );
  }

  /// Narrows the active interval after a miss when Range Scout is active.
  GameState applyRangeScoutHint(GameState state, int guess) {
    if (state.isComplete) return state;
    final nextMinimum = state.lastResult == GuessResult.tooLow
        ? (guess + 1 > state.minimum ? guess + 1 : state.minimum)
        : state.minimum;
    final nextMaximum = state.lastResult == GuessResult.tooHigh
        ? (guess - 1 < state.maximum ? guess - 1 : state.maximum)
        : state.maximum;
    if (nextMinimum > nextMaximum) return state;
    return GameState(
      secret: state.secret,
      attempts: state.attempts,
      isComplete: state.isComplete,
      lastResult: state.lastResult,
      minimum: nextMinimum,
      maximum: nextMaximum,
    );
  }

  GameState guess(GameState state, int value) {
    if (state.isComplete) return state;
    if (value < state.minimum || value > state.maximum) {
      return GameState(
        secret: state.secret,
        attempts: state.attempts,
        isComplete: false,
        lastResult: GuessResult.outOfRange,
        minimum: state.minimum,
        maximum: state.maximum,
      );
    }
    final result = value == state.secret
        ? GuessResult.correct
        : value < state.secret
            ? GuessResult.tooLow
            : GuessResult.tooHigh;
    return GameState(
      secret: state.secret,
      attempts: state.attempts + 1,
      isComplete: result == GuessResult.correct,
      lastResult: result,
      minimum: state.minimum,
      maximum: state.maximum,
    );
  }
}
