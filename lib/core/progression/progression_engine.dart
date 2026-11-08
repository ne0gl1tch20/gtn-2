import '../../worlds/world_boss_catalog.dart';
import '../numbers/big_number.dart';
import 'progression_state.dart';

class UpgradeDefinition {
  UpgradeDefinition({
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
  const PrestigeRules({
    required this.minimumMoney,
    required this.rewardForMoney,
    this.startingCapital,
  });
  final BigNumber minimumMoney;
  final BigNumber Function(BigNumber money) rewardForMoney;
  final BigNumber? startingCapital;
}

class UltraRules {
  const UltraRules({
    required this.minimumMoney, required this.rewardForMoney,
    this.resetPrestigeUpgrades = true,
    this.startingCapital,
  });
  final BigNumber minimumMoney;
  final int Function(BigNumber money) rewardForMoney;
  final bool resetPrestigeUpgrades;
  final BigNumber? startingCapital;
}

class ProgressionEngine {
  const ProgressionEngine();

  ProgressionState recordGuess(
    ProgressionState state, {
    required bool correct,
    BigNumber? baseReward,
    BigNumber? flatBonusReward,
    GuessRewardModifiers modifiers = const GuessRewardModifiers(),
    int upgradeMultiplier = 1,
    bool isBot = false,
  }) {
    if (upgradeMultiplier < 1 || modifiers.streakMultiplier < 1 ||
        modifiers.criticalMultiplier < 1) {
      throw ArgumentError('Reward multipliers must be at least one.');
    }
    final streak = correct ? state.currentStreak + 1 : 0;
    if (!correct) {
      return state.copyWith(
        totalGuesses: state.totalGuesses + (isBot ? 0 : 1),
        currentStreak: isBot ? state.currentStreak : 0,
      );
    }
    var reward = baseReward ?? BigNumber.fromInt(0);
    final bonus = flatBonusReward ?? BigNumber.fromInt(0);
    if (reward.compareTo(BigNumber.fromInt(0)) < 0 ||
        bonus.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Guess rewards cannot be negative.');
    }
    reward = (reward + bonus)
        .multiplyInt(upgradeMultiplier)
        .multiplyInt(modifiers.streakMultiplier)
        .multiplyInt(modifiers.criticalMultiplier);
    return state.copyWith(
      money: state.money + reward,
      totalGuesses: state.totalGuesses + (isBot ? 0 : 1),
      correctGuesses: state.correctGuesses + (isBot ? 0 : 1),
      moneyEarned: state.moneyEarned + reward,
      currentStreak: isBot ? state.currentStreak : streak,
      bestStreak: isBot ? state.bestStreak : streak > state.bestStreak ? streak : state.bestStreak,
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

  ProgressionState purchasePrestigeUpgrade(
    ProgressionState state,
    UpgradeDefinition definition,
  ) {
    final level = state.prestigeUpgrades[definition.id] ?? 0;
    if (definition.maxLevel != null && level >= definition.maxLevel!) return state;
    final cost = definition.costAtLevel(level);
    if (state.prestige.compareTo(cost) < 0) return state;
    final levels = Map<String, int>.of(state.prestigeUpgrades)
      ..[definition.id] = level + 1;
    return state.copyWith(
      prestige: state.prestige - cost,
      prestigeUpgrades: Map.unmodifiable(levels),
    );
  }

  ProgressionState purchaseUltraUpgrade(
    ProgressionState state,
    UpgradeDefinition definition,
  ) {
    final level = state.ultraUpgrades[definition.id] ?? 0;
    if (definition.maxLevel != null && level >= definition.maxLevel!) return state;
    final cost = definition.costAtLevel(level);
    if (state.ultra.compareTo(cost) < 0) return state;
    final levels = Map<String, int>.of(state.ultraUpgrades)
      ..[definition.id] = level + 1;
    return state.copyWith(
      ultra: state.ultra - cost,
      ultraUpgrades: Map.unmodifiable(levels),
    );
  }

  ProgressionState prestige(ProgressionState state, PrestigeRules rules) {
    if (state.money.compareTo(rules.minimumMoney) < 0) return state;
    final reward = rules.rewardForMoney(state.money);
    if (reward.compareTo(BigNumber.fromInt(0)) <= 0) return state;
    return state.copyWith(
      money: rules.startingCapital ?? BigNumber.fromInt(0),
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
      money: rules.startingCapital ?? BigNumber.fromInt(0),
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

  ProgressionState attackWorldBoss(
    ProgressionState state,
    WorldBossDefinition boss,
  ) {
    if (!WorldBossCatalog.canFight(state, boss) ||
        WorldBossCatalog.isDefeated(state, boss)) {
      return state;
    }
    final nextDamage = WorldBossCatalog.damage(state, boss) + 1;
    final damage = Map<String, int>.of(state.bossDamage)
      ..[boss.id] = nextDamage;
    if (nextDamage < boss.hits) {
      return state.copyWith(bossDamage: Map.unmodifiable(damage));
    }
    final defeated = Set<String>.of(state.defeatedBosses)..add(boss.id);
    final moneyReward = BigNumber.fromInt(boss.moneyReward);
    final nebulaReward = BigNumber.fromInt(boss.nebulaReward);
    const relicByWorld = <String, String>{
      'verdant_grove': 'verdant_guardian',
      'crystal_caverns': 'crystal_golem',
      'ember_summit': 'ember_dragon',
      'nebula_rift': 'nebula_titan',
    };
    final relicId = relicByWorld[boss.id];
    final relicInventory = Set<String>.of(state.legacySystems.relicInventory);
    if (relicId != null) relicInventory.add(relicId);
    final codexEntries = Set<String>.of(state.legacySystems.codexEntries)
      ..add('world:${boss.id}')
      ..add('boss:${relicId ?? boss.id}');
    return state.copyWith(
      bossDamage: Map.unmodifiable(damage),
      defeatedBosses: Set.unmodifiable(defeated),
      money: state.money + moneyReward,
      moneyEarned: state.moneyEarned + moneyReward,
      nebula: state.nebula + nebulaReward,
      nebulaEarned: state.nebulaEarned + nebulaReward,
      legacySystems: state.legacySystems.copyWith(
        relicInventory: Set.unmodifiable(relicInventory),
        codexEntries: Set.unmodifiable(codexEntries),
      ),
    );
  }

  ProgressionState awardArcadeReward(
    ProgressionState state, {
    required BigNumber nebulaReward,
    required BigNumber moneyReward,
  }) {
    final zero = BigNumber.fromInt(0);
    if (nebulaReward.compareTo(zero) < 0 || moneyReward.compareTo(zero) < 0) {
      throw ArgumentError('Arcade rewards cannot be negative.');
    }
    final nebulaUpgradeLevel =
        (state.ultraUpgrades['ultra_nebula_boost'] ?? 0).clamp(0, 15);
    final shopMultiplier =
        (state.nebulaItems['nebula_boost'] ?? 0) > 0 ? 2 : 1;
    final nebulaMultiplier = (1 + nebulaUpgradeLevel) * shopMultiplier;
    final actualNebulaReward = nebulaReward.multiplyInt(nebulaMultiplier);
    return state.copyWith(
      nebula: state.nebula + actualNebulaReward,
      nebulaEarned: state.nebulaEarned + actualNebulaReward,
      money: state.money + moneyReward,
      moneyEarned: state.moneyEarned + moneyReward,
    );
  }

  ProgressionState awardNebulaFromArcade(
    ProgressionState state, BigNumber reward,
  ) {
    if (reward.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Nebula reward cannot be negative.');
    }
    final ultraLevel =
        (state.ultraUpgrades['ultra_nebula_boost'] ?? 0).clamp(0, 15);
    final shopMultiplier =
        (state.nebulaItems['nebula_boost'] ?? 0) > 0 ? 2 : 1;
    final actualReward = reward.multiplyInt((1 + ultraLevel) * shopMultiplier);
    return state.copyWith(
      nebula: state.nebula + actualReward,
      nebulaEarned: state.nebulaEarned + actualReward,
    );
  }

  ProgressionState purchaseNebulaItem(
    ProgressionState state, {
    required String itemId,
    BigNumber? price,
  }) {
    final itemPrice = price ?? BigNumber.fromInt(25);
    if (itemId.isEmpty || itemPrice.compareTo(BigNumber.fromInt(0)) < 0) {
      throw ArgumentError('Invalid Nebula shop purchase.');
    }
    if (state.nebula.compareTo(itemPrice) < 0) return state;
    final inventory = Map<String, int>.of(state.nebulaItems)
      ..[itemId] = (state.nebulaItems[itemId] ?? 0) + 1;
    return state.copyWith(
      nebula: state.nebula - itemPrice,
      nebulaItems: Map.unmodifiable(inventory),
    );
  }
}
