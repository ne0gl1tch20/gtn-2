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
        SaveData(secret: 42, attempts: 0, gamesWon: 0, progression: purchased),
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
  test(
    'saturated arcade Nebula and fractional Money survive a fresh storage load',
    () async {
      final longMax = BigNumber.parse('9223372036854775807');
      final initial = ProgressionState.initial.copyWith(
        nebula: BigNumber.fromInt(10),
        nebulaEarned: longMax - BigNumber.fromInt(5),
        money: BigNumber.parse('123.45'),
        moneyEarned: BigNumber.parse('678.90'),
        moneySpent: BigNumber.parse('0.1'),
        ultraUpgrades: const {'ultra_nebula_boost': 15},
        nebulaItems: const {'nebula_boost': 1},
      );

      final rewarded = ProgressionEngine().awardArcadeReward(
        initial,
        nebulaReward: BigNumber.fromInt(288230376151711744),
        moneyReward: BigNumber.parse('0.25'),
      );

      expect(rewarded.nebula.toString(), '9223372036854775817');
      expect(rewarded.nebulaEarned, longMax);
      expect(rewarded.money.toString(), '123.7');
      expect(rewarded.moneyEarned.toString(), '679.15');

      await storage.save(
        SaveData(
          secret: 42,
          attempts: 0,
          gamesWon: 0,
          progression: rewarded,
        ),
      );
      final restored = await SaveStorage(directory: directory).load();

      expect(restored, isNotNull);
      expect(restored!.progression.nebula, rewarded.nebula);
      expect(restored.progression.nebulaEarned, longMax);
      expect(restored.progression.money, rewarded.money);
      expect(restored.progression.moneyEarned, rewarded.moneyEarned);
      expect(restored.progression.moneySpent, rewarded.moneySpent);
    },
  );

}
