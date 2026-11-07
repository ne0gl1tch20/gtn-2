import '../numbers/big_number.dart';
import 'progression_state.dart';

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id, required this.baseCost, required this.growthRate,
    this.maxLevel,
  });
  final String id;
  final BigNumber baseCost, growthRate;
  final int? maxLevel;

  BigNumber costAtLevel(int currentLevel) {
    if (currentLevel < 0) throw ArgumentError.value(currentLevel);
    return baseCost * growthRate.powInt(currentLevel);
  }
}

class GuessRewardModifiers {
  const GuessRewardModifiers({
    this.streakMultiplier = 1, this.criticalMultiplier = 1,
  });
  final int streakMultiplier, criticalMultiplier;
}

class PrestigeRules {
  const PrestigeRules({required this.minimumMoney, required this.rewardForMoney});
  final BigNumber minimumMoney;
  final BigNumber Function(BigNumber money) rewardForMoney;
}

class UltraRules {
  const UltraRules({
    required this.minimumMoney, required this.rewardForMoney,
    this.resetPrestigeUpgrades = true,
  });
  final BigNumber minimumMoney;
  final int Function(BigNumber money) rewardForMoney;
  final bool resetPrestigeUpgrades;
}

class ProgressionEngine {
  const ProgressionEngine();

  ProgressionState recordGuess(
    ProgressionState state, {
    required bool correct,
    BigNumber? baseReward,
    GuessRewardModifiers modifiers = const GuessRewardModifiers(),
    int upgradeMultiplier = 1,
  }) {
    if (upgradeMultiplier < 1 || modifiers.streakMultiplier < 1 ||
        modifiers.criticalMultiplier < 1) {
      throw ArgumentError('Reward multipliers must be at least one.');
    }
    final streak = correct ? state.currentStreak + 1 : 0;
    if (!correct) {
      return state.copyWith(
        totalGuesses: state.totalGuesses + 1, currentStreak: 0,
      );
    }
    var reward = baseReward ?? BigNumber.fromInt(0);
    if (reward.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Guess reward cannot be negative.');
    }
    reward = reward.multiplyInt(upgradeMultiplier)
        .multiplyInt(modifiers.streakMultiplier)
        .multiplyInt(modifiers.criticalMultiplier);
    return state.copyWith(
      money: state.money + reward,
      totalGuesses: state.totalGuesses + 1,
      correctGuesses: state.correctGuesses + 1,
      moneyEarned: state.moneyEarned + reward,
      currentStreak: streak,
      bestStreak: streak > state.bestStreak ? streak : state.bestStreak,
    );
  }

  ProgressionState purchaseUpgrade(
    ProgressionState state, UpgradeDefinition definition,
  ) {
    final level = state.upgrades[definition.id] ?? 0;
    if (definition.maxLevel != null && level >= definition.maxLevel!) return state;
    final cost = definition.costAtLevel(level);
    if (state.money.compareTo(cost) < 0) return state;
    final levels = Map<String, int>.of(state.upgrades)
      ..[definition.id] = level + 1;
    return state.copyWith(
      money: state.money - cost, upgrades: Map.unmodifiable(levels),
    );
  }

  ProgressionState prestige(ProgressionState state, PrestigeRules rules) {
    if (state.money.compareTo(rules.minimumMoney) < 0) return state;
    final reward = rules.rewardForMoney(state.money);
    if (reward.compareTo(BigNumber.fromInt(0)) <= 0) return state;
    return state.copyWith(
      money: BigNumber.fromInt(0),
      prestige: state.prestige + reward,
      upgrades: const {},
      prestigeResets: state.prestigeResets + 1,
      currentStreak: 0,
    );
  }

  ProgressionState ultra(ProgressionState state, UltraRules rules) {
    if (state.money.compareTo(rules.minimumMoney) < 0) return state;
    final rawReward = rules.rewardForMoney(state.money);
    if (rawReward <= 0) return state;
    final reward = rawReward > 2000 ? 2000 : rawReward;
    return state.copyWith(
      money: BigNumber.fromInt(0),
      prestige: BigNumber.fromInt(0),
      ultra: state.ultra + BigNumber.fromInt(reward),
      upgrades: const {},
      prestigeUpgrades: rules.resetPrestigeUpgrades
          ? const {} : state.prestigeUpgrades,
      ultraResets: state.ultraResets + 1,
      prestigeResets: 0,
      currentStreak: 0,
    );
  }

  ProgressionState awardNebulaFromArcade(
    ProgressionState state, BigNumber reward,
  ) {
    if (reward.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Nebula reward cannot be negative.');
    }
    return state.copyWith(
      nebula: state.nebula + reward,
      nebulaEarned: state.nebulaEarned + reward,
    );
  }

  ProgressionState purchaseNebulaItem(
    ProgressionState state, {
    required String itemId,
    BigNumber price = const BigNumber.fromInt(25),
  }) {
    if (itemId.isEmpty || price.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Invalid Nebula shop purchase.');
    }
    if (state.nebula.compareTo(price) < 0) return state;
    final inventory = Map<String, int>.of(state.ultraUpgrades)
      ..[itemId] = (state.ultraUpgrades[itemId] ?? 0) + 1;
    return state.copyWith(
      nebula: state.nebula - price,
      ultraUpgrades: Map.unmodifiable(inventory),
    );
  }
}
