/// Feedback-only bot ported from GTN1's GuessingBot.kt.
///
/// This class deliberately has no reference to GameState or the secret target.
/// Its only information comes from the range and feedback supplied by the game.
enum BotFeedback { tooLow, tooHigh, correct }

class GuessingBot {
  GuessingBot({int minimum = 1, int maximum = 100}) {
    reset(minimum, maximum);
  }

  int _lowerBound = 1;
  int _upperBound = 100;

  int get lowerBound => _lowerBound;
  int get upperBound => _upperBound;

  void reset(int minimum, int maximum) {
    if (minimum < 1 || maximum < minimum) {
      throw ArgumentError('Bot range must satisfy 1 <= minimum <= maximum.');
    }
    _lowerBound = minimum;
    _upperBound = maximum;
  }

  int nextGuess({required int rangeMinimum, required int rangeMaximum}) {
    if (rangeMinimum < 1 || rangeMaximum < rangeMinimum) {
      throw ArgumentError('Invalid game range.');
    }
    if (rangeMinimum != _lowerBound || rangeMaximum != _upperBound) {
      _lowerBound = rangeMinimum > _lowerBound ? rangeMinimum : _lowerBound;
      if (_lowerBound < 1) _lowerBound = 1;
      _upperBound = rangeMaximum < _upperBound ? rangeMaximum : _upperBound;
      if (_upperBound < _lowerBound) _upperBound = _lowerBound;
      if (_lowerBound > _upperBound) reset(rangeMinimum, rangeMaximum);
    }
    return _lowerBound + ((_upperBound - _lowerBound) ~/ 2);
  }

  void observeGuess(int guess, BotFeedback feedback) {
    switch (feedback) {
      case BotFeedback.tooLow:
        if (guess + 1 > _lowerBound) _lowerBound = guess + 1;
        break;
      case BotFeedback.tooHigh:
        if (guess - 1 < _upperBound) _upperBound = guess - 1;
        break;
      case BotFeedback.correct:
        break;
    }
    if (_lowerBound > _upperBound) reset(1, 100);
  }
}
