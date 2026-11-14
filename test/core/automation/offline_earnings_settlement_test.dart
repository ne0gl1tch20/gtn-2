import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/automation/offline_earnings_settlement.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  group('offline earnings settlement', () {
    test('settles payout into Money and lifetime earnings', () {
      final initial = ProgressionState.initial.copyWith(
        money: BigNumber.fromInt(100),
        moneyEarned: BigNumber.fromInt(500),
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: true,
          lastSaveTimestamp: 1_800_000_000_000,
        ),
      );

      final result = OfflineEarningsSettlement.settle(
        progression: initial,
        nowMillis: 1_800_000_060_000,
      );

      expect(result.earnings.toString(), '30000');
      expect(result.progression.money.toString(), '30100');
      expect(result.progression.moneyEarned.toString(), '30500');
      expect(
        result.progression.legacySystems.lastSaveTimestamp,
        1_800_000_060_000,
      );
      expect(result.clockRollbackDetected, isFalse);
    });

    test('caps a long absence at eight hours', () {
      final initial = ProgressionState.initial.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: true,
          lastSaveTimestamp: 1,
        ),
      );

      final result = OfflineEarningsSettlement.settle(
        progression: initial,
        nowMillis: 999_999_001,
      );

      expect(result.earnings.toString(), '14400000');
      expect(result.elapsedSeconds, greaterThan(28800));
    });

    test('inactive automation and missing save timestamps earn nothing', () {
      final inactive = ProgressionState.initial.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: false,
          lastSaveTimestamp: 1_800_000_000_000,
        ),
      );
      final neverSaved = ProgressionState.initial.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: true,
          lastSaveTimestamp: 0,
        ),
      );

      expect(
        OfflineEarningsSettlement.settle(
          progression: inactive,
          nowMillis: 1_800_003_600_000,
        ).earnings.toString(),
        '0',
      );
      expect(
        OfflineEarningsSettlement.settle(
          progression: neverSaved,
          nowMillis: 1_800_003_600_000,
        ).earnings.toString(),
        '0',
      );
    });

    test('persisting a settlement prevents the same interval paying twice', () {
      final initial = ProgressionState.initial.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: true,
          lastSaveTimestamp: 1_800_000_000_000,
        ),
      );

      final first = OfflineEarningsSettlement.settle(
        progression: initial,
        nowMillis: 1_800_000_060_000,
      );
      final second = OfflineEarningsSettlement.settle(
        progression: first.progression,
        nowMillis: 1_800_000_060_000,
      );

      expect(first.earnings.toString(), '30000');
      expect(second.earnings.toString(), '0');
      expect(second.progression.money.toString(), '30000');
      expect(second.progression.moneyEarned.toString(), '30000');
    });

    test('clock rollback pauses automation and awards no offline money', () {
      const now = 1_800_000_000_000;
      final initial = ProgressionState.initial.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          autoClickerActive: true,
          lastSaveTimestamp: now + 90_000,
        ),
      );

      final result = OfflineEarningsSettlement.settle(
        progression: initial,
        nowMillis: now,
      );

      expect(result.clockRollbackDetected, isTrue);
      expect(result.earnings.toString(), '0');
      expect(result.progression.legacySystems.autoClickerActive, isFalse);
      expect(result.progression.legacySystems.lastSaveTimestamp, now);
      expect(
        result.progression.legacySystems.timeTravelPenaltyUntil,
        now + 86_400_000,
      );
    });
  });
}
