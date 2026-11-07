import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('SaveData', () {
    test('round-trips progression and settings through JSON', () {
      final save = SaveData(
        secret: 42,
        attempts: 7,
        gamesWon: 3,
        isComplete: true,
        progression: ProgressionState.initial.copyWith(
          money: BigNumber.parse('12345678901234567890.25'),
          prestige: BigNumber.fromInt(4),
          upgrades: const {'income': 2},
        ),
        settings: const GameSettings(darkMode: false, reduceMotion: true),
      );
      expect(SaveData.fromJson(save.toJson()).toJson(), save.toJson());
    });

    test('rejects unknown versions and invalid fields', () {
      expect(
        () => SaveData.fromJson({
          'schemaVersion': 3,
          'secret': 42,
          'attempts': 0,
          'gamesWon': 0,
          'isComplete': false,
        }),
        throwsFormatException,
      );
      expect(
        () => SaveData.fromJson({
          'schemaVersion': 1,
          'secret': 0,
          'attempts': -1,
          'gamesWon': 0,
          'isComplete': false,
        }),
        throwsFormatException,
      );
    });

    test('defaults progression and settings for older saves', () {
      final save = SaveData.fromJson({
        'schemaVersion': 1,
        'secret': 42,
        'attempts': 0,
        'gamesWon': 0,
        'isComplete': false,
      });
      expect(save.progression.money.toString(), '0');
      expect(save.settings, GameSettings.initial);
      expect(save.schemaVersion, SaveData.currentSchemaVersion);
      expect(save.progression.legacySystems.toJson(), LegacySystemsState.initial.toJson());
    });

    test('migrates schema 1 saves and preserves nested legacy systems', () {
      final legacy = LegacySystemsState.initial.copyWith(
        activeMutators: const {'mut_hardcore'},
        talents: const {'talent_speed_1'},
        homeBaseLevel: 3,
        musicLibrary: const ['track_a'],
      );
      final oldSave = SaveData(
        schemaVersion: 1,
        secret: 42,
        attempts: 2,
        gamesWon: 1,
        progression: ProgressionState.initial.copyWith(legacySystems: legacy),
      ).toJson();
      final migrated = SaveData.fromJson(oldSave);
      expect(migrated.schemaVersion, SaveData.currentSchemaVersion);
      expect(migrated.progression.legacySystems.toJson(), legacy.toJson());
    });
  });

  test('saves and loads through a temporary file safely', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-test-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final first = SaveData(secret: 42, attempts: 4, gamesWon: 1);
    final second = SaveData(secret: 73, attempts: 2, gamesWon: 2);

    expect(await storage.load(), isNull);
    await storage.save(first);
    expect((await storage.load())?.toJson(), first.toJson());
    await storage.save(second);
    expect((await storage.load())?.toJson(), second.toJson());
  });

  test('save slots use separate files', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-slots-test-');
    addTearDown(() => directory.delete(recursive: true));
    final firstSlot = SaveStorage(directory: directory, slot: 1);
    final secondSlot = SaveStorage(directory: directory, slot: 2);
    await firstSlot.save(SaveData(secret: 11, attempts: 0, gamesWon: 0));
    await secondSlot.save(SaveData(secret: 22, attempts: 0, gamesWon: 0));
    expect((await firstSlot.load())?.secret, 11);
    expect((await secondSlot.load())?.secret, 22);
  });
}
