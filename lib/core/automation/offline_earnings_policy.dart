import '../numbers/big_number.dart';

/// Canonical GTN1 offline catch-up policy.
///
/// Offline earnings are available only while automation was active when the
/// save was last written. Elapsed time is clamped to eight hours to prevent
/// unbounded catch-up and negative elapsed time is treated as zero.
class OfflineEarningsPolicy {
  const OfflineEarningsPolicy._();

  static const int maxOfflineSeconds = 28800;
  static const int earningsPerSecond = 500;

  static int effectiveSeconds(int elapsedSeconds) {
    if (elapsedSeconds <= 0) return 0;
    return elapsedSeconds > maxOfflineSeconds
        ? maxOfflineSeconds
        : elapsedSeconds;
  }

  static BigNumber calculate({
    required bool autoClickerWasActive,
    required int elapsedSeconds,
  }) {
    if (!autoClickerWasActive) return BigNumber.fromInt(0);
    return BigNumber.fromInt(earningsPerSecond)
        .multiplyInt(effectiveSeconds(elapsedSeconds));
  }
}
