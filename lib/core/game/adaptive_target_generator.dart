import 'dart:math';

/// Dart port of GTN1's bounded adaptive target proposal.
///
/// The constants and 64-bit mixing steps mirror
/// `app/src/main/cpp/gtn_native_core.h` and the Kotlin reference benchmark.
/// BigInt keeps unsigned 64-bit wraparound exact on both Android and Windows.
class AdaptiveTargetGenerator {
  const AdaptiveTargetGenerator._();

  static final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;
  static final BigInt _signedMax = (BigInt.one << 63) - BigInt.one;
  static final BigInt _mixIncrement = BigInt.parse(
    '9E3779B97F4A7C15',
    radix: 16,
  );
  static final BigInt _mixMultiplierA = BigInt.parse(
    'BF58476D1CE4E5B9',
    radix: 16,
  );
  static final BigInt _mixMultiplierB = BigInt.parse(
    '94D049BB133111EB',
    radix: 16,
  );
  static final BigInt _streakMultiplier = BigInt.parse(
    'D6E8FEB86659FD93',
    radix: 16,
  );
  static final BigInt _attemptsMultiplier = BigInt.parse(
    'A5A3564E27F3C91B',
    radix: 16,
  );

  /// Produces a full-width unsigned seed from two independent random words.
  static BigInt randomSeed(Random random) {
    final high = random.nextInt(1 << 32);
    final low = random.nextInt(1 << 32);
    return (BigInt.from(high) << 32) | BigInt.from(low);
  }

  static int nextTarget({
    required int rangeMin,
    required int rangeMax,
    required String difficultyId,
    required int streak,
    required int attempts,
    required BigInt seed,
  }) {
    if (rangeMax < rangeMin) return rangeMin;

    final difference =
        (BigInt.from(rangeMax) - BigInt.from(rangeMin)) & _mask64;
    final width = (difference + BigInt.one) & _mask64;
    if (width == BigInt.zero) return rangeMin;

    final safeStreak = streak < 0 ? 0 : streak;
    final safeAttempts = attempts < 0 ? 0 : attempts;
    var state = seed & _mask64;
    state ^= _difficultySalt(difficultyId);
    state ^= (BigInt.from(safeStreak) * _streakMultiplier) & _mask64;
    state ^= (BigInt.from(safeAttempts) * _attemptsMultiplier) & _mask64;

    final sample = _mix(state);
    var offset = sample % width;
    final streakPressure = safeStreak > 32 ? 32 : safeStreak;
    final difficultyPressure = switch (difficultyId) {
      'extreme' => 3,
      'hard' => 2,
      _ => 1,
    };
    final pressure = streakPressure + difficultyPressure;

    if (width > BigInt.from(4)) {
      final quarter = width ~/ BigInt.from(4);
      final pressureBand =
          (BigInt.from(pressure) * width) ~/ BigInt.from(128);
      final edgeBand = quarter < pressureBand ? quarter : pressureBand;
      if (edgeBand > BigInt.zero && sample.isOdd) {
        final maxOffset = width - BigInt.one;
        final shiftedOffset = offset + edgeBand;
        offset = shiftedOffset > maxOffset ? maxOffset : shiftedOffset;
      }
    }

    final unsignedMinimum = BigInt.from(rangeMin) & _mask64;
    final result = (unsignedMinimum + offset) & _mask64;
    if (result > _signedMax) return rangeMax;
    return result.toInt();
  }

  static BigInt _mix(BigInt input) {
    var value = (input + _mixIncrement) & _mask64;
    value = ((value ^ (value >> 30)) * _mixMultiplierA) & _mask64;
    value = ((value ^ (value >> 27)) * _mixMultiplierB) & _mask64;
    return value ^ (value >> 31);
  }

  static BigInt _difficultySalt(String difficultyId) => switch (difficultyId) {
    'extreme' => BigInt.parse('E17E4E9B5A7C31D1', radix: 16),
    'hard' => BigInt.parse('A11CE5D4B8F23071', radix: 16),
    _ => BigInt.parse('C1A551C0DE2026A1', radix: 16),
  };
}
