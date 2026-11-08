import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/adaptive_trait_profile.dart';
import 'package:gtn_2/core/legacy/invisible_trait_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';

void main() {
  const engine = InvisibleTraitEngine();

  test('legacy saves receive a safe default adaptive profile', () {
    final restored = LegacySystemsState.fromJson(<String, dynamic>{});
    expect(restored.adaptiveTraitProfile.totalGuessesObserved, 0);
    expect(restored.adaptiveTraitProfile.awardedBonuses, isEmpty);
  });

  test('profile round trips and rejects invalid score data', () {
    const profile = AdaptiveTraitProfile(
      totalGuessesObserved: 12,
      correctGuessesObserved: 7,
      failedGuessesObserved: 5,
      accuracyScore: 0.58,
      helperUses: {'mistake_insurance': 2},
      helperCooldowns: {'mistake_insurance': 15},
      awardedBonuses: {'first_prestige_bonus'},
    );
    expect(AdaptiveTraitProfile.fromJson(profile.toJson()).toJson(), profile.toJson());
    expect(
      () => AdaptiveTraitProfile.fromJson({'schemaVersion': 1, 'accuracyScore': 2}),
      throwsFormatException,
    );
  });

  test('repeated failures activate bounded adaptive helpers', () {
    const profile = AdaptiveTraitProfile(
      totalGuessesObserved: 10,
      failedGuessesObserved: 6,
      correctGuessesObserved: 10,
      accuracyScore: 0.7,
    );
    final decision = engine.evaluate(
      profile: profile,
      prestigeCount: 0,
      ultraCount: 0,
      currentStreak: 0,
    );
    expect(decision.helperIds, contains(InvisibleTraitEngine.helperMistakeInsurance));
    expect(decision.helperIds, contains(InvisibleTraitEngine.helperRangeScout));
    expect(decision.helperIds, contains(InvisibleTraitEngine.helperComeback));
    expect(decision.helperIds.length, lessThanOrEqualTo(3));
  });

  test('helper cooldowns prevent repeated activation until their window expires', () {
    const profile = AdaptiveTraitProfile(
      totalGuessesObserved: 10,
      failedGuessesObserved: 3,
      helperCooldowns: {'mistake_insurance': 13},
    );
    final blocked = engine.evaluate(
      profile: profile,
      prestigeCount: 0,
      ultraCount: 0,
      currentStreak: 0,
    );
    expect(blocked.helperIds, isNot(contains(InvisibleTraitEngine.helperMistakeInsurance)));
    final ready = engine.evaluate(
      profile: profile.copyWith(totalGuessesObserved: 13),
      prestigeCount: 0,
      ultraCount: 0,
      currentStreak: 0,
    );
    expect(ready.helperIds, contains(InvisibleTraitEngine.helperMistakeInsurance));
  });

  test('first prestige, first ultra and veteran bonuses are one-time', () {
    const profile = AdaptiveTraitProfile();
    final decision = engine.evaluate(
      profile: profile,
      prestigeCount: 10,
      ultraCount: 1,
      currentStreak: 0,
    );
    expect(decision.bonusIds, containsAll({
      InvisibleTraitEngine.bonusFirstPrestige,
      InvisibleTraitEngine.bonusFirstUltra,
      InvisibleTraitEngine.bonusVeteran,
    }));
    final awarded = engine.markBonusesAwarded(profile, decision.bonusIds);
    final second = engine.evaluate(
      profile: awarded,
      prestigeCount: 10,
      ultraCount: 1,
      currentStreak: 0,
    );
    expect(second.bonusIds, isEmpty);
  });

  test('guess observations update bounded scores and exact earned currency', () {
    final next = engine.observeGuess(
      profile: const AdaptiveTraitProfile(),
      correct: true,
      newStreak: 10,
      reward: BigNumber.parse('12.5'),
    );
    expect(next.totalGuessesObserved, 1);
    expect(next.correctGuessesObserved, 1);
    expect(next.longStreaksObserved, 1);
    expect(next.moneyEarnedObserved, '12.5');
    expect(next.accuracyScore, closeTo(0.08, 0.000001));
  });

  test('gentle target bias eases the next target while staying in range', () {
    const profile = AdaptiveTraitProfile(
      totalGuessesObserved: 8,
      failedGuessesObserved: 5,
      accuracyScore: 0.30,
    );
    final adjusted = engine.adjustNextTarget(
      profile: profile,
      candidate: 90,
      rangeMin: 1,
      rangeMax: 100,
    );
    expect(adjusted, inInclusiveRange(1, 100));
    expect(adjusted, lessThan(90));
    expect(engine.adjustNextTarget(
      profile: const AdaptiveTraitProfile(),
      candidate: 90,
      rangeMin: 1,
      rangeMax: 100,
    ), 90);
  });

  test('helper use persists counters and cooldown ticks', () {
    final next = engine.markHelperUses(
      const AdaptiveTraitProfile(totalGuessesObserved: 8),
      {InvisibleTraitEngine.helperMistakeInsurance},
    );
    expect(next.helperUses[InvisibleTraitEngine.helperMistakeInsurance], 1);
    expect(next.helperCooldowns[InvisibleTraitEngine.helperMistakeInsurance], 11);
  });
}
