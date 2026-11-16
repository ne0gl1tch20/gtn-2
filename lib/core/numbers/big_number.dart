/// A base-10 decimal represented by an integer coefficient and scale.
///
/// For example, 12.34 is stored as coefficient 1234 and scale 2.
/// Trailing decimal zeroes are normalized away.
class BigNumber implements Comparable<BigNumber> {
  BigNumber._(this.coefficient, this.scale);

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

  /// Parses decimal/scientific notation and GTN1's named magnitude suffixes.
  ///
  /// Invalid input remains a FormatException so save validation can reject
  /// malformed currency instead of silently converting it to zero.
  factory BigNumber.parse(String value) {
    final input = value.trim();
    const suffixPowers = <String, int>{
      'K': 3,
      'M': 6,
      'B': 9,
      'T': 12,
      'QA': 15,
      'QI': 18,
      'SX': 21,
      'SP': 24,
      'OC': 27,
      'NO': 30,
      'DC': 33,
      'UD': 36,
      'DD': 39,
      'TD': 42,
      'QAD': 45,
      'QID': 48,
      'SXD': 51,
      'SPD': 54,
      'OCD': 57,
      'NOD': 60,
      'VG': 63,
      'UVG': 66,
      'DVG': 69,
      'TVG': 72,
      'QAVG': 75,
      'QIVG': 78,
      'SXVG': 81,
      'SPVG': 84,
      'OCVG': 87,
      'NOVG': 90,
      'TG': 93,
      'VGN': 63,
    };

    var numericInput = input;
    var suffixPower = 0;
    final suffixMatch = RegExp(r'^(.+?)([A-Za-z]+)$').firstMatch(input);
    if (suffixMatch != null) {
      final suffix = suffixMatch.group(2)!.toUpperCase();
      final power = suffixPowers[suffix];
      if (power == null) {
        throw FormatException('Invalid decimal number.', value);
      }
      numericInput = suffixMatch.group(1)!.trim();
      suffixPower = power;
    }

    final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?$')
        .firstMatch(numericInput);
    if (match == null) {
      throw FormatException('Invalid decimal number.', value);
    }
    final fraction = match.group(3) ?? '';
    final digits = '${match.group(2)}$fraction';
    var coefficient = BigInt.parse(
      '${match.group(1) == '-' ? '-' : ''}$digits',
    );
    var scale =
        fraction.length - int.parse(match.group(4) ?? '0') - suffixPower;
    if (scale < 0) {
      coefficient *= _powerOfTen(-scale);
      scale = 0;
    }
    return BigNumber.fromParts(coefficient, scale);
  }

  final BigInt coefficient;
  final int scale;

  BigNumber operator +(BigNumber other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = coefficient * _powerOfTen(commonScale - scale);
    final right = other.coefficient * _powerOfTen(commonScale - other.scale);
    return _roundToPrecision(BigNumber.fromParts(left + right, commonScale));
  }

  BigNumber operator -(BigNumber other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = coefficient * _powerOfTen(commonScale - scale);
    final right = other.coefficient * _powerOfTen(commonScale - other.scale);
    final result = _roundToPrecision(
      BigNumber.fromParts(left - right, commonScale),
    );
    return result.coefficient.isNegative ? BigNumber.fromInt(0) : result;
  }

  BigNumber operator *(BigNumber other) => _roundToPrecision(
    BigNumber.fromParts(coefficient * other.coefficient, scale + other.scale),
  );

  /// Divides using GTN1's 16-place HALF_UP rule. A zero divisor returns zero.
  BigNumber operator /(BigNumber other) {
    if (other.coefficient == BigInt.zero) return BigNumber.fromInt(0);
    const resultScale = 16;
    final numerator = coefficient * _powerOfTen(other.scale + resultScale);
    final denominator = other.coefficient * _powerOfTen(scale);
    var quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();
    if (remainder * BigInt.two >= denominator.abs()) {
      quotient += numerator.isNegative != denominator.isNegative
          ? -BigInt.one
          : BigInt.one;
    }
    return BigNumber.fromParts(quotient, resultScale);
  }

  BigNumber multiplyInt(int value) => _roundToPrecision(
    BigNumber.fromParts(coefficient * BigInt.from(value), scale),
  );

  /// Raises this value to a non-negative integer exponent exactly.
  BigNumber powInt(int exponent) {
    if (exponent < 0) {
      throw ArgumentError.value(exponent, 'exponent', 'Must not be negative.');
    }
    return _roundToPrecision(
      BigNumber.fromParts(coefficient.pow(exponent), scale * exponent),
    );
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

  /// Formats this value using GTN1's Standard, Scientific or Engineering
  /// display notation. Serialization must continue to use [toString] so save
  /// files retain plain decimal values.
  String format([String notation = 'Standard']) {
    if (coefficient == BigInt.zero) return '0';
    if (compareTo(BigNumber.fromInt(1)) < 0) {
      return _stripTrailingDecimalZeros(_fixedDecimal(this, 2));
    }

    final digits = coefficient.abs().toString().length;
    final exponent = digits - scale - 1;
    if (notation == 'Scientific') {
      return _scientificString(this, exponent);
    }
    if (notation == 'Engineering') {
      final engineeringExponent = (exponent ~/ 3) * 3;
      final scaled = _shiftDecimal(this, -engineeringExponent);
      return '${_stripTrailingDecimalZeros(_fixedDecimal(scaled, 2))}e$engineeringExponent';
    }
    if (exponent < 3) {
      return _stripTrailingDecimalZeros(_fixedDecimal(this, 0));
    }

    final suffixIndex = exponent ~/ 3;
    const suffixes = <String>[
      '',
      'K',
      'M',
      'B',
      'T',
      'Qa',
      'Qi',
      'Sx',
      'Sp',
      'Oc',
      'No',
      'Dc',
      'Ud',
      'Dd',
      'Td',
      'Qad',
      'Qid',
      'Sxd',
      'Spd',
      'Ocd',
      'Nod',
      'Vg',
      'UVg',
      'DVg',
      'TVg',
      'QaVg',
      'QiVg',
      'SxVg',
      'SpVg',
      'OcVg',
      'NoVg',
      'Tg',
    ];
    if (suffixIndex >= suffixes.length) {
      return _scientificString(this, exponent);
    }
    final suffixExponent = exponent - exponent % 3;
    final scaled = _shiftDecimal(this, -suffixExponent);
    return '${_stripTrailingDecimalZeros(_fixedDecimal(scaled, 2))}${suffixes[suffixIndex]}';
  }

  static BigNumber _shiftDecimal(BigNumber value, int power) {
    if (power >= 0) {
      return BigNumber.fromParts(
        value.coefficient * _powerOfTen(power),
        value.scale,
      );
    }
    return BigNumber.fromParts(value.coefficient, value.scale - power);
  }

  static BigNumber _roundToScale(BigNumber value, int targetScale) {
    if (value.scale <= targetScale) {
      return BigNumber.fromParts(
        value.coefficient * _powerOfTen(targetScale - value.scale),
        targetScale,
      );
    }
    final discarded = value.scale - targetScale;
    final divisor = _powerOfTen(discarded);
    final absolute = value.coefficient.abs();
    var quotient = absolute ~/ divisor;
    final remainder = absolute.remainder(divisor);
    if (remainder * BigInt.two >= divisor) quotient += BigInt.one;
    if (value.coefficient.isNegative) quotient = -quotient;
    return BigNumber.fromParts(quotient, targetScale);
  }

  static String _fixedDecimal(BigNumber value, int decimalPlaces) {
    BigInt scaledCoefficient;
    if (value.scale <= decimalPlaces) {
      scaledCoefficient =
          value.coefficient * _powerOfTen(decimalPlaces - value.scale);
    } else {
      final divisor = _powerOfTen(value.scale - decimalPlaces);
      final absolute = value.coefficient.abs();
      scaledCoefficient = absolute ~/ divisor;
      if (absolute.remainder(divisor) * BigInt.two >= divisor) {
        scaledCoefficient += BigInt.one;
      }
      if (value.coefficient.isNegative) {
        scaledCoefficient = -scaledCoefficient;
      }
    }
    final negative = scaledCoefficient.isNegative;
    final digits = scaledCoefficient.abs().toString().padLeft(
      decimalPlaces + 1,
      '0',
    );
    if (decimalPlaces == 0) return '${negative ? '-' : ''}$digits';
    final split = digits.length - decimalPlaces;
    return '${negative ? '-' : ''}${digits.substring(0, split)}.${digits.substring(split)}';
  }

  static String _stripTrailingDecimalZeros(String value) {
    if (!value.contains('.')) return value;
    var result = value;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String _scientificString(BigNumber value, int exponent) {
    var mantissa = _shiftDecimal(value, -exponent);
    mantissa = _roundToScale(mantissa, 2);
    if (mantissa.compareTo(BigNumber.fromInt(10)) >= 0) {
      exponent++;
      mantissa = BigNumber.fromParts(BigInt.one, 0);
    }
    final fixed = _fixedDecimal(mantissa, 2);
    final exponentText = exponent >= 0
        ? '+${exponent.toString().padLeft(2, '0')}'
        : exponent.toString().padLeft(3, '0');
    return fixed + 'e' + exponentText;
  }

  @override
  String toString() {
    if (scale == 0) return coefficient.toString();
    final negative = coefficient.isNegative;
    final digits = coefficient.abs().toString().padLeft(scale + 1, '0');
    final split = digits.length - scale;
    final result = '${digits.substring(0, split)}.${digits.substring(split)}';
    return negative ? '-$result' : result;
  }

  static BigNumber _roundToPrecision(BigNumber value, {int precision = 34}) {
    final digits = value.coefficient.abs().toString().length;
    final discardedDigits = digits - precision;
    if (discardedDigits <= 0 || value.coefficient == BigInt.zero) {
      return value;
    }

    final divisor = _powerOfTen(discardedDigits);
    final absolute = value.coefficient.abs();
    var quotient = absolute ~/ divisor;
    final remainder = absolute.remainder(divisor);
    final midpoint = remainder * BigInt.two;
    if (midpoint > divisor || (midpoint == divisor && quotient.isOdd)) {
      quotient += BigInt.one;
    }

    if (value.coefficient.isNegative) quotient = -quotient;
    final adjustedScale = value.scale - discardedDigits;
    if (adjustedScale >= 0) {
      return BigNumber.fromParts(quotient, adjustedScale);
    }
    return BigNumber.fromParts(quotient * _powerOfTen(-adjustedScale), 0);
  }

  static BigInt _powerOfTen(int exponent) => BigInt.from(10).pow(exponent);
}
