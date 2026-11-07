import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

void main() {
  group('SaveData', () {
    test('round-trips through JSON', () {
      final save = SaveData(\n        secret: 42, attempts: 7, gamesWon: 3, isComplete: true,\n        progression: ProgressionState.initial.copyWith(\n          money: BigNumber.parse('12345678901234567890.25'),\n          prestige: BigNumber.fromInt(4),\n          upgrades: const {'income': 2},\n        ),\n      );
      expect(SaveData.fromJson(save.toJson()).toJson(), save.toJson());
    });

    test('rejects unknown versions and invalid fields', () {
      expect(
        () => SaveData.fromJson({
          'schemaVersion': 2,
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
  });

  test('loads older schema-one saves without progression data', () {\n    final save = SaveData.fromJson({\n      'schemaVersion': 1, 'secret': 42, 'attempts': 0,\n      'gamesWon': 0, 'isComplete': false,\n    });\n    expect(save.progression.money.toString(), '0');\n  });\n\n  test('saves and loads through a temporary file safely', () async {
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
}
