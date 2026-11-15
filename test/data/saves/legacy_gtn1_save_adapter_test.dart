import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_save_adapter.dart';

void main() {
  group('LegacyGtn1SaveAdapter', () {
    test('maps GTN1 core state, settings, progression and adaptive memory', () {
      final save = LegacyGtn1SaveAdapter.fromGameStateJson({
        'difficultyId': 'hard',
        'profileName': 'Player One',
        'profileIconId': 'star',
        'targetNumber': 42,
        'currentRangeMin': 1,
        'currentRangeMax': 100,
        'attempts': 7,
        'correctGuesses': 3,
        'streak': 2,
        'bestStreak': 4,
        'gamesWon': 5,
        'isComplete': false,
        'money': '12345678901234567890',
        'prestige': '2',
        'ultra': '1',
        'nebula': '9',
        'prestigeCount': 2,
        'ultraCount': 1,
        'upgradeLevels': {'better_range': 3},
        'prestigeUpgradeLevels': {'reward_boost': 2},
        'ultraUpgradeLevels': {'ultra_power': 1},
        'defeatedBossIds': ['grove_guardian'],
        'discoveredTraitIds': ['steady_hands'],
        'activeMutators': ['hardcore'],
        'talents': ['focused_mind'],
        'relicInventory': ['relic_seed'],
        'equippedRelicIds': ['relic_seed'],
        'selectedTraitArms': {'left': 'steady_hands'},
        'homeBaseLevel': 2,
        'lastSaveTimestamp': 123456,
        'statistics': {
          'totalGuesses': 20,
          'correctGuesses': 3,
          'failedGuesses': 17,
          'arcadePlayed': 12,
          'arcadeBestScores': {'classic': 100},
          'moneyEarned': '500',
          'moneySpent': '100',
          'prestigesCount': 2,
          'ultrasCount': 1,
          'nebulaEarned': 9,
          'playtimeSeconds': 3600,
          'arcadePlayed': 0,
          'randomEventsTriggered': 4,
        },
        'traitProfile': {
          'schemaVersion': 1,
          'totalGuessesObserved': 20,
          'correctGuessesObserved': 3,
          'failedGuessesObserved': 17,
          'closeMissesObserved': 2,
          'longStreaksObserved': 1,
          'sessionsObserved': 4,
          'prestigesObserved': 2,
          'ultrasObserved': 1,
          'upgradesPurchasedObserved': 6,
          'moneyEarnedObserved': '500',
          'moneySpentObserved': '100',
          'consistencyScore': 0.5,
          'accuracyScore': 0.15,
          'riskScore': 0.2,
          'persistenceScore': 0.7,
          'progressionScore': 0.4,
          'helperUses': {'range_hint': 2},
          'helperCooldowns': {'range_hint': 1},
          'awardedBonuses': ['first_streak'],
        },
        'settings': {
          'themeMode': 'Dark',
          'locale': 'en-US',
          'reducedMotion': true,
          'musicEnabled': false,
          'musicLibraryPaths': ['track-a.mp3'],
          'musicQueuePaths': ['track-a.mp3'],
          'musicPlaylistPaths': {
            'focus': ['track-a.mp3'],
          },
          'musicRepeatMode': 'all',
          'musicShuffle': true,
          'moreScreenOrder': ['save_slots', 'settings'],
          'moreScreenButtonColors': {'save_slots': '#00BCD4'},
        },
      });

      expect(save.secret, 42);
      expect(save.minimum, 1);
      expect(save.maximum, 150);
      expect(save.attempts, 7);
      expect(save.correctGuesses, 3);
      expect(save.streak, 2);
      expect(save.bestStreak, 4);
      expect(save.gamesWon, 5);
      expect(save.profileName, 'Player One');
      expect(save.profileIconId, 'star');
      expect(save.progression.money.toString(), '12345678901234567890');
      expect(save.progression.prestige.toString(), '2');
      expect(save.progression.ultra.toString(), '1');
      expect(save.progression.nebula.toString(), '9');
      expect(save.progression.upgrades['better_range'], 3);
      expect(save.progression.prestigeResets, 2);
      expect(save.progression.defeatedBosses, {'grove_guardian'});
      expect(save.progression.legacySystems.activeMutators, {'hardcore'});
      expect(
        save.progression.legacySystems.selectedTraitArms['left'],
        'steady_hands',
      );
      expect(
        save
            .progression
            .legacySystems
            .adaptiveTraitProfile
            .failedGuessesObserved,
        17,
      );
      expect(
        save
            .progression
            .legacySystems
            .adaptiveTraitProfile
            .helperUses['range_hint'],
        2,
      );
      expect(save.settings.difficultyId, 'hard');
      expect(save.settings.localeCode, 'en_us');
      expect(save.settings.reduceMotion, isTrue);
      expect(save.settings.musicLibraryPaths, ['track-a.mp3']);
      expect(save.settings.musicPlaylistPaths['focus'], ['track-a.mp3']);
      expect(save.progression.playtimeSeconds, 3600);
      expect(
        save.progression.legacySystems.legacyGtn1Snapshot['shopPurchases'],
        isNull,
      );
      final sourceStats =
          save.progression.legacySystems.legacyGtn1Snapshot['statistics']
              as Map;
      expect(sourceStats['failedGuesses'], 17);
      expect(sourceStats['arcadePlayed'], 12);
      expect(sourceStats['arcadeBestScores']['classic'], 100);
    });

    test(
      'retains source-only statistics and shop fields for later round trips',
      () {
        final save = LegacyGtn1SaveAdapter.fromGameStateJson({
          'shopPurchases': ['range_boost'],
          'prestigeShopPurchases': ['prestige_reward'],
          'ultraShopPurchases': ['ultra_power'],
          'buyMultiplier': '10',
          'creativeAttemptLimit': 20,
          'creativeRewardMultiplier': 2.5,
          'lastSavedVersion': '1.4.0',
          'statistics': {
            'totalGuesses': 10,
            'correctGuesses': 4,
            'failedGuesses': 6,
            'arcadePlayed': 3,
            'arcadeBestScores': {'classic': 42},
          },
        });
        final snapshot = save.progression.legacySystems.legacyGtn1Snapshot;
        expect(snapshot['shopPurchases'], ['range_boost']);
        expect(snapshot['prestigeShopPurchases'], ['prestige_reward']);
        expect(snapshot['ultraShopPurchases'], ['ultra_power']);
        expect(snapshot['buyMultiplier'], '10');
        expect(snapshot['creativeAttemptLimit'], 20);
        expect(snapshot['creativeRewardMultiplier'], 2.5);
        expect(snapshot['lastSavedVersion'], '1.4.0');
        expect((snapshot['statistics'] as Map)['failedGuesses'], 6);
      },
    );

    test(
      'reverse serialization updates live state but retains source-only fields',
      () {
        final save = LegacyGtn1SaveAdapter.fromGameStateJson({
          'shopPurchases': ['range_boost'],
          'statistics': {
            'totalGuesses': 10,
            'correctGuesses': 4,
            'failedGuesses': 6,
            'arcadePlayed': 3,
            'arcadeBestScores': {'classic': 42},
          },
          'settings': {'locale': 'en-US', 'themeMode': 'Dark'},
        });
        final source = LegacyGtn1SaveAdapter.toGameStateJson(save);
        expect(source['shopPurchases'], ['range_boost']);
        expect(source['nebula'], '0');
        expect(source['streak'], 0);
        expect((source['statistics'] as Map)['failedGuesses'], 6);
        expect(
          (source['statistics'] as Map)['arcadeBestScores']['classic'],
          42,
        );
        expect((source['settings'] as Map)['locale'], 'en-US');
      },
    );

    test('rejects malformed source types and mirrors GTN1 negative-value sanitization', () {
      expect(
        () => LegacyGtn1SaveAdapter.fromGameStateJson({'attempts': 'many'}),
        throwsFormatException,
      );
      final sanitized = LegacyGtn1SaveAdapter.fromGameStateJson({
        'attempts': -1,
        'correctGuesses': -2,
        'streak': -3,
        'bestStreak': -4,
        'money': '-10',
        'prestige': '-2',
        'ultra': '-1',
        'nebula': '-9',
        'currentRangeMin': -10,
        'currentRangeMax': -5,
        'targetNumber': -1,
      });
      expect(sanitized.attempts, 0);
      expect(sanitized.correctGuesses, 0);
      expect(sanitized.streak, 0);
      expect(sanitized.bestStreak, 0);
      expect(sanitized.progression.money.toString(), '0');
      expect(sanitized.progression.prestige.toString(), '0');
      expect(sanitized.progression.ultra.toString(), '0');
      expect(sanitized.progression.nebula.toString(), '0');
      expect(sanitized.minimum, 1);
      expect(sanitized.maximum, 100);
      expect(sanitized.secret, 1);
    });

    test('accepts absent legacy fields using GTN1 defaults', () {
      final save = LegacyGtn1SaveAdapter.fromGameStateJson({});
      expect(save.secret, 50);
      expect(save.maximum, 100);
      expect(save.progression.money.toString(), '0');
      expect(
        save.progression.legacySystems.adaptiveTraitProfile.schemaVersion,
        1,
      );
    });
  });
}
