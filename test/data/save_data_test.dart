import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  group('SaveData', () {
    test(
      'persists achievement IDs and playtime and migrates older progression',
      () {
        final progression = ProgressionState.initial.copyWith(
          achievements: const {'correct_10', 'playtime_1h'},
          playtimeSeconds: 3600,
          nebulaItems: const {'cosmetic_nebula_ring': 1},
          equippedCosmeticId: 'cosmetic_nebula_ring',
        );
        final save = SaveData(
          secret: 42,
          attempts: 0,
          gamesWon: 0,
          progression: progression,
        );
        final restored = SaveData.fromJson(save.toJson());
        expect(restored.progression.achievements, progression.achievements);
        expect(restored.progression.playtimeSeconds, 3600);
        expect(restored.progression.equippedCosmeticId, 'cosmetic_nebula_ring');
        expect(restored.progression.nebulaItems['cosmetic_nebula_ring'], 1);

        final oldProgression = Map<String, dynamic>.from(progression.toJson())
          ..remove('achievements')
          ..remove('playtimeSeconds')
          ..remove('equippedCosmeticId');
        final migrated = ProgressionState.fromJson(oldProgression);
        expect(migrated.achievements, isEmpty);
        expect(migrated.playtimeSeconds, 0);
        expect(migrated.equippedCosmeticId, isNull);
      },
    );

    test('rejects unknown equipped Nebula cosmetics', () {
      final progression = ProgressionState.initial.toJson()
        ..['equippedCosmeticId'] = 'cosmetic_unknown';
      expect(
        () => ProgressionState.fromJson(progression),
        throwsFormatException,
      );
    });

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
        settings: const GameSettings(
          darkMode: false,
          reduceMotion: true,
          difficultyId: 'hard',
        ),
      );
      expect(SaveData.fromJson(save.toJson()).toJson(), save.toJson());
      expect(SaveData.fromJson(save.toJson()).minimum, 25);
      expect(SaveData.fromJson(save.toJson()).maximum, 150);
      expect(SaveData.fromJson(save.toJson()).settings.difficultyId, 'hard');
    });

    test('round-trips huge progression currencies and permanent levels', () {
      String expanded(String digits, int zeroCount) =>
          '$digits${List<String>.filled(zeroCount, '0').join()}';

      final progression = ProgressionState.initial.copyWith(
        money: BigNumber.parse(expanded('1', 100)),
        prestige: BigNumber.parse(expanded('25', 79)),
        ultra: BigNumber.parse(expanded('3', 60)),
        nebula: BigNumber.parse(expanded('4', 40)),
        moneyEarned: BigNumber.parse(expanded('5', 100)),
        moneySpent: BigNumber.parse(expanded('6', 90)),
        nebulaEarned: BigNumber.parse(expanded('7', 50)),
        prestigeUpgrades: const {
          'prestige_money_boost': 4,
          'prestige_gain_boost': 5,
        },
        ultraUpgrades: const {'ultra_money_boost': 3, 'ultra_gain_boost': 2},
      );
      final save = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        progression: progression,
      );

      final restored = SaveData.fromJson(save.toJson()).progression;

      expect(restored.money, progression.money);
      expect(restored.prestige, progression.prestige);
      expect(restored.ultra, progression.ultra);
      expect(restored.nebula, progression.nebula);
      expect(restored.moneyEarned, progression.moneyEarned);
      expect(restored.moneySpent, progression.moneySpent);
      expect(restored.nebulaEarned, progression.nebulaEarned);
      expect(restored.prestigeUpgrades, progression.prestigeUpgrades);
      expect(restored.ultraUpgrades, progression.ultraUpgrades);
    });

    test('persists Creative Mode configuration and active run per save', () {
      final creative = CreativeModeSave(
        enabled: true,
        rangeMin: 10,
        rangeMax: 30,
        effects: const [
          CreativeModeEffect(
            id: 'hints',
            type: CreativeEffectType.extraHints,
            value: 2,
          ),
        ],
      );
      final run = CreativeModeRuntime.start(creative, 21)!;
      final persistedCreative = CreativeModeRuntime.persist(creative, run)!;
      final save = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        creativeMode: persistedCreative,
      );

      final restored = SaveData.fromJson(save.toJson());

      expect(restored.creativeMode, isNotNull);
      expect(CreativeModeRuntime.resume(restored.creativeMode!)!.target, 21);
      expect(restored.creativeMode!.effects.single.value, 2);
    });

    test('rejects malformed nested Creative Mode configuration', () {
      final base = SaveData(secret: 42, attempts: 0, gamesWon: 0).toJson();
      expect(
        () => SaveData.fromJson({
          ...base,
          'creativeMode': {
            'schemaVersion': 3,
            'name': 'Bad',
            'enabled': true,
            'rangeMin': 1,
            'rangeMax': 10,
            'effects': [
              {'id': 'bad', 'type': 'UNKNOWN', 'value': 1},
            ],
          },
        }),
        throwsFormatException,
      );
    });

    test('round-trips save profile name and icon', () {
      final save = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        profileName: 'My Run',
        profileIconId: 'planet',
      );
      final restored = SaveData.fromJson(save.toJson());
      expect(restored.profileName, 'My Run');
      expect(restored.profileIconId, 'planet');
      expect(
        restored.copyWith(profileName: 'New Name').profileIconId,
        'planet',
      );
    });

    test('migrates old saves without profile fields', () {
      final oldSave =
          SaveData(
              schemaVersion: 3,
              secret: 42,
              attempts: 0,
              gamesWon: 0,
            ).toJson()
            ..remove('profileName')
            ..remove('profileIconId');
      final migrated = SaveData.fromJson(oldSave);
      expect(migrated.schemaVersion, SaveData.currentSchemaVersion);
      expect(migrated.profileName, isEmpty);
      expect(migrated.profileIconId, 'default');
    });

    test('rejects invalid profile metadata', () {
      final base = SaveData(secret: 42, attempts: 0, gamesWon: 0).toJson();
      expect(
        () => SaveData.fromJson({
          ...base,
          'profileName': List.filled(25, 'x').join(),
        }),
        throwsFormatException,
      );
      expect(
        () => SaveData.fromJson({...base, 'profileIconId': 'unknown'}),
        throwsFormatException,
      );
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
        () => SaveData.fromJson({...save.toJson(), 'maximum': 501}),
        throwsFormatException,
      );
    });

    test('rejects unknown versions and invalid fields', () {
      expect(
        () => SaveData.fromJson({
          'schemaVersion': 6,
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
      expect(
        save.progression.legacySystems.toJson(),
        LegacySystemsState.initial.toJson(),
      );
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
    final directory = await Directory.systemTemp.createTemp('gtn2-save-test-');
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

  test(
    'serializes writes across separate storage instances for one slot',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-save-instance-queue-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = SaveStorage(directory: directory, slot: 3);
      final second = SaveStorage(directory: directory, slot: 3);

      await Future.wait([
        first.save(SaveData(secret: 31, attempts: 1, gamesWon: 1)),
        second.save(SaveData(secret: 82, attempts: 2, gamesWon: 2)),
      ]);

      final restored = await first.load();
      expect(restored, isNotNull);
      expect([31, 82], contains(restored!.secret));
      expect(await first.hasBackup(), isTrue);
    },
  );

  test(
    'gameplay save updates preserve profile and Creative Mode metadata',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-save-metadata-update-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);
      final creative = CreativeModeSave(
        enabled: true,
        rangeMin: 10,
        rangeMax: 50,
        effects: const [
          CreativeModeEffect(
            id: 'extra-hints',
            type: CreativeEffectType.extraHints,
            value: 2,
          ),
        ],
      );
      await storage.save(
        SaveData(
          secret: 42,
          attempts: 1,
          gamesWon: 2,
          profileName: 'My Profile',
          profileIconId: 'crown',
          creativeMode: creative,
        ),
      );

      await storage.update(
        (current) => current!.copyWith(
          secret: 73,
          attempts: 4,
          gamesWon: 3,
          isComplete: false,
          minimum: 1,
          maximum: 100,
          progression: ProgressionState.initial.copyWith(
            money: BigNumber.fromInt(900),
          ),
          settings: const GameSettings(difficultyId: 'hard'),
        ),
      );

      final restored = await storage.load();
      expect(restored?.secret, 73);
      expect(restored?.attempts, 4);
      expect(restored?.gamesWon, 3);
      expect(restored?.profileName, 'My Profile');
      expect(restored?.profileIconId, 'crown');
      expect(restored?.creativeMode?.enabled, isTrue);
      expect(restored?.creativeMode?.effects.single.value, 2);
      expect(restored?.progression.money.toString(), '900');
      expect(restored?.settings.difficultyId, 'hard');
    },
  );

  test('persists Extreme Hardcore saves through the storage layer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-extreme-save-test-',
    );
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

  test(
    'rejects invalid nested progression and legacy state before writing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-invalid-nested-save-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);

      final invalidStatistics = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        progression: ProgressionState.initial.copyWith(totalGuesses: -1),
      );
      await expectLater(storage.save(invalidStatistics), throwsArgumentError);
      expect(await storage.load(), isNull);

      final invalidLegacyState = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        progression: ProgressionState.initial.copyWith(
          legacySystems: LegacySystemsState.initial.copyWith(homeBaseLevel: 21),
        ),
      );
      await expectLater(storage.save(invalidLegacyState), throwsArgumentError);
      expect(await storage.load(), isNull);
    },
  );

  test(
    'rejects save data whose secret is outside its configured range',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-invalid-range-save-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);

      await expectLater(
        storage.save(
          SaveData(
            secret: 501,
            attempts: 0,
            gamesWon: 0,
            minimum: 1,
            maximum: 500,
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'recovers the completed temporary save after an interrupted write',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-save-recovery-tmp-',
      );
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
    },
  );

  test(
    'recovers the last known-good backup when the primary save is corrupt',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-save-recovery-bak-',
      );
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
      expect(
        await File('${directory.path}/gtn2-save.json.corrupt').exists(),
        isTrue,
      );
    },
  );

  test('persists the active save slot across storage instances', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-active-slot-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final slotOne = SaveStorage(directory: directory, slot: 1);
    final slotTen = SaveStorage(directory: directory, slot: 10);

    expect(await slotOne.loadActiveSlot(), 1);
    await slotTen.saveActiveSlot(10);
    expect(await slotOne.loadActiveSlot(), 10);
    await slotOne.saveActiveSlot(3);
    expect(await slotTen.loadActiveSlot(), 3);
  });

  test(
    'rejects invalid active slot values without replacing the selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-active-slot-invalid-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);

      await storage.saveActiveSlot(4);
      await expectLater(storage.saveActiveSlot(0), throwsRangeError);
      await expectLater(storage.saveActiveSlot(11), throwsRangeError);
      expect(await storage.loadActiveSlot(), 4);
    },
  );

  test(
    'recovers active-slot metadata from a completed temporary file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-active-slot-tmp-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);
      final temporary = File('${directory.path}/gtn2-active-slot.json.tmp');
      await temporary.writeAsString('{"schemaVersion":1,"slot":8}');

      expect(await storage.loadActiveSlot(), 8);
      expect(
        await File('${directory.path}/gtn2-active-slot.json').exists(),
        isTrue,
      );
      expect(await temporary.exists(), isFalse);
    },
  );

  test(
    'recovers active-slot metadata from backup when primary is corrupt',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-active-slot-bak-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);
      final primary = File('${directory.path}/gtn2-active-slot.json');
      final backup = File('${directory.path}/gtn2-active-slot.json.bak');
      await primary.writeAsString('{broken json');
      await backup.writeAsString('{"schemaVersion":1,"slot":6}');

      expect(await storage.loadActiveSlot(), 6);
      expect(
        await File('${directory.path}/gtn2-active-slot.json').exists(),
        isTrue,
      );
      expect(
        await File('${directory.path}/gtn2-active-slot.json.corrupt').exists(),
        isTrue,
      );
    },
  );

  test('retains and restores the previous valid save', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-save-restore-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    await storage.save(SaveData(secret: 42, attempts: 1, gamesWon: 1));
    await storage.save(SaveData(secret: 73, attempts: 2, gamesWon: 2));

    expect(await storage.hasBackup(), isTrue);
    expect((await storage.load())?.secret, 73);
    expect(await storage.restoreBackup(), isTrue);
    expect((await storage.load())?.secret, 42);
    expect(await storage.hasBackup(), isTrue);
    expect(await storage.restoreBackup(), isTrue);
    expect((await storage.load())?.secret, 73);
  });

  test('creates a save only once when two storage instances race', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-create-slot-race-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = SaveStorage(directory: directory, slot: 5);
    final second = SaveStorage(directory: directory, slot: 5);
    final results = await Future.wait([
      first.createIfEmpty(SaveData(secret: 31, attempts: 0, gamesWon: 0)),
      second.createIfEmpty(SaveData(secret: 82, attempts: 0, gamesWon: 0)),
    ]);

    expect(results.where((created) => created).length, 1);
    expect([31, 82], contains((await first.load())!.secret));
  });

  test('duplicate operations cannot overwrite the same target slot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-duplicate-slot-race-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = SaveStorage(directory: directory, slot: 1);
    final second = SaveStorage(directory: directory, slot: 2);
    await first.save(SaveData(secret: 31, attempts: 0, gamesWon: 0));
    await second.save(SaveData(secret: 82, attempts: 0, gamesWon: 0));

    final results = await Future.wait([
      first.duplicateTo(3),
      second.duplicateTo(3),
    ]);

    expect(results.where((created) => created).length, 1);
    expect(
      [31, 82],
      contains(
        (await SaveStorage(directory: directory, slot: 3).load())!.secret,
      ),
    );
  });

  test('duplicates a save and its restore backup into an empty slot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-save-duplicate-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = SaveStorage(directory: directory, slot: 1);
    final target = SaveStorage(directory: directory, slot: 2);
    await source.save(SaveData(secret: 42, attempts: 1, gamesWon: 1));
    await source.save(SaveData(secret: 73, attempts: 2, gamesWon: 2));

    expect(await source.duplicateTo(2), isTrue);
    expect((await target.load())?.secret, 73);
    expect(await target.hasBackup(), isTrue);
    expect(await source.duplicateTo(2), isFalse);
    expect(await source.duplicateTo(1), isFalse);
  });

  test('reset removes the save and all recovery files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-save-reset-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory, slot: 4);
    await storage.save(SaveData(secret: 42, attempts: 1, gamesWon: 1));
    await storage.save(SaveData(secret: 73, attempts: 2, gamesWon: 2));

    await storage.reset();

    expect(await storage.load(), isNull);
    expect(await storage.hasBackup(), isFalse);
  });

  test('save slots use separate files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-save-slots-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final firstSlot = SaveStorage(directory: directory, slot: 1);
    final secondSlot = SaveStorage(directory: directory, slot: 2);
    final tenthSlot = SaveStorage(
      directory: directory,
      slot: SaveStorage.maxSaveSlots,
    );
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
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-save-slot-range-',
    );
    addTearDown(() => directory.delete(recursive: true));

    expect(SaveStorage.maxSaveSlots, 10);
    expect(() => SaveStorage(directory: directory, slot: 0), throwsRangeError);
    expect(() => SaveStorage(directory: directory, slot: 11), throwsRangeError);
  });
}
