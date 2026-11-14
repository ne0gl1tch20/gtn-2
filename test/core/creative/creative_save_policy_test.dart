import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_save_policy.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

SaveData creativeSave({
  int attempts = 8,
  int minimum = 1,
  int maximum = 100,
  int correctGuesses = 3,
  int currentStreak = 2,
  int bestStreak = 5,
  bool enabled = true,
}) => SaveData(
  secret: minimum + ((maximum - minimum) ~/ 2),
  attempts: attempts,
  gamesWon: 1,
  minimum: minimum,
  maximum: maximum,
  correctGuesses: correctGuesses,
  streak: currentStreak,
  bestStreak: bestStreak,
  creativeModeEnabled: enabled,
  progression: ProgressionState.initial.copyWith(
    totalGuesses: 100,
    correctGuesses: 50,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
  ),
);

GameUpgrade upgrade(String id, int maximum) => GameUpgrade(
  definition: UpgradeDefinition(
    id: id,
    baseCost: BigNumber.fromInt(1),
    growthRate: BigNumber.fromInt(2),
    maxLevel: maximum,
  ),
  name: id,
  description: id,
  effectPerLevel: 1,
);

void main() {
  group('CreativeSavePolicy', () {
    const emptyCatalog = <GameUpgrade>[];

    test('range update resets the active round like GTN1', () {
      final updated = CreativeSavePolicy.updateRange(
        current: creativeSave(),
        minimum: 20,
        maximum: 1000000,
      );

      expect(updated, isNotNull);
      expect(updated!.minimum, 20);
      expect(updated.maximum, 1000000);
      expect(updated.secret, 500010);
      expect(updated.attempts, 0);
      expect(updated.isComplete, isFalse);
      expect(updated.correctGuesses, 0);
      expect(updated.streak, 0);
      expect(updated.progression.totalGuesses, 100);
      expect(updated.progression.correctGuesses, 50);
      expect(updated.progression.currentStreak, 0);
      expect(updated.progression.bestStreak, 5);
    });

    test('rejects range edits for ordinary saves and invalid bounds', () {
      expect(
        CreativeSavePolicy.updateRange(
          current: creativeSave(enabled: false),
          minimum: 1,
          maximum: 100,
        ),
        isNull,
      );
      for (final bounds in [
        (minimum: 0, maximum: 100),
        (minimum: 101, maximum: 100),
        (minimum: 1, maximum: 1000001),
      ]) {
        expect(
          CreativeSavePolicy.updateRange(
            current: creativeSave(),
            minimum: bounds.minimum,
            maximum: bounds.maximum,
          ),
          isNull,
        );
      }
    });

    test('sets non-negative currencies using GTN1 suffix notation', () {
      final updated = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'money',
        value: '12.5K',
        upgrades: emptyCatalog,
        prestigeUpgrades: emptyCatalog,
        ultraUpgrades: emptyCatalog,
      );

      expect(updated?.progression.money, BigNumber.fromInt(12500));
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'nebula',
          value: '-1',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
      final unknownSuffix = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'money',
        value: '1XYZ',
        upgrades: emptyCatalog,
        prestigeUpgrades: emptyCatalog,
        ultraUpgrades: emptyCatalog,
      );
      // GTN1's BigNumber constructor maps unrecognized suffixes to zero.
      expect(unknownSuffix?.progression.money, BigNumber.fromInt(0));
    });

    test('validates attempts and correct guesses against each other', () {
      final attempts = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'attempts',
        value: '10',
        upgrades: emptyCatalog,
        prestigeUpgrades: emptyCatalog,
        ultraUpgrades: emptyCatalog,
      );
      expect(attempts?.attempts, 10);

      final correct = CreativeSavePolicy.updateValue(
        current: attempts!,
        key: 'correctGuesses',
        value: '9',
        upgrades: emptyCatalog,
        prestigeUpgrades: emptyCatalog,
        ultraUpgrades: emptyCatalog,
      );
      expect(correct?.correctGuesses, 9);
      expect(correct?.progression.correctGuesses, 50);
      expect(correct?.progression.totalGuesses, 100);

      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'attempts',
          value: '2',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'correctGuesses',
          value: '9',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
    });

    test('keeps best streak consistent with current streak', () {
      final raised = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'streak',
        value: '8',
        upgrades: emptyCatalog,
        prestigeUpgrades: emptyCatalog,
        ultraUpgrades: emptyCatalog,
      );
      expect(raised?.streak, 8);
      expect(raised?.bestStreak, 8);
      expect(raised?.progression.currentStreak, 8);
      expect(raised?.progression.bestStreak, 8);
      expect(raised?.progression.correctGuesses, 50);

      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(currentStreak: 8, bestStreak: 8),
          key: 'bestStreak',
          value: '7',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
    });

    test('validates each upgrade level against its own canonical catalog', () {
      final normal = upgrade('reward_multiplier', 20);
      final prestige = upgrade('prestige_gain_boost', 10);
      final ultra = upgrade('ultra_gain_boost', 5);

      final updated = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'upgradeLevel:reward_multiplier',
        value: '12',
        upgrades: [normal],
        prestigeUpgrades: [prestige],
        ultraUpgrades: [ultra],
      );
      expect(updated?.progression.upgrades['reward_multiplier'], 12);

      final prestigeUpdated = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'prestigeUpgradeLevel:prestige_gain_boost',
        value: '8',
        upgrades: [normal],
        prestigeUpgrades: [prestige],
        ultraUpgrades: [ultra],
      );
      expect(
        prestigeUpdated?.progression.prestigeUpgrades['prestige_gain_boost'],
        8,
      );

      final ultraUpdated = CreativeSavePolicy.updateValue(
        current: creativeSave(),
        key: 'ultraUpgradeLevel:ultra_gain_boost',
        value: '5',
        upgrades: [normal],
        prestigeUpgrades: [prestige],
        ultraUpgrades: [ultra],
      );
      expect(ultraUpdated?.progression.ultraUpgrades['ultra_gain_boost'], 5);

      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'prestigeUpgradeLevel:prestige_gain_boost',
          value: '11',
          upgrades: [normal],
          prestigeUpgrades: [prestige],
          ultraUpgrades: [ultra],
        ),
        isNull,
      );
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'ultraUpgradeLevel:unknown',
          value: '1',
          upgrades: [normal],
          prestigeUpgrades: [prestige],
          ultraUpgrades: [ultra],
        ),
        isNull,
      );
    });

    test('enforces the source input length and attempts ceiling', () {
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'money',
          value: List.filled(101, '1').join(),
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'attempts',
          value: '1000000000001',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
    });

    test('rejects all value edits for non-Creative saves and unknown keys', () {
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(enabled: false),
          key: 'money',
          value: '10',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
      expect(
        CreativeSavePolicy.updateValue(
          current: creativeSave(),
          key: 'not-a-source-field',
          value: '10',
          upgrades: emptyCatalog,
          prestigeUpgrades: emptyCatalog,
          ultraUpgrades: emptyCatalog,
        ),
        isNull,
      );
    });
  });
}
