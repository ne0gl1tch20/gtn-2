import '../numbers/big_number.dart';
import 'progression_engine.dart';
import 'progression_state.dart';

/// Progression formulas kept in one place to match the original GTN economy.
class ProgressionCalculator {
  ProgressionCalculator._();

  // Fixed-point precision keeps floor boundaries stable for very large ratios.
  // GTN1 uses BigDecimal/DECIMAL128 and an explicit high-precision natural log.
  static final BigInt _decimalScale = BigInt.from(10).pow(60);
  static final BigInt _naturalLogTen = _naturalLogScaled(
    _decimalScale * BigInt.from(10),
  );

  static BigNumber prestigeRequirement(int prestigeResets) {
    if (prestigeResets < 0) throw ArgumentError.value(prestigeResets);
    return BigNumber.fromInt(50000000) *
        BigNumber.parse('2.5').powInt(prestigeResets);
  }

  static BigNumber ultraRequirement(int ultraResets) {
    if (ultraResets < 0) throw ArgumentError.value(ultraResets);
    return BigNumber.fromInt(10000000000) *
        BigNumber.fromInt(5).powInt(ultraResets);
  }

  static BigNumber prestigeReward(BigNumber money, BigNumber requirement) {
    final ratio = _integerRatioFloor(money, requirement);
    return BigNumber.fromParts(_integerSquareRoot(ratio), 0);
  }

  static int ultraReward(BigNumber money, BigNumber requirement) {
    if (money.compareTo(requirement) < 0 ||
        requirement.compareTo(BigNumber.fromInt(0)) <= 0) {
      return 0;
    }
    final ratio = _ratioParts(money, requirement);
    final numerator = ratio.$1;
    final denominator = ratio.$2;
    final exponent = _decimalExponent(numerator, denominator);
    if (exponent >= 20) return 2000;

    // Keep the mantissa as an exact rational until it is converted to a
    // 60-digit fixed-point value. A double can round 1e20 - 1 up to 1e20,
    // incorrectly granting the 2,000 reward cap one unit early.
    final mantissaDenominator = denominator * BigInt.from(10).pow(exponent);
    final mantissaScaled = (numerator * _decimalScale) ~/ mantissaDenominator;
    final naturalLogMantissa = _naturalLogScaled(mantissaScaled);
    final log10Mantissa =
        (naturalLogMantissa * _decimalScale) ~/ _naturalLogTen;
    final logarithmScaled =
        BigInt.from(exponent) * _decimalScale + log10Mantissa;
    final reward = (logarithmScaled * BigInt.from(100)) ~/ _decimalScale;
    return reward.toInt().clamp(0, 2000);
  }

  static PrestigeRules prestigeRules(ProgressionState state) {
    final requirement = prestigeRequirement(state.prestigeResets);
    final gainLevel = (state.prestigeUpgrades['prestige_gain_boost'] ?? 0)
        .clamp(0, 25);
    final startingLevel =
        (state.prestigeUpgrades['prestige_starting_capital'] ?? 0).clamp(0, 30);
    final gainMultiplier = BigNumber.parse(
      (1.0 + gainLevel * 0.2).toStringAsFixed(2),
    );
    return PrestigeRules(
      minimumMoney: requirement,
      startingCapital: BigNumber.fromInt(startingLevel * 1000),
      rewardForMoney: (money) =>
          _floorToInteger(prestigeReward(money, requirement) * gainMultiplier),
    );
  }

  static UltraRules ultraRules(ProgressionState state) {
    final requirement = ultraRequirement(state.ultraResets);
    final gainLevel = (state.ultraUpgrades['ultra_gain_boost'] ?? 0).clamp(
      0,
      10,
    );
    final startingLevel =
        (state.prestigeUpgrades['prestige_starting_capital'] ?? 0).clamp(0, 30);
    final gainMultiplier = BigNumber.parse(
      (1.0 + gainLevel * 0.5).toStringAsFixed(2),
    );
    return UltraRules(
      minimumMoney: requirement,
      startingCapital: BigNumber.fromInt(startingLevel * 1000),
      rewardForMoney: (money) {
        final boosted = _floorToInteger(
          BigNumber.fromInt(ultraReward(money, requirement)) * gainMultiplier,
        );
        return boosted.coefficient.toInt().clamp(0, 2000);
      },
    );
  }

  static BigNumber _floorToInteger(BigNumber value) {
    if (value.scale == 0) return value;
    return BigNumber.fromParts(
      value.coefficient ~/ BigInt.from(10).pow(value.scale),
      0,
    );
  }

  static BigInt _integerRatioFloor(BigNumber value, BigNumber divisor) {
    if (divisor.compareTo(BigNumber.fromInt(0)) <= 0) {
      throw ArgumentError.value(divisor, 'divisor');
    }
    final parts = _ratioParts(value, divisor);
    return parts.$1 ~/ parts.$2;
  }

  static (BigInt, BigInt) _ratioParts(BigNumber value, BigNumber divisor) {
    if (value.coefficient.isNegative || divisor.coefficient.isNegative) {
      throw ArgumentError('Progression values must be non-negative.');
    }
    final numerator = value.coefficient * BigInt.from(10).pow(divisor.scale);
    final denominator = divisor.coefficient * BigInt.from(10).pow(value.scale);
    return (numerator, denominator);
  }

  static BigInt _integerSquareRoot(BigInt value) {
    if (value <= BigInt.zero) return BigInt.zero;
    var estimate = BigInt.one << ((value.bitLength + 1) ~/ 2);
    while (true) {
      final next = (estimate + value ~/ estimate) >> 1;
      if (next >= estimate) return estimate;
      estimate = next;
    }
  }

  /// Natural logarithm using ln(x) = 2 * (z + z^3/3 + ...),
  /// where z = (x - 1) / (x + 1). All operations use fixed-point integers.
  static BigInt _naturalLogScaled(BigInt valueScaled) {
    if (valueScaled <= BigInt.zero) {
      throw ArgumentError.value(valueScaled, 'valueScaled');
    }
    if (valueScaled == _decimalScale) return BigInt.zero;

    final z =
        ((valueScaled - _decimalScale) * _decimalScale) ~/
        (valueScaled + _decimalScale);
    final zSquared = (z * z) ~/ _decimalScale;
    var term = z;
    var sum = z;
    var divisor = 3;

    for (var iteration = 0; iteration < 512; iteration++) {
      term = (term * zSquared) ~/ _decimalScale;
      final contribution = term ~/ BigInt.from(divisor);
      if (contribution == BigInt.zero) break;
      sum += contribution;
      divisor += 2;
    }
    return sum * BigInt.from(2);
  }

  static int _decimalExponent(BigInt numerator, BigInt denominator) {
    var exponent = numerator.toString().length - denominator.toString().length;
    final below = exponent >= 0
        ? numerator < denominator * BigInt.from(10).pow(exponent)
        : numerator * BigInt.from(10).pow(-exponent) < denominator;
    if (below) exponent--;
    return exponent;
  }
}
