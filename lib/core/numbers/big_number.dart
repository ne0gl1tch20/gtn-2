/// An exact base-10 decimal represented by an integer coefficient and scale.
///
/// For example, 12.34 is stored as coefficient 1234 and scale 2.
/// Trailing decimal zeroes are normalized away.
class BigNumber implements Comparable<BigNumber> {
  BigNumber._(this.coefficient, this.scale);\n\n  const BigNumber.zero() : coefficient = BigInt.zero, scale = 0;

  factory BigNumber.fromInt(int value) => BigNumber._(BigInt.from(value), 0);

  factory BigNumber.fromParts(BigInt coefficient, int scale) {
    if (scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'Must not be negative.');
    }
    if (coefficient == BigInt.zero) return BigNumber._(BigInt.zero, 0);
    var normalizedCoefficient = coefficient;
    var normalizedScale = scale;
    while (normalizedScale > 0 &&
        normalizedCoefficient.remainder(BigInt.from(10)) == BigInt.zero) {
      normalizedCoefficient ~/= BigInt.from(10);
      normalizedScale--;
    }
    return BigNumber._(normalizedCoefficient, normalizedScale);
  }

  factory BigNumber.parse(String value) {
    final input = value.trim();
    final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$').firstMatch(input);
    if (match == null) {
      throw FormatException('Invalid decimal number.', value);
    }
    final fraction = match.group(3) ?? '';
    final digits = '${match.group(2)}$fraction';
    final coefficient = BigInt.parse(
      '${match.group(1) == '-' ? '-' : ''}$digits',
    );
    return BigNumber.fromParts(coefficient, fraction.length);
  }

  final BigInt coefficient;
  final int scale;

  BigNumber operator +(BigNumber other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = coefficient * _powerOfTen(commonScale - scale);
    final right = other.coefficient * _powerOfTen(commonScale - other.scale);
    return BigNumber.fromParts(left + right, commonScale);
  }

  BigNumber operator -(BigNumber other) =>
      this + BigNumber.fromParts(-other.coefficient, other.scale);

  BigNumber operator *(BigNumber other) => BigNumber.fromParts(
        coefficient * other.coefficient,
        scale + other.scale,
      );

  BigNumber multiplyInt(int value) =>
      BigNumber.fromParts(coefficient * BigInt.from(value), scale);

  /// Raises this value to a non-negative integer exponent exactly.
  BigNumber powInt(int exponent) {
    if (exponent < 0) {
      throw ArgumentError.value(exponent, 'exponent', 'Must not be negative.');
    }
    return BigNumber.fromParts(coefficient.pow(exponent), scale * exponent);
  }

  @override
  int compareTo(BigNumber other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = coefficient * _powerOfTen(commonScale - scale);
    final right = other.coefficient * _powerOfTen(commonScale - other.scale);
    return left.compareTo(right);
  }

  @override
  bool operator ==(Object other) =>
      other is BigNumber &&
      coefficient == other.coefficient &&
      scale == other.scale;

  @override
  int get hashCode => Object.hash(coefficient, scale);

  @override
  String toString() {
    if (scale == 0) return coefficient.toString();
    final negative = coefficient.isNegative;
    final digits = coefficient.abs().toString().padLeft(scale + 1, '0');
    final split = digits.length - scale;
    final result = '${digits.substring(0, split)}.${digits.substring(split)}';
    return negative ? '-$result' : result;
  }

  static BigInt _powerOfTen(int exponent) =>
      BigInt.from(10).pow(exponent);
}
