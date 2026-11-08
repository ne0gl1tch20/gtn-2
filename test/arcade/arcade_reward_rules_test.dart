import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_reward_rules.dart';

void main() {
  test('Memory Match rejects rewards before an answer is submitted', () {
    expect(
      ArcadeRewardRules.isMemoryMatchRewardEligible(
        submitted: false,
        correct: false,
      ),
      isFalse,
    );
  });

  test('Memory Match rejects a submitted incorrect answer', () {
    expect(
      ArcadeRewardRules.isMemoryMatchRewardEligible(
        submitted: true,
        correct: false,
      ),
      isFalse,
    );
  });

  test('Memory Match rewards a submitted correct answer', () {
    expect(
      ArcadeRewardRules.isMemoryMatchRewardEligible(
        submitted: true,
        correct: true,
      ),
      isTrue,
    );
  });
}
