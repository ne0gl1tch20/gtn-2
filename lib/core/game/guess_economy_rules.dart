import '../numbers/big_number.dart';
import '../progression/progression_state.dart';
import 'difficulty_rules.dart';

/// Exact reward policy shared by GTN1 Android and Windows gameplay.
///
/// Currency is kept in BigNumber throughout the calculation. Random critical
/// rolls stay at the caller boundary so tests can supply deterministic results.
class GuessEconomyRules {
  const GuessEconomyRules._();

  static const int frenzyThreshold = 5;
  static const double frenzyBonusPerTier = 0.25;
  static const double frenzyMaximumMultiplier = 5.0;
  static const int baseRewardPerRangeUnit = 100;
  static const int minimumGuessReward = 10;
  static const double criticalMultiplier = 5.0;

  static double criticalChance(int precisionUpgradeLevel) =>
      0.05 + precisionUpgradeLevel * 0.01;

  static double streakMultiplier(int streak) => 1.0 + streak * 0.1;

  static double frenzyMultiplier(int streak) {
    if (streak < frenzyThreshold) return 1.0;
    final tiers = streak ~/ frenzyThreshold;
    final multiplier = 1.0 + tiers * frenzyBonusPerTier;
    return multiplier > frenzyMaximumMultiplier
        ? frenzyMaximumMultiplier
        : multiplier;
  }

  /// GTN1's permanent Money upgrades apply to every money reward.
  static BigNumber moneyEarningMultiplier(ProgressionState state) {
    final prestigeLevel = (state.prestigeUpgrades['prestige_money_boost'] ?? 0)
        .clamp(0, 50);
    final ultraLevel = (state.ultraUpgrades['ultra_money_boost'] ?? 0).clamp(
      0,
      20,
    );
    final prestige = BigNumber.parse(
      (1.0 + prestigeLevel * 0.5).toStringAsFixed(2),
    );
    final ultra = BigNumber.parse((1.0 + ultraLevel * 2.0).toStringAsFixed(2));
    return prestige * ultra;
  }

  /// Mirrors GuessEconomyDecisionRules.resolve + GameEngine.processGuess.
  static BigNumber correctGuessReward({
    required int rangeMaximum,
    required int currentStreak,
    required int rewardMultiplierLevel,
    required bool hasTalentReward,
    required bool isCritical,
    required String difficultyId,
    required BigNumber mutatorMultiplier,
    required BigNumber traitMultiplier,
    required BigNumber permanentMoneyMultiplier,
    bool infiniteSingularityOwned = false,
  }) {
    if (rangeMaximum < 1 || currentStreak < 0 || rewardMultiplierLevel < 0) {
      throw ArgumentError('Invalid guess economy input.');
    }

    final base = BigNumber.fromInt(baseRewardPerRangeUnit)
        .multiplyInt(rangeMaximum);
    final streak = _decimal(streakMultiplier(currentStreak));
    final frenzy = _decimal(frenzyMultiplier(currentStreak));
    final critical = BigNumber.parse(
      isCritical ? criticalMultiplier.toStringAsFixed(2) : '1',
    );
    final upgrade = _decimal(1.0 + rewardMultiplierLevel * 0.25);
    final talent = BigNumber.parse(hasTalentReward ? '1.5' : '1');
    final difficulty = _decimal(DifficultyRules.rewardMultiplier(difficultyId));
    final singularity = BigNumber.parse(infiniteSingularityOwned ? '2' : '1');

    final calculated =
        base *
        streak *
        frenzy *
        critical *
        upgrade *
        talent *
        mutatorMultiplier *
        difficulty *
        traitMultiplier *
        singularity;
    final minimum = BigNumber.fromInt(minimumGuessReward);
    final minimumAdjusted = calculated.compareTo(minimum) < 0
        ? minimum
        : calculated;
    return minimumAdjusted * permanentMoneyMultiplier;
  }

  static BigNumber _decimal(double value) =>
      BigNumber.parse(value.toStringAsFixed(4));
}
