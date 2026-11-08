import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/automation/guessing_bot.dart';
import 'package:gtn_2/core/automation/offline_earnings_policy.dart';

void main() {
  group('GTN1 feedback-driven guessing bot', () {
    test('uses a midpoint without receiving or reading the secret', () {
      final bot = GuessingBot(minimum: 1, maximum: 100);
      expect(bot.nextGuess(rangeMinimum: 1, rangeMaximum: 100), 50);
      bot.observeGuess(50, BotFeedback.tooLow);
      expect(bot.lowerBound, 51);
      expect(bot.upperBound, 100);
      expect(bot.nextGuess(rangeMinimum: 1, rangeMaximum: 100), 75);
      bot.observeGuess(75, BotFeedback.tooHigh);
      expect(bot.lowerBound, 51);
      expect(bot.upperBound, 74);
      expect(bot.nextGuess(rangeMinimum: 1, rangeMaximum: 100), 62);
    });

    test('honors a changing game range and supports singleton ranges', () {
      final bot = GuessingBot(minimum: 1, maximum: 500);
      expect(bot.nextGuess(rangeMinimum: 100, rangeMaximum: 200), 150);
      expect(bot.nextGuess(rangeMinimum: 173, rangeMaximum: 173), 173);
    });

    test('rejects invalid ranges and guesses outside the current interval', () {
      expect(() => GuessingBot(minimum: 0), throwsArgumentError);
      final bot = GuessingBot();
      expect(
        () => bot.nextGuess(rangeMinimum: 0, rangeMaximum: 100),
        throwsArgumentError,
      );
      expect(
        () => bot.observeGuess(101, BotFeedback.tooHigh),
        throwsArgumentError,
      );
    });

    test('correct feedback does not change the learned interval', () {
      final bot = GuessingBot();
      bot.observeGuess(50, BotFeedback.correct);
      expect(bot.lowerBound, 1);
      expect(bot.upperBound, 100);
    });
  });

  group('GTN1 offline earnings policy', () {
    test('awards 500 Money per effective second while automation was active', () {
      expect(
        OfflineEarningsPolicy.calculate(
          autoClickerWasActive: true,
          elapsedSeconds: 60,
        ).toString(),
        '30000',
      );
    });

    test('caps catch-up at eight hours', () {
      expect(OfflineEarningsPolicy.effectiveSeconds(999999), 28800);
      expect(
        OfflineEarningsPolicy.calculate(
          autoClickerWasActive: true,
          elapsedSeconds: 999999,
        ).toString(),
        '14400000',
      );
    });

    test('disables earnings when automation was inactive', () {
      expect(
        OfflineEarningsPolicy.calculate(
          autoClickerWasActive: false,
          elapsedSeconds: 3600,
        ).toString(),
        '0',
      );
    });

    test('clamps negative elapsed time to zero', () {
      expect(OfflineEarningsPolicy.effectiveSeconds(-30), 0);
      expect(
        OfflineEarningsPolicy.calculate(
          autoClickerWasActive: true,
          elapsedSeconds: -30,
        ).toString(),
        '0',
      );
    });
  });
}
