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
        'currentStreak': 2,
        'bestStreak': 4,
        'gamesWon': 5,
        'isComplete': false,
        'money': '12345678901234567890',
        'prestige': '2',
        'ultra': '1',
        'nebulaCurrency': '9',
        'prestigeCount': 2,
        'ultraCount': 1,
        'upgradeLevels': {'better_range': 3},
        'prestigeUpgradeLevels': {'reward_boost': 2},
        'ultraUpgradeLevels': {'ultra_power': 1},
        'defeatedBosses': ['grove_guardian'],
        'discoveredTraitIds': ['steady_hands'],
        'activeMutators': ['hardcore'],
        'talents': ['focused_mind'],
        'relicInventory': ['relic_seed'],
        'equippedRelicIds': ['relic_seed'],
        'selectedTraitArms': {'left': 'steady_hands'},
        'homeBaseLevel': 2,
        'lastSavedAt': 123456,
        'statistics': {
          'totalGuesses': 20,
          'correctGuesses': 3,
          'failedGuesses': 0,
          'moneyEarned': '500',
          'moneySpent': '100',
          'prestigesCount': 2,
          'ultrasCount': 1,
          'nebulaEarned': 9,
          'playtimeSeconds': 3600,
          'arcadePlayed': 0,
          'arcadeBestScores': <String, int>{},
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
          'musicPlaylistPaths': {'focus': ['track-a.mp3']},
          'musicRepeatMode': 'all',
          'musicShuffle': true,
          'moreScreenOrder': ['save_slots', 'settings'],
          'moreScreenButtonColors': {'save_slots': '#00BCD4'},
        },
      });

      expect(save.secret, 42);
      expect(save.minimum, 1);
      expect(save.maximum, 100);
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
      expect(save.progression.legacySystems.activeMutators, {'hardcore'});
      expect(save.progression.legacySystems.selectedTraitArms['left'], 'steady_hands');
      expect(save.progression.legacySystems.adaptiveTraitProfile.failedGuessesObserved, 17);
      expect(save.progression.legacySystems.adaptiveTraitProfile.helperUses['range_hint'], 2);
      expect(save.settings.difficultyId, 'hard');
      expect(save.settings.localeCode, 'en_us');
      expect(save.settings.reduceMotion, isTrue);
      expect(save.settings.musicLibraryPaths, ['track-a.mp3']);
      expect(save.settings.musicPlaylists['focus'], ['track-a.mp3']);
      expect(save.progression.playtimeSeconds, 3600);
    });

    test('rejects non-default fields with no GTN2 destination', () {
      expect(
        () => LegacyGtn1SaveAdapter.fromGameStateJson({
          'statistics': {'shopPurchases': [], 'failedGuesses': 2},
          'shopPurchases': ['nebula_boost'],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('statistics.failedGuesses'),
          ),
        ),
      );
    });

    test('rejects malformed source types and invalid GTN2 invariants', () {
      expect(
        () => LegacyGtn1SaveAdapter.fromGameStateJson({'attempts': 'many'}),
        throwsFormatException,
      );
      expect(
        () => LegacyGtn1SaveAdapter.fromGameStateJson({
          'currentRangeMin': 10,
          'currentRangeMax': 5,
          'targetNumber': 7,
        }),
        throwsFormatException,
      );
    });

    test('accepts absent legacy fields using GTN1 defaults', () {
      final save = LegacyGtn1SaveAdapter.fromGameStateJson({});
      expect(save.secret, 50);
      expect(save.maximum, 100);
      expect(save.progression.money.toString(), '0');
      expect(save.progression.legacySystems.adaptiveTraitProfile.schemaVersion, 1);
    });
  });
}
