import '../numbers/big_number.dart';
import 'progression_engine.dart';
import 'progression_state.dart';

/// Progression formulas kept in one place to match the original GTN economy.
class ProgressionCalculator {
  ProgressionCalculator._();

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

    final shift = 16 - exponent;
    final scaled = shift >= 0
        ? (numerator * BigInt.fromInt(10).pow(shift)) ~/ denominator
        : numerator ~/ (denominator * BigInt.fromInt(10).pow(-shift));
    final digits = scaled.toString().padLeft(17, '0');
    final mantissa = double.parse('${digits.substring(0, 1)}.${digits.substring(1, 16)}');
    final reward = (100 * (exponent + (log10(mantissa)))).floor();
    return reward.clamp(0, 2000);
  }

  static PrestigeRules prestigeRules(ProgressionState state) {
    final requirement = prestigeRequirement(state.prestigeResets);
    return PrestigeRules(
      minimumMoney: requirement,
      rewardForMoney: (money) => prestigeReward(money, requirement),
    );
  }

  static UltraRules ultraRules(ProgressionState state) {
    final requirement = ultraRequirement(state.ultraResets);
    return UltraRules(
      minimumMoney: requirement,
      rewardForMoney: (money) => ultraReward(money, requirement),
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

  static int _decimalExponent(BigInt numerator, BigInt denominator) {
    var exponent = numerator.toString().length - denominator.toString().length;
    final below = exponent >= 0
        ? numerator < denominator * BigInt.from(10).pow(exponent)
        : numerator * BigInt.from(10).pow(-exponent) < denominator;
    if (below) exponent--;
    return exponent;
  }
}

double log10(double value) => value.log10();
