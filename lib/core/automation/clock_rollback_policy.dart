/// Matches GTN1's AntiTimeTravelRules clock-rollback policy.
class ClockRollbackDecision {
  const ClockRollbackDecision({
    required this.detected,
    required this.differenceSeconds,
    required this.lastSaveTimestamp,
    required this.timeTravelPenaltyUntil,
    required this.autoClickerActive,
  });

  final bool detected;
  final int differenceSeconds;
  final int lastSaveTimestamp;
  final int timeTravelPenaltyUntil;
  final bool autoClickerActive;
}

class ClockRollbackPolicy {
  const ClockRollbackPolicy._();

  static const int penaltyMillis = 24 * 60 * 60 * 1000;

  static ClockRollbackDecision check({
    required int nowMillis,
    required int lastSaveTimestamp,
    required int timeTravelPenaltyUntil,
    required bool autoClickerActive,
  }) {
    if (nowMillis < lastSaveTimestamp) {
      return ClockRollbackDecision(
        detected: true,
        differenceSeconds: (lastSaveTimestamp - nowMillis) ~/ 1000,
        lastSaveTimestamp: nowMillis,
        timeTravelPenaltyUntil: nowMillis + penaltyMillis,
        autoClickerActive: false,
      );
    }
    return ClockRollbackDecision(
      detected: false,
      differenceSeconds: 0,
      lastSaveTimestamp: nowMillis,
      timeTravelPenaltyUntil: timeTravelPenaltyUntil,
      autoClickerActive: autoClickerActive,
    );
  }
}
