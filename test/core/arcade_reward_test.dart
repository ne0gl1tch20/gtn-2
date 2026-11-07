import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  const engine = ProgressionEngine();

  test('Arcade reward adds Nebula and Money and tracks lifetime earnings', () {
    final initial = ProgressionState.initial;
    final updated = engine.awardArcadeReward(
      initial,
      nebulaReward: BigNumber.fromInt(1),
      moneyReward: BigNumber.fromInt(5000),
    );

    expect(updated.nebula, BigNumber.fromInt(1));
    expect(updated.nebulaEarned, BigNumber.fromInt(1));
    expect(updated.money, BigNumber.fromInt(5000));
    expect(updated.moneyEarned, BigNumber.fromInt(5000));
  });

  test('Nebula Crystal doubles future Arcade Nebula rewards', () {
    final purchased = engine.purchaseNebulaItem(
      ProgressionState(nebula: BigNumber.fromInt(50)),
      itemId: 'nebula_boost',
      price: BigNumber.fromInt(50),
    );
    final rewarded = engine.awardArcadeReward(
      purchased,
      nebulaReward: BigNumber.fromInt(1),
      moneyReward: BigNumber.fromInt(0),
    );
    expect(rewarded.nebula, BigNumber.fromInt(2));
    expect(rewarded.nebulaEarned, BigNumber.fromInt(2));
  });

  test('Arcade reward rejects negative payouts', () {
    expect(
      () => engine.awardArcadeReward(
        ProgressionState.initial,
        nebulaReward: BigNumber.fromInt(-1),
        moneyReward: BigNumber.fromInt(0),
      ),
      throwsArgumentError,
    );
  });
}
