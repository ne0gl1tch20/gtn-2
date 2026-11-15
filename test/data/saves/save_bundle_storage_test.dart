import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_backup_bundle.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_save_codec.dart';
import 'package:gtn_2/data/saves/portable_save_backup.dart';
import 'package:gtn_2/data/saves/save_bundle_storage.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('SaveBundleStorage', () {
    late Directory sourceDirectory;
    late Directory targetDirectory;

    setUp(() async {
      sourceDirectory = await Directory.systemTemp.createTemp(
        'gtn2-bundle-src-',
      );
      targetDirectory = await Directory.systemTemp.createTemp(
        'gtn2-bundle-dst-',
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

    test(
      'exports and imports all slots, backups, active slot and global settings',
      () async {
        final slotOne = SaveStorage(directory: sourceDirectory, slot: 1);
        await slotOne.save(SaveData(secret: 20, attempts: 1, gamesWon: 0));
        await slotOne.save(SaveData(secret: 30, attempts: 2, gamesWon: 1));
        final slotTwo = SaveStorage(directory: sourceDirectory, slot: 2);
        await slotTwo.save(
          SaveData(secret: 77, attempts: 4, gamesWon: 3, profileName: 'Second'),
        );
        await slotTwo.saveActiveSlot(2);

        final settings = GameSettings.initial.copyWith(
          localeCode: 'en_us',
          themeMode: 'Dark',
          updateCheckIntervalHours: 6,
        );
        final source = SaveBundleStorage(directory: sourceDirectory);
        final backupText = await source.exportPortableBackup(
          activeSlot: 2,
          appPreferences: settings,
          passphrase: 'correct horse battery',
        );

        final target = SaveBundleStorage(directory: targetDirectory);
        final result = await target.importBackup(
          input: backupText,
          passphrase: 'correct horse battery',
          legacyTargetSlot: 1,
        );

        expect(result, isNotNull);
        expect(result!.isFullBundle, isTrue);
        expect(result.activeSlot, 2);
        expect(result.importedSlots, 2);
        expect(
          await SaveStorage(directory: targetDirectory).loadActiveSlot(),
          2,
        );
        expect(
          (await SaveStorage(
            directory: targetDirectory,
            slot: 1,
          ).loadPrimary())!.secret,
          30,
        );
        expect(
          (await SaveStorage(
            directory: targetDirectory,
            slot: 1,
          ).loadBackup())!.secret,
          20,
        );
        expect(
          (await SaveStorage(
            directory: targetDirectory,
            slot: 2,
          ).loadPrimary())!.profileName,
          'Second',
        );
        final restoredSettings = await SaveBundleStorage.loadAppPreferences(
          targetDirectory,
        );
        expect(restoredSettings!.themeMode, 'Dark');
        expect(restoredSettings.updateCheckIntervalHours, 6);
      },
    );

    test('wrong passphrase leaves every existing slot untouched', () async {
      final targetSlot = SaveStorage(directory: targetDirectory, slot: 1);
      await targetSlot.save(SaveData(secret: 88, attempts: 0, gamesWon: 0));
      final before = await targetSlot.loadPrimary();

      final source = SaveBundleStorage(directory: sourceDirectory);
      await SaveStorage(
        directory: sourceDirectory,
        slot: 1,
      ).save(SaveData(secret: 12, attempts: 0, gamesWon: 0));
      final backupText = await source.exportPortableBackup(
        activeSlot: 1,
        appPreferences: GameSettings.initial,
        passphrase: 'correct horse battery',
      );

      await expectLater(
        () => SaveBundleStorage(directory: targetDirectory).importBackup(
          input: backupText,
          passphrase: 'incorrect horse battery',
          legacyTargetSlot: 1,
        ),
        throwsFormatException,
      );
      expect((await targetSlot.loadPrimary())!.secret, before!.secret);
    });

    test('legacy single-save import preserves other slots and Creative Save protection', () async {
      final existing = SaveStorage(directory: targetDirectory, slot: 1);
      await existing.save(
        SaveData(
          secret: 50,
          attempts: 3,
          gamesWon: 1,
          minimum: 10,
          maximum: 90,
          creativeModeEnabled: true,
        ),
      );
      await SaveStorage(
        directory: targetDirectory,
        slot: 2,
      ).save(SaveData(secret: 44, attempts: 2, gamesWon: 0));
      final sourceSave = {
        'difficultyId': 'classic',
        'profileName': 'Imported',
        'profileIconId': 'star',
        'targetNumber': 5,
        'currentRangeMin': 1,
        'currentRangeMax': 100,
        'attempts': 1,
        'correctGuesses': 0,
        'streak': 0,
        'bestStreak': 0,
        'money': '0',
        'prestige': '0',
        'ultra': '0',
        'nebula': '0',
        'statistics': {
          'totalGuesses': 1,
          'correctGuesses': 0,
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
            input: LegacyGtn1SaveCodec.encode(jsonEncode(sourceSave)),
            passphrase: '',
            legacyTargetSlot: 1,
          );

      expect(result!.isFullBundle, isFalse);
      expect(result.activeSlot, 1);
      final restored = await existing.loadPrimary();
      expect(restored!.profileName, 'Imported');
      expect(restored.creativeModeEnabled, isTrue);
      expect(restored.minimum, 10);
      expect(restored.maximum, 90);
      expect(restored.secret, 10);
      expect((await existing.loadBackup())!.secret, 50);
      expect(
        (await SaveStorage(
          directory: targetDirectory,
          slot: 2,
        ).loadPrimary())!.secret,
        44,
      );
    });

    test(
      'full bundle import keeps existing permanent Creative Save eligibility',
      () async {
        await SaveStorage(
          directory: sourceDirectory,
          slot: 1,
        ).save(SaveData(secret: 50, attempts: 0, gamesWon: 0));
        final source = SaveBundleStorage(directory: sourceDirectory);
        final backupText = await source.exportPortableBackup(
          activeSlot: 1,
          appPreferences: GameSettings.initial,
          passphrase: 'correct horse battery',
        );

        final target = SaveStorage(directory: targetDirectory, slot: 1);
        await target.save(
          SaveData(
            secret: 800,
            attempts: 2,
            gamesWon: 1,
            minimum: 100,
            maximum: 1000,
            creativeModeEnabled: true,
          ),
        );
        await SaveBundleStorage(directory: targetDirectory).importBackup(
          input: backupText,
          passphrase: 'correct horse battery',
          legacyTargetSlot: 1,
        );

        final restored = await target.loadPrimary();
        expect(restored!.creativeModeEnabled, isTrue);
        expect(restored.minimum, 100);
        expect(restored.maximum, 1000);
        expect(restored.secret, 100);
      },
    );

    test(
      'stores Creative Mode-only slots separately until a game save is created',
      () async {
        const creative = CreativeModeSave(
          name: 'Independent sandbox',
          enabled: true,
          rangeMin: 10,
          rangeMax: 500,
        );
        final settings = GameSettings.initial;
        final bundle = LegacyGtn1BackupBundle(
          formatVersion: 3,
          appPreferences: settings,
          activeSlot: 4,
          slots: const {},
          backups: const {},
          creativeSlots: const {4: creative},
        );
        final backupText = await PortableSaveBackup.encryptGtn1Payload(
          bundle.encode(),
          'correct horse battery',
        );

        await SaveBundleStorage(directory: targetDirectory).importBackup(
          input: backupText,
          passphrase: 'correct horse battery',
          legacyTargetSlot: 1,
        );
        final storage = SaveStorage(directory: targetDirectory, slot: 4);
        expect(await storage.loadPrimary(), isNull);
        expect((await storage.loadCreativeMode())!.name, 'Independent sandbox');

        final created = await storage.createIfEmpty(
          SaveData(secret: 50, attempts: 0, gamesWon: 0),
        );
        expect(created, isTrue);
        expect(
          (await storage.load())!.creativeMode!.name,
          'Independent sandbox',
        );
      },
    );

    test('startup recovery restores the pre-import snapshot', () async {
      const transactionName = '.gtn2-bundle-import-txn';
      final transaction = Directory('${targetDirectory.path}/$transactionName');
      final rollback = Directory('${transaction.path}/rollback');
      await rollback.create(recursive: true);
      final target = File('${targetDirectory.path}/gtn2-save.json');
      await target.writeAsString('new partial contents');
      await File('${rollback.path}/gtn2-save.json')
          .writeAsString('old contents');
      await File('${transaction.path}/manifest.json').writeAsString(
        jsonEncode({
          'files': [
            {'name': 'gtn2-save.json', 'existed': true},
            {'name': 'gtn2-active-slot.json', 'existed': false},
          ],
        }),
      );

      await SaveBundleStorage.recoverPendingImport(targetDirectory);

      expect(await target.readAsString(), 'old contents');
      expect(
        await File('${targetDirectory.path}/gtn2-active-slot.json').exists(),
        isFalse,
      );
      expect(await transaction.exists(), isFalse);
    });

    test(
      'ignores an incomplete temporary manifest before live files are touched',
      () async {
        const transactionName = '.gtn2-bundle-import-txn';
        final transaction = Directory(
          '${targetDirectory.path}/$transactionName',
        );
        await transaction.create(recursive: true);
        final target = File('${targetDirectory.path}/gtn2-save.json');
        await target.writeAsString('original live save');
        await File('${transaction.path}/manifest.json.tmp')
            .writeAsString('{"files":');

        await SaveBundleStorage.recoverPendingImport(targetDirectory);

        expect(await target.readAsString(), 'original live save');
        expect(await transaction.exists(), isFalse);
      },
    );
  });
}
