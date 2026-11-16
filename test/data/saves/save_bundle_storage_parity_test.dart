import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/data/saves/save_bundle_storage.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('SaveBundleStorage GTN1 parity', () {
    late Directory sourceDirectory;
    late Directory targetDirectory;

    setUp(() async {
      sourceDirectory = await Directory.systemTemp.createTemp(
        'gtn1-all-slots-',
      );
      targetDirectory = await Directory.systemTemp.createTemp(
        'gtn2-all-slots-',
      );
    });

    tearDown(() async {
      if (await sourceDirectory.exists()) {
        await sourceDirectory.delete(recursive: true);
      }
      if (await targetDirectory.exists()) {
        await targetDirectory.delete(recursive: true);
      }
    });

    test('exports and restores all ten primaries, backups and separate Creative saves', () async {
      for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
        final storage = SaveStorage(directory: sourceDirectory, slot: slot);
        await storage.save(
          SaveData(secret: 10 + slot, attempts: slot, gamesWon: slot - 1),
        );
        await storage.save(
          SaveData(secret: 20 + slot, attempts: slot + 1, gamesWon: slot),
        );
      }
      const creative = CreativeModeSave(
        name: 'GTN1 independent Creative slot',
        enabled: true,
        rangeMin: 25,
        rangeMax: 900,
        effects: [
          CreativeModeEffect(
            id: 'extra-hints',
            type: CreativeEffectType.extraHints,
            value: 2,
          ),
        ],
      );
      await File('${sourceDirectory.path}/gtn2-creative-slot10.json')
          .writeAsString(CreativeModeSave.encode(creative), flush: true);

      final settings = GameSettings.initial.copyWith(
        localeCode: 'en_ph',
        themeMode: 'Dark',
        updateCheckIntervalHours: 12,
      );
      final exported = await SaveBundleStorage(directory: sourceDirectory)
          .exportPortableBackup(
            activeSlot: 10,
            appPreferences: settings,
            passphrase: 'correct horse battery',
          );

      final profileJson = jsonEncode({
        'schemaVersion': 2,
        'username': 'Local profile',
        'bio': 'Must remain local',
        'avatarId': 'custom',
        'customAvatarPath': '${targetDirectory.path}/player-avatar.webp',
        'profileId': 'local-profile-id',
        'setupComplete': true,
      });
      final profileFile = File(
        '${targetDirectory.path}/gtn2-player-profile.json',
      );
      final avatarFile = File('${targetDirectory.path}/player-avatar.webp');
      await profileFile.writeAsString(profileJson, flush: true);
      final avatarBytes = [0, 1, 2, 3, 127, 128, 255];
      await avatarFile.writeAsBytes(avatarBytes, flush: true);

      final imported = await SaveBundleStorage(directory: targetDirectory)
          .importBackup(
            input: exported,
            passphrase: 'correct horse battery',
            legacyTargetSlot: 1,
          );

      expect(imported, isNotNull);
      expect(imported!.isFullBundle, isTrue);
      expect(imported.activeSlot, 10);
      expect(imported.importedSlots, 10);
      expect(
        await SaveStorage(directory: targetDirectory).loadActiveSlot(),
        10,
      );
      for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
        final storage = SaveStorage(directory: targetDirectory, slot: slot);
        expect((await storage.loadPrimary())!.secret, 20 + slot);
        expect((await storage.loadBackup())!.secret, 10 + slot);
      }
      expect(
        (await SaveStorage(
          directory: targetDirectory,
          slot: 10,
        ).loadCreativeMode())!.name,
        creative.name,
      );
      final restoredSettings = await SaveBundleStorage.loadAppPreferences(
        targetDirectory,
      );
      expect(restoredSettings!.localeCode, 'en_ph');
      expect(restoredSettings.themeMode, 'Dark');
      expect(restoredSettings.updateCheckIntervalHours, 12);

      expect(await profileFile.readAsString(), profileJson);
      expect(await avatarFile.readAsBytes(), avatarBytes);
    });

    test(
      'preserves profile and custom avatar during legacy single-save import',
      () async {
        final profileJson = jsonEncode({
          'schemaVersion': 2,
          'username': 'Keep me',
          'bio': 'Local only',
          'avatarId': 'custom',
          'customAvatarPath': '${targetDirectory.path}/avatar.png',
          'profileId': 'keep-profile',
          'setupComplete': true,
        });
        final profileFile = File(
          '${targetDirectory.path}/gtn2-player-profile.json',
        );
        final avatarFile = File('${targetDirectory.path}/avatar.png');
        await profileFile.writeAsString(profileJson, flush: true);
        await avatarFile.writeAsBytes([9, 8, 7, 6], flush: true);

        final legacy = {
          'difficultyId': 'classic',
          'profileName': 'Migrated save',
          'profileIconId': 'star',
          'targetNumber': 42,
          'currentRangeMin': 1,
          'currentRangeMax': 100,
          'attempts': 3,
          'correctGuesses': 1,
          'statistics': {
            'totalGuesses': 3,
            'correctGuesses': 1,
            'failedGuesses': 2,
            'moneyEarned': '0',
            'moneySpent': '0',
            'nebulaEarned': 0,
            'playtimeSeconds': 0,
            'randomEventsTriggered': 0,
          },
          'settings': {'themeMode': 'Dark', 'locale': 'en-US'},
        };
        final result = await SaveBundleStorage(directory: targetDirectory)
            .importBackup(
              input: jsonEncode(legacy),
              passphrase: '',
              legacyTargetSlot: 4,
            );

        expect(result, isNotNull);
        expect(result!.isFullBundle, isFalse);
        expect(result.activeSlot, 4);
        expect(
          (await SaveStorage(
            directory: targetDirectory,
            slot: 4,
          ).loadPrimary())!.secret,
          42,
        );
        expect(await profileFile.readAsString(), profileJson);
        expect(await avatarFile.readAsBytes(), [9, 8, 7, 6]);
      },
    );
  });
}
