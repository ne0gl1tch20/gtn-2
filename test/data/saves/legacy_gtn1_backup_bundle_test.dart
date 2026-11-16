import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_backup_bundle.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_save_adapter.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('LegacyGtn1BackupBundle', () {
    test('round-trips all ten-slot bundle sections and global preferences', () {
      final settings = GameSettings.initial.copyWith(
        localeCode: 'en_us',
        themeMode: 'Dark',
        updateCheckIntervalHours: 6,
      );
      final creative = CreativeModeSave(
        name: 'Sandbox',
        enabled: true,
        rangeMin: 10,
        rangeMax: 900,
        effects: const [
          CreativeModeEffect(
            id: 'extra-hints',
            type: CreativeEffectType.extraHints,
            value: 2,
          ),
        ],
      );
      final save = SaveData(
        secret: 42,
        attempts: 7,
        correctGuesses: 3,
        streak: 2,
        bestStreak: 4,
        gamesWon: 5,
        settings: settings,
        profileName: 'Player One',
        profileIconId: 'star',
        creativeMode: creative,
        progression: ProgressionState(
          money: BigNumber.parse('12345678901234567890'),
          nebulaItems: const {'golden_guess': 1},
          totalGuesses: 20,
          correctGuesses: 3,
          moneyEarned: BigNumber.parse('500'),
          moneySpent: BigNumber.parse('100'),
          legacySystems: LegacySystemsState.initial.copyWith(
            legacyGtn1Snapshot: {
              'shopPurchases': ['old_shop_item'],
              'statistics': {
                'arcadePlayed': 12,
                'arcadeBestScores': {'classic': 100},
              },
            },
          ),
        ),
      );
      final bundle = LegacyGtn1BackupBundle(
        formatVersion: 3,
        appPreferences: settings,
        activeSlot: 2,
        slots: {2: save},
        backups: {1: save.copyWith(secret: 25)},
        creativeSlots: {2: creative},
      );

      final decoded = LegacyGtn1BackupBundle.decode(bundle.encode());

      expect(decoded.formatVersion, 3);
      expect(decoded.activeSlot, 2);
      expect(decoded.appPreferences.localeCode, 'en_us');
      expect(decoded.appPreferences.updateCheckIntervalHours, 6);
      expect(decoded.slots[2]!.secret, 42);
      expect(decoded.slots[2]!.gamesWon, 5);
      expect(decoded.slots[2]!.isComplete, false);
      expect(
        decoded.slots[2]!.progression.money.toString(),
        '12345678901234567890',
      );
      expect(decoded.slots[2]!.progression.nebulaItems, {'golden_guess': 1});
      expect(decoded.creativeSlots[2]!.name, 'Sandbox');
      expect(decoded.backups[1]!.secret, 25);
      final retained =
          decoded.slots[2]!.progression.legacySystems.legacyGtn1Snapshot;
      expect(retained['shopPurchases'], ['old_shop_item']);
      final retainedStatistics = Map<String, dynamic>.from(
        retained['statistics'] as Map,
      );
      final retainedScores = Map<String, dynamic>.from(
        retainedStatistics['arcadeBestScores'] as Map,
      );
      expect(retainedScores['classic'], 100);
    });

    test('decodes an independently shaped GTN1 v3 bundle fixture', () {
      final sourceSettings = {
        'themeMode': 'Dark',
        'locale': 'en-US',
        'musicEnabled': false,
        'musicLibraryPaths': ['source-track.mp3'],
        'musicQueuePaths': ['source-track.mp3'],
        'musicPlaylistPaths': {
          'focus': ['source-track.mp3'],
        },
        'musicRepeatMode': 'all',
        'musicShuffle': true,
        'moreScreenOrder': ['save_slots', 'settings'],
      };
      final sourceSave = {
        'difficultyId': 'hard',
        'profileName': 'GTN1 fixture',
        'profileIconId': 'star',
        'targetNumber': 77,
        'currentRangeMin': 1,
        'currentRangeMax': 150,
        'attempts': 9,
        'correctGuesses': 2,
        'streak': 3,
        'bestStreak': 5,
        'gamesWon': 4,
        'isComplete': false,
        'money': '98765432101234567890',
        'prestige': '2',
        'ultra': '1',
        'nebula': '3',
        'prestigeCount': 2,
        'ultraCount': 1,
        'upgradeLevels': {'better_range': 1},
        'shopPurchases': ['shop_token'],
        'prestigeShopPurchases': ['prestige_token'],
        'ultraShopPurchases': ['ultra_token'],
        'lastSavedVersion': '1.2.3',
        'statistics': {
          'totalGuesses': 20,
          'correctGuesses': 2,
          'failedGuesses': 11,
          'moneyEarned': '10000',
          'moneySpent': '124',
          'prestigesCount': 2,
          'ultrasCount': 1,
          'nebulaEarned': 33,
          'playtimeSeconds': 1234,
          'arcadePlayed': 4,
          'arcadeBestScores': {'classic': 99},
          'randomEventsTriggered': 5,
        },
        'settings': {'themeMode': 'System', 'locale': 'en-US'},
      };
      const sourceCreative = {
        'schemaVersion': 3,
        'name': 'Source Creative slot',
        'enabled': true,
        'rangeMin': 25,
        'rangeMax': 900,
        'effects': [
          {'id': 'extra-hints', 'type': 'EXTRA_HINTS', 'value': 2},
        ],
        'activeRun': null,
      };
      final raw = jsonEncode({
        'formatVersion': 3,
        'appPreferencesJson': jsonEncode(sourceSettings),
        'activeSlot': 3,
        'slots': {'3': jsonEncode(sourceSave)},
        'backups': {
          '3': jsonEncode({...sourceSave, 'targetNumber': 60}),
        },
        'creativeSlots': {'3': jsonEncode(sourceCreative)},
      });

      final decoded = LegacyGtn1BackupBundle.decode(raw);
      final save = decoded.slots[3]!;
      expect(decoded.activeSlot, 3);
      expect(decoded.appPreferences.localeCode, 'en_us');
      expect(decoded.appPreferences.musicLibraryPaths, ['source-track.mp3']);
      expect(save.secret, 77);
      expect(save.progression.money.toString(), '98765432101234567890');
      expect(
        save.progression.legacySystems.legacyGtn1Snapshot['shopPurchases'],
        ['shop_token'],
      );
      final stats = Map<String, dynamic>.from(
        save.progression.legacySystems.legacyGtn1Snapshot['statistics'] as Map,
      );
      expect(stats['failedGuesses'], 11);
      expect(stats['arcadePlayed'], 4);
      expect(decoded.creativeSlots[3]!.name, 'Source Creative slot');

      final redecoded = LegacyGtn1BackupBundle.decode(decoded.encode());
      final reencodedSource = LegacyGtn1SaveAdapter.toGameStateJson(
        redecoded.slots[3]!,
      );
      expect(reencodedSource['shopPurchases'], ['shop_token']);
      final reencodedStats = Map<String, dynamic>.from(
        reencodedSource['statistics'] as Map,
      );
      expect(reencodedStats['failedGuesses'], 11);
      expect(reencodedStats['arcadePlayed'], 4);
      expect(redecoded.creativeSlots[3]!.effects.single.value, 2);
    });

    test('rejects malformed maps, unsupported versions and invalid slots', () {
      final settings = jsonEncode(
        LegacyGtn1BackupBundle(
          formatVersion: 3,
          appPreferences: GameSettings.initial,
          activeSlot: 1,
          slots: const {},
          backups: const {},
          creativeSlots: const {},
        ).appPreferences.toJson(),
      );

      expect(
        () => LegacyGtn1BackupBundle.decode(
          jsonEncode({
            'formatVersion': 4,
            'appPreferencesJson': settings,
            'activeSlot': 1,
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => LegacyGtn1BackupBundle.decode(
          jsonEncode({
            'formatVersion': 3,
            'appPreferencesJson': settings,
            'activeSlot': 1,
            'slots': {'11': '{}'},
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => LegacyGtn1BackupBundle.decode(
          jsonEncode({
            'formatVersion': 3,
            'appPreferencesJson': settings,
            'activeSlot': 1,
            'creativeSlots': {'2': 'not-json'},
          }),
        ),
        throwsFormatException,
      );
    });

    test(
      'retains a Creative Mode-only source slot without dropping its config',
      () {
        final creative = const CreativeModeSave(
          name: 'Standalone sandbox',
          enabled: true,
        );
        final raw = jsonEncode({
          'formatVersion': 3,
          'appPreferencesJson': jsonEncode(
            LegacyGtn1BackupBundle(
              formatVersion: 3,
              appPreferences: GameSettings.initial,
              activeSlot: 1,
              slots: const {},
              backups: const {},
              creativeSlots: const {},
            ).appPreferences.toJson(),
          ),
          'activeSlot': 1,
          'slots': <String, String>{},
          'backups': <String, String>{},
          'creativeSlots': {'4': CreativeModeSave.encode(creative)},
        });

        final decoded = LegacyGtn1BackupBundle.decode(raw);
        expect(decoded.slots.containsKey(4), isFalse);
        expect(decoded.creativeSlots[4]!.name, 'Standalone sandbox');
      },
    );
  });
}
