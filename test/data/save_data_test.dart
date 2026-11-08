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
        minimum: 25,
        maximum: 150,
        progression: ProgressionState.initial.copyWith(
          money: BigNumber.parse('12345678901234567890.25'),
          prestige: BigNumber.fromInt(4),
          upgrades: const {'income': 2},
        ),
        settings: const GameSettings(darkMode: false, reduceMotion: true, difficultyId: 'hard'),
      );
      expect(SaveData.fromJson(save.toJson()).toJson(), save.toJson());
      expect(SaveData.fromJson(save.toJson()).minimum, 25);
      expect(SaveData.fromJson(save.toJson()).maximum, 150);
      expect(SaveData.fromJson(save.toJson()).settings.difficultyId, 'hard');
    });

    test('accepts and round-trips Extreme Hardcore save ranges', () {
      final save = SaveData(
        secret: 487,
        attempts: 12,
        gamesWon: 2,
        minimum: 1,
        maximum: 500,
        settings: const GameSettings(difficultyId: 'extreme'),
      );
      final restored = SaveData.fromJson(save.toJson());
      expect(restored.secret, 487);
      expect(restored.maximum, 500);
      expect(restored.settings.difficultyId, 'extreme');
      expect(
        () => SaveData.fromJson({
          ...save.toJson(),
          'maximum': 501,
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown versions and invalid fields', () {
      expect(
        () => SaveData.fromJson({
          'schemaVersion': 4,
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
      expect(save.minimum, 1);
      expect(save.maximum, 100);
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

  test('persists Extreme Hardcore saves through the storage layer', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-extreme-save-test-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final extremeSave = SaveData(
      secret: 487,
      attempts: 12,
      gamesWon: 2,
      minimum: 1,
      maximum: 500,
      settings: const GameSettings(difficultyId: 'extreme'),
    );

    await storage.save(extremeSave);

    final restored = await storage.load();
    expect(restored?.secret, 487);
    expect(restored?.maximum, 500);
    expect(restored?.settings.difficultyId, 'extreme');
  });

  test('rejects save data whose secret is outside its configured range', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-invalid-range-save-test-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);

    await expectLater(
      storage.save(SaveData(
        secret: 501,
        attempts: 0,
        gamesWon: 0,
        minimum: 1,
        maximum: 500,
      )),
      throwsArgumentError,
    );
  });

  test('recovers the completed temporary save after an interrupted write', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-recovery-tmp-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final temporary = File('${directory.path}/gtn2-save.json.tmp');
    await temporary.writeAsString(
      '{"schemaVersion":3,"secret":91,"attempts":4,"gamesWon":2,"isComplete":false,"minimum":1,"maximum":100}',
    );

    final recovered = await storage.load();

    expect(recovered?.secret, 91);
    expect(await File('${directory.path}/gtn2-save.json').exists(), isTrue);
    expect(await temporary.exists(), isFalse);
  });

  test('recovers the last known-good backup when the primary save is corrupt', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-recovery-bak-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final primary = File('${directory.path}/gtn2-save.json');
    final backup = File('${directory.path}/gtn2-save.json.bak');
    await primary.writeAsString('{broken json');
    await backup.writeAsString(
      '{"schemaVersion":3,"secret":73,"attempts":2,"gamesWon":1,"isComplete":false,"minimum":1,"maximum":100}',
    );

    final recovered = await storage.load();

    expect(recovered?.secret, 73);
    expect(await File('${directory.path}/gtn2-save.json').exists(), isTrue);
    expect(await File('${directory.path}/gtn2-save.json.corrupt').exists(), isTrue);
  });

  test('persists the active save slot across storage instances', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-active-slot-test-');
    addTearDown(() => directory.delete(recursive: true));
    final slotOne = SaveStorage(directory: directory, slot: 1);
    final slotTen = SaveStorage(directory: directory, slot: 10);

    expect(await slotOne.loadActiveSlot(), 1);
    await slotTen.saveActiveSlot(10);
    expect(await slotOne.loadActiveSlot(), 10);
    await slotOne.saveActiveSlot(3);
    expect(await slotTen.loadActiveSlot(), 3);
  });

  test('rejects invalid active slot values without replacing the selection', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-active-slot-invalid-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);

    await storage.saveActiveSlot(4);
    await expectLater(storage.saveActiveSlot(0), throwsRangeError);
    await expectLater(storage.saveActiveSlot(11), throwsRangeError);
    expect(await storage.loadActiveSlot(), 4);
  });

  test('recovers active-slot metadata from a completed temporary file', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-active-slot-tmp-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final temporary = File('${directory.path}/gtn2-active-slot.json.tmp');
    await temporary.writeAsString('{"schemaVersion":1,"slot":8}');

    expect(await storage.loadActiveSlot(), 8);
    expect(await File('${directory.path}/gtn2-active-slot.json').exists(), isTrue);
    expect(await temporary.exists(), isFalse);
  });

  test('recovers active-slot metadata from backup when primary is corrupt', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-active-slot-bak-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final primary = File('${directory.path}/gtn2-active-slot.json');
    final backup = File('${directory.path}/gtn2-active-slot.json.bak');
    await primary.writeAsString('{broken json');
    await backup.writeAsString('{"schemaVersion":1,"slot":6}');

    expect(await storage.loadActiveSlot(), 6);
    expect(await File('${directory.path}/gtn2-active-slot.json').exists(), isTrue);
    expect(await File('${directory.path}/gtn2-active-slot.json.corrupt').exists(), isTrue);
  });

  test('save slots use separate files', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-slots-test-');
    addTearDown(() => directory.delete(recursive: true));
    final firstSlot = SaveStorage(directory: directory, slot: 1);
    final secondSlot = SaveStorage(directory: directory, slot: 2);
    final tenthSlot = SaveStorage(directory: directory, slot: SaveStorage.maxSaveSlots);
    await firstSlot.save(SaveData(secret: 11, attempts: 0, gamesWon: 0));
    await secondSlot.save(SaveData(secret: 22, attempts: 0, gamesWon: 0));
    await tenthSlot.save(SaveData(secret: 99, attempts: 0, gamesWon: 0));
    expect((await firstSlot.load())?.secret, 11);
    expect((await secondSlot.load())?.secret, 22);
    expect((await tenthSlot.load())?.secret, 99);
    expect(
      File('${directory.path}/gtn2-save-slot10.json').existsSync(),
      isTrue,
    );
  });

  test('rejects save slots outside the original ten-slot range', () async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-save-slot-range-');
    addTearDown(() => directory.delete(recursive: true));

    expect(SaveStorage.maxSaveSlots, 10);
    expect(
      () => SaveStorage(directory: directory, slot: 0),
      throwsRangeError,
    );
    expect(
      () => SaveStorage(directory: directory, slot: 11),
      throwsRangeError,
    );
  });
}
