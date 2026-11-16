import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

void main() {
  late Directory directory;
  late SaveStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'gtn2-economy-persistence-',
    );
    storage = SaveStorage(directory: directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test(
    'arcade Nebula payout and shop purchase survive a fresh storage instance',
    () async {
      final engine = ProgressionEngine();
      final initial = ProgressionState.initial.copyWith(
        nebula: BigNumber.fromInt(25),
      );

      final rewarded = engine.awardArcadeReward(
        initial,
        nebulaReward: BigNumber.fromInt(10),
        moneyReward: BigNumber.fromInt(125),
      );
      final purchased = engine.purchaseNebulaItem(
        rewarded,
        itemId: 'nebula_boost',
        price: BigNumber.fromInt(25),
      );

      expect(purchased.nebula.toString(), '10');
      expect(purchased.nebulaEarned.toString(), '10');
      expect(purchased.money.toString(), '125');
      expect(purchased.moneyEarned.toString(), '125');
      expect(purchased.nebulaItems['nebula_boost'], 1);

      await storage.save(
        SaveData(
          secret: 42,
          attempts: 0,
          gamesWon: 0,
          progression: purchased,
        ),
      );

      final restartedStorage = SaveStorage(directory: directory);
      final restored = await restartedStorage.load();

      expect(restored, isNotNull);
      expect(restored!.progression.nebula.toString(), '10');
      expect(restored.progression.nebulaEarned.toString(), '10');
      expect(restored.progression.money.toString(), '125');
      expect(restored.progression.moneyEarned.toString(), '125');
      expect(restored.progression.nebulaItems['nebula_boost'], 1);

      final secondLoad = await restartedStorage.load();
      expect(secondLoad!.progression.nebula.toString(), '10');
      expect(secondLoad.progression.nebulaEarned.toString(), '10');
    },
  );
}
