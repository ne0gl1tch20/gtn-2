import '../numbers/big_number.dart';
import '../progression/progression_state.dart';
import 'clock_rollback_policy.dart';
import 'offline_earnings_policy.dart';

/// Applies GTN1's offline catch-up exactly once for a restored save snapshot.
///
/// The returned timestamp is advanced even when no payout is due. Persisting
/// the returned progression makes a repeated restore at the same instant
/// produce zero additional earnings.
class OfflineEarningsSettlement {
  const OfflineEarningsSettlement._();

  static OfflineEarningsSettlementResult settle({
    required ProgressionState progression,
    required int nowMillis,
  }) {
    final systems = progression.legacySystems;
    final clock = ClockRollbackPolicy.check(
      nowMillis: nowMillis,
      lastSaveTimestamp: systems.lastSaveTimestamp,
      timeTravelPenaltyUntil: systems.timeTravelPenaltyUntil,
      autoClickerActive: systems.autoClickerActive,
    );

    final elapsedSeconds = systems.lastSaveTimestamp > 0 && !clock.detected
        ? (nowMillis - systems.lastSaveTimestamp) ~/ 1000
        : 0;
    final earnings = OfflineEarningsPolicy.calculate(
      autoClickerWasActive: clock.autoClickerActive,
      elapsedSeconds: elapsedSeconds,
    );

    final updated = progression.copyWith(
      money: progression.money + earnings,
      moneyEarned: progression.moneyEarned + earnings,
      legacySystems: systems.copyWith(
        autoClickerActive: clock.autoClickerActive,
        lastSaveTimestamp: clock.lastSaveTimestamp,
        timeTravelPenaltyUntil: clock.timeTravelPenaltyUntil,
      ),
    );

    return OfflineEarningsSettlementResult(
      progression: updated,
      earnings: earnings,
      clockRollbackDetected: clock.detected,
      elapsedSeconds: elapsedSeconds,
    );
  }
}

class OfflineEarningsSettlementResult {
  const OfflineEarningsSettlementResult({
    required this.progression,
    required this.earnings,
    required this.clockRollbackDetected,
    required this.elapsedSeconds,
  });

  final ProgressionState progression;
  final BigNumber earnings;
  final bool clockRollbackDetected;
  final int elapsedSeconds;
}
