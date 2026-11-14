import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/automation/offline_earnings_settlement.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

void main() {
  test(
    'offline payout survives restart without being awarded twice',
    () async {
    final directory = await Directory.systemTemp.createTemp(
      'gtn2-offline-settlement-save-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = SaveStorage(directory: directory);
    final savedAt = 1_800_000_000_000;
    const resumedAt = 1_800_000_060_000;
    final progression = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(25),
      moneyEarned: BigNumber.fromInt(25),
      legacySystems: LegacySystemsState.initial.copyWith(
        autoClickerActive: true,
        lastSaveTimestamp: savedAt,
      ),
    );
    await storage.save(
      SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        progression: progression,
      ),
    );

    final firstLoad = (await storage.load())!;
    final firstSettlement = OfflineEarningsSettlement.settle(
      progression: firstLoad.progression,
      nowMillis: resumedAt,
    );
    await storage.update(
      (current) => current!.copyWith(
        progression: firstSettlement.progression,
      ),
    );

    final restartedLoad = (await storage.load())!;
    final secondSettlement = OfflineEarningsSettlement.settle(
      progression: restartedLoad.progression,
      nowMillis: resumedAt,
    );

    expect(firstSettlement.earnings.toString(), '30000');
    expect(secondSettlement.earnings.toString(), '0');
    expect(restartedLoad.progression.money.toString(), '30025');
    expect(restartedLoad.progression.moneyEarned.toString(), '30025');
    expect(
      restartedLoad.progression.legacySystems.lastSaveTimestamp,
      resumedAt,
    );
    },
  );
}
