/// GTN1's monotonic 50 ms guard for manual guess submissions.
class GuessRateLimitPolicy {
  const GuessRateLimitPolicy._();

  static const minimumIntervalMicroseconds = 50000;

  static bool isRateLimited({
    required int? lastSubmissionMicroseconds,
    required int nowMicroseconds,
    int minimumInterval = minimumIntervalMicroseconds,
  }) {
    if (lastSubmissionMicroseconds == null || minimumInterval <= 0) {
      return false;
    }
    if (nowMicroseconds < lastSubmissionMicroseconds) return true;
    return nowMicroseconds - lastSubmissionMicroseconds < minimumInterval;
  }
}

/// Stateful manual-input limiter backed by a monotonic clock.
///
/// Bot submissions bypass this limiter at the caller, matching GTN1's
/// AntiCheatService boundary. Rejected submissions do not move the timestamp.
class GuessRateLimiter {
  GuessRateLimiter({
    int Function()? nowMicroseconds,
    this.minimumInterval = GuessRateLimitPolicy.minimumIntervalMicroseconds,
  }) : _nowMicroseconds = nowMicroseconds ?? _monotonicNow;

  static final Stopwatch _clock = Stopwatch()..start();

  final int Function() _nowMicroseconds;
  final int minimumInterval;
  int? _lastSubmissionMicroseconds;

  static int _monotonicNow() => _clock.elapsedMicroseconds;

  bool tryAccept() {
    final now = _nowMicroseconds();
    if (GuessRateLimitPolicy.isRateLimited(
      lastSubmissionMicroseconds: _lastSubmissionMicroseconds,
      nowMicroseconds: now,
      minimumInterval: minimumInterval,
    )) {
      return false;
    }
    _lastSubmissionMicroseconds = now;
    return true;
  }
}
