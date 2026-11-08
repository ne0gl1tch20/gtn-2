import '../numbers/big_number.dart';
import 'adaptive_trait_profile.dart';

class AdaptiveTraitDecision {
  const AdaptiveTraitDecision({this.helperIds = const {}, this.bonusIds = const {}});
  final Set<String> helperIds;
  final Set<String> bonusIds;
}

/// Deterministic Dart port of GTN1's InvisibleTraitEngine.
/// It only emits bounded intents; all currency changes remain in the game transaction.
class InvisibleTraitEngine {
  const InvisibleTraitEngine();

  static const helperRangeScout = 'range_scout';
  static const helperMistakeInsurance = 'mistake_insurance';
  static const helperStreakGuard = 'streak_guard';
  static const helperComeback = 'comeback_reward';
  static const helperMomentum = 'momentum_reward';
  static const helperGentleTarget = 'gentle_target_bias';
  static const bonusFirstPrestige = 'first_prestige_bonus';
  static const bonusFirstUltra = 'first_ultra_bonus';
  static const bonusVeteran = 'veteran_bonus';

  AdaptiveTraitProfile observeGuess({
    required AdaptiveTraitProfile profile,
    required bool correct,
    required int newStreak,
    required BigNumber reward,
  }) {
    final tick = profile.totalGuessesObserved + 1;
    return profile.copyWith(
      totalGuessesObserved: tick,
      correctGuessesObserved: profile.correctGuessesObserved + (correct ? 1 : 0),
      failedGuessesObserved: profile.failedGuessesObserved + (correct ? 0 : 1),
      longStreaksObserved: profile.longStreaksObserved + (newStreak >= longStreakThreshold ? 1 : 0),
      moneyEarnedObserved: (BigNumber.parse(profile.moneyEarnedObserved) + reward).toString(),
      consistencyScore: _smooth(profile.consistencyScore, correct ? 1 : 0),
      accuracyScore: _smooth(profile.accuracyScore, correct ? 1 : 0),
      riskScore: _smooth(profile.riskScore, correct ? 0 : 1),
      persistenceScore: _smooth(profile.persistenceScore, 1),
    );
  }

  AdaptiveTraitProfile observeUpgradePurchase(
    AdaptiveTraitProfile profile, {
    int countDelta = 1,
  }) {
    if (countDelta <= 0) {
      return profile;
    }
    return profile.copyWith(
      upgradesPurchasedObserved: profile.upgradesPurchasedObserved + countDelta,
    );
  }

  AdaptiveTraitProfile observeProgression(
    AdaptiveTraitProfile profile, {
    required int prestigeDelta,
    required int ultraDelta,
  }) {
    final prestige = prestigeDelta < 0 ? 0 : prestigeDelta;
    final ultra = ultraDelta < 0 ? 0 : ultraDelta;
    if (prestige == 0 && ultra == 0) {
      return profile;
    }
    return profile.copyWith(
      prestigesObserved: profile.prestigesObserved + prestige,
      ultrasObserved: profile.ultrasObserved + ultra,
      progressionScore: _smooth(profile.progressionScore, 1),
    );
  }

  AdaptiveTraitDecision evaluate({
    required AdaptiveTraitProfile profile,
    required int prestigeCount,
    required int ultraCount,
    required int currentStreak,
  }) {
    final tick = profile.totalGuessesObserved;
    final helpers = <String>{};

    void offer(String id) {
      if (!_cooldownActive(profile, id, tick) && helpers.length < maxHelpersPerGuess) {
        helpers.add(id);
      }
    }

    if (tick >= gentleTargetMinGuesses &&
        profile.failedGuessesObserved >= gentleTargetMinFailures &&
        profile.accuracyScore <= gentleTargetAccuracyCeiling) {
      helpers.add(helperGentleTarget);
    }
    if (profile.failedGuessesObserved >= failureHelperThreshold) {
      offer(helperMistakeInsurance);
    }
    if (profile.failedGuessesObserved >= rangeHelperThreshold &&
        profile.correctGuessesObserved >= 10) {
      offer(helperRangeScout);
    }
    if (profile.longStreaksObserved > 0) {
      offer(helperStreakGuard);
    }
    if (profile.failedGuessesObserved >= comebackFailureThreshold &&
        profile.correctGuessesObserved > 0) {
      offer(helperComeback);
    }
    if (currentStreak >= momentumStreakThreshold) {
      offer(helperMomentum);
    }

    final bonuses = <String>{};
    if (prestigeCount >= 1 && !profile.awardedBonuses.contains(bonusFirstPrestige)) {
      bonuses.add(bonusFirstPrestige);
    }
    if (ultraCount >= 1 && !profile.awardedBonuses.contains(bonusFirstUltra)) {
      bonuses.add(bonusFirstUltra);
    }
    if (prestigeCount >= veteranPrestigeThreshold &&
        !profile.awardedBonuses.contains(bonusVeteran)) {
      bonuses.add(bonusVeteran);
    }
    return AdaptiveTraitDecision(
      helperIds: Set.unmodifiable(helpers),
      bonusIds: Set.unmodifiable(bonuses),
    );
  }

  int adjustNextTarget({
    required AdaptiveTraitProfile profile,
    required int candidate,
    required int rangeMin,
    required int rangeMax,
  }) {
    final safeCandidate = candidate.clamp(rangeMin, rangeMax).toInt();
    final decision = evaluate(
      profile: profile,
      prestigeCount: 0,
      ultraCount: 0,
      currentStreak: 0,
    );
    if (rangeMax <= rangeMin || !decision.helperIds.contains(helperGentleTarget)) {
      return safeCandidate;
    }
    final midpoint = rangeMin / 2 + rangeMax / 2;
    final strength = (gentleTargetBaseStrength +
            (gentleTargetAccuracyCeiling - profile.accuracyScore) * 0.20)
        .clamp(gentleTargetBaseStrength, gentleTargetMaxStrength);
    return (safeCandidate + (midpoint - safeCandidate) * strength)
        .toInt()
        .clamp(rangeMin, rangeMax)
        .toInt();
  }

  AdaptiveTraitProfile markHelperUses(AdaptiveTraitProfile profile, Set<String> helperIds) {
    if (helperIds.isEmpty) return profile;
    final tick = profile.totalGuessesObserved;
    final uses = Map<String, int>.of(profile.helperUses);
    final cooldowns = Map<String, int>.of(profile.helperCooldowns);
    for (final id in helperIds) {
      uses[id] = (uses[id] ?? 0) + 1;
      cooldowns[id] = tick + _cooldownFor(id);
    }
    return profile.copyWith(
      helperUses: Map.unmodifiable(uses),
      helperCooldowns: Map.unmodifiable(cooldowns),
    );
  }

  AdaptiveTraitProfile markBonusesAwarded(AdaptiveTraitProfile profile, Set<String> bonusIds) {
    if (bonusIds.isEmpty) return profile;
    return profile.copyWith(
      awardedBonuses: Set.unmodifiable({...profile.awardedBonuses, ...bonusIds}),
    );
  }

  bool _cooldownActive(AdaptiveTraitProfile profile, String id, int tick) =>
      (profile.helperCooldowns[id] ?? 0) > tick;

  int _cooldownFor(String id) => switch (id) {
    helperRangeScout => 5,
    helperMistakeInsurance => 3,
    helperStreakGuard => 10,
    helperComeback => 10,
    helperMomentum => 5,
    _ => 5,
  };

  double _smooth(double previous, double sample) =>
      (previous * scoreDecay + sample * (1 - scoreDecay)).clamp(0.0, 1.0).toDouble();

  static const maxHelpersPerGuess = 3;
  static const longStreakThreshold = 10;
  static const failureHelperThreshold = 3;
  static const rangeHelperThreshold = 5;
  static const comebackFailureThreshold = 6;
  static const momentumStreakThreshold = 5;
  static const gentleTargetMinGuesses = 5;
  static const gentleTargetMinFailures = 3;
  static const gentleTargetAccuracyCeiling = 0.45;
  static const gentleTargetBaseStrength = 0.18;
  static const gentleTargetMaxStrength = 0.25;
  static const veteranPrestigeThreshold = 10;
  static const scoreDecay = 0.92;
}
