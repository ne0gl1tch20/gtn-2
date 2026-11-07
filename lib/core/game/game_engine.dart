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
  }) {
    if (secret < minimum || secret > maximum || attempts < 0) {
      throw ArgumentError('Saved game state is invalid.');
    }
    return GameState(
      secret: secret,
      attempts: attempts,
      isComplete: isComplete,
      minimum: minimum,
      maximum: maximum,
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
