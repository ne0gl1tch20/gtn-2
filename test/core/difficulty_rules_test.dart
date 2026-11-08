import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/difficulty_rules.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('GTN1 difficulty rules', () {
    test('uses canonical base ranges and reward multipliers', () {
      expect(DifficultyRules.baseRangeMaximum(DifficultyRules.classic), 100);
      expect(DifficultyRules.baseRangeMaximum(DifficultyRules.hard), 150);
      expect(DifficultyRules.baseRangeMaximum(DifficultyRules.extreme), 250);
      expect(DifficultyRules.rewardMultiplier(DifficultyRules.classic), 1.0);
      expect(DifficultyRules.rewardMultiplier(DifficultyRules.hard), 1.5);
      expect(DifficultyRules.rewardMultiplier(DifficultyRules.extreme), 2.5);
      expect(DifficultyRules.wrongGuessPenalty(DifficultyRules.hard), 0.02);
      expect(DifficultyRules.wrongGuessPenalty(DifficultyRules.extreme), 0.05);
    });

    test('better range reduces the maximum by five and never below fifty', () {
      expect(DifficultyRules.rangeMaximum('classic', 1), 95);
      expect(DifficultyRules.rangeMaximum('hard', 10), 100);
      expect(DifficultyRules.rangeMaximum('extreme', 20), 150);
      expect(DifficultyRules.rangeMaximum('extreme', 99), 150);
    });

    test('Hardcore doubles every difficulty range', () {
      for (final id in DifficultyRules.ids) {
        final base = DifficultyRules.rangeMaximum(id, 0);
        final hardcoreMaximum = base * 2;
        expect(hardcoreMaximum, lessThanOrEqualTo(500));
      }
    });

    test('Flutter game engine restores Extreme Hardcore saves up to 500', () {
      final engine = GameEngine(maximum: 500);
      final restored = engine.restore(
        secret: 487,
        attempts: 12,
        isComplete: false,
        savedMinimum: 1,
        savedMaximum: 500,
      );
      expect(restored.maximum, 500);
      expect(restored.secret, 487);
    });

    test('settings default to Classic and persist selected difficulty', () {
      final oldSettings = GameSettings.fromJson({
        'darkMode': true,
        'reduceMotion': false,
        'localeCode': 'en_us',
      });
      expect(oldSettings.difficultyId, DifficultyRules.classic);
      const settings = GameSettings(difficultyId: DifficultyRules.extreme);
      expect(GameSettings.fromJson(settings.toJson()).difficultyId, DifficultyRules.extreme);
    });

    test('settings reject unknown difficulty identifiers', () {
      expect(
        () => GameSettings.fromJson({
          'darkMode': true,
          'reduceMotion': false,
          'localeCode': 'en_us',
          'difficultyId': 'nightmare',
        }),
        throwsFormatException,
      );
    });
  });
}
