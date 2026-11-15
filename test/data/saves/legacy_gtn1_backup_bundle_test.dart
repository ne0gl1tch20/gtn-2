import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_backup_bundle.dart';
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
      expect(
        (retained['statistics'] as Map)['arcadeBestScores']['classic'],
        100,
      );
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
