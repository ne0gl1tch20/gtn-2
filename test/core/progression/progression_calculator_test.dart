import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_calculator.dart';

void main() {
  test('Prestige requirement keeps the GTN 1 base and growth', () {
    expect(ProgressionCalculator.prestigeRequirement(0), BigNumber.fromInt(50000000));
    expect(ProgressionCalculator.prestigeRequirement(1), BigNumber.fromInt(125000000));
    expect(ProgressionCalculator.prestigeRequirement(2), BigNumber.parse('312500000'));
  });

  test('Ultra requirement keeps the GTN 1 base and growth', () {
    expect(ProgressionCalculator.ultraRequirement(0), BigNumber.fromInt(10000000000));
    expect(ProgressionCalculator.ultraRequirement(1), BigNumber.fromInt(50000000000));
    expect(ProgressionCalculator.ultraRequirement(2), BigNumber.fromInt(250000000000));
  });

  test('Prestige reward uses the floor square root of money ratio', () {
    expect(
      ProgressionCalculator.prestigeReward(
        BigNumber.fromInt(200000000),
        BigNumber.fromInt(50000000),
      ),
      BigNumber.fromInt(2),
    );
  });

  test('Ultra reward is zero below threshold and capped at 2000', () {
    expect(
      ProgressionCalculator.ultraReward(
        BigNumber.fromInt(9999999999),
        BigNumber.fromInt(10000000000),
      ),
      0,
    );
    expect(
      ProgressionCalculator.ultraReward(
        BigNumber.fromInt(10000000000000000000000000000000000000000),
        BigNumber.fromInt(10000000000),
      ),
      2000,
    );
  });
}
