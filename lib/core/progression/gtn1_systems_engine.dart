import 'dart:math';

import '../numbers/big_number.dart';
import 'gtn1_trait_catalog.dart';
import 'gtn1_systems_state.dart';
import 'progression_state.dart';

class Gtn1TalentDefinition {
  const Gtn1TalentDefinition(this.id, this.name, this.description, this.cost, this.parentId);
  final String id, name, description;
  final int cost;
  final String? parentId;
}

class Gtn1RelicDefinition {
  const Gtn1RelicDefinition(this.id, this.name, this.description, this.bossId, this.rarity);
  final String id, name, description, bossId, rarity;
}

class Gtn1QuestDefinition {
  const Gtn1QuestDefinition(this.id, this.title, this.target, this.rewardMoney, this.rewardNebula);
  final String id, title;
  final int target, rewardMoney, rewardNebula;
}

class StakeResult {
  const StakeResult(this.state, this.won, this.stake, this.payout);
  final ProgressionState state;
  final bool won;
  final BigNumber stake, payout;
}

/// GTN 1's gameplay transactions ported to Dart. Every method validates IDs,
/// prerequisites, affordability and one-time claims before returning new save state.
class Gtn1SystemsEngine {
  const Gtn1SystemsEngine();

  static const mutatorIds = {'mut_hardcore', 'mut_speed', 'mut_blind', 'mut_tax'};
  static const talentCatalog = <Gtn1TalentDefinition>[
    Gtn1TalentDefinition('talent_speed_1', 'Velocity Boost I', 'Increases Auto-Clicker speed by 25%.', 100, null),
    Gtn1TalentDefinition('talent_speed_2', 'Velocity Boost II', 'Increases Auto-Clicker speed by 50%.', 500, 'talent_speed_1'),
    Gtn1TalentDefinition('talent_crit_1', 'Critical Precision I', 'Increases critical guess chance by 5%.', 250, null),
    Gtn1TalentDefinition('talent_crit_2', 'Critical Precision II', 'Increases critical guess chance by 15%.', 1000, 'talent_crit_1'),
    Gtn1TalentDefinition('talent_reward_1', 'Nebula Resonance', 'Boosts Money earnings by 50%.', 2500, 'talent_crit_2'),
    Gtn1TalentDefinition('talent_master_1', 'Omniscient Oracle', 'Adds a Nebula to correct guesses.', 10000, 'talent_reward_1'),
  ];
  static const relicCatalog = <Gtn1RelicDefinition>[
    Gtn1RelicDefinition('verdant_guardian', 'Heartwood Sigil', 'A living charm from the Verdant Guardian.', 'verdant_guardian', 'Rare'),
    Gtn1RelicDefinition('crystal_golem', 'Prism Core', 'A crystal lens that remembers every guess.', 'crystal_golem', 'Rare'),
    Gtn1RelicDefinition('ember_dragon', 'Ember Scale', 'A warm scale from the Ember Dragon.', 'ember_dragon', 'Epic'),
    Gtn1RelicDefinition('nebula_titan', 'Starbound Fragment', 'A fragment of the Nebula Titan armor.', 'nebula_titan', 'Legendary'),
  ];
  static const dailyQuests = <Gtn1QuestDefinition>[
    Gtn1QuestDefinition('daily_guesses_10', 'Make 10 guesses', 10, 10000, 0),
    Gtn1QuestDefinition('daily_correct_5', 'Get 5 correct guesses', 5, 0, 25),
    Gtn1QuestDefinition('daily_streak_5', 'Reach a streak of 5', 5, 0, 35),
    Gtn1QuestDefinition('daily_upgrades_3', 'Buy 3 upgrades', 3, 0, 50),
  ];
  static const dailyRewards = [5, 10, 15, 20, 25, 30, 50];

  static int mutatorRewardMultiplier(Set<String> mutators) {
    final active = mutators.intersection(mutatorIds);
    var multiplier = 1;
    if (active.contains('mut_hardcore')) multiplier *= 2;
    if (active.contains('mut_speed')) multiplier *= 3;
    if (active.contains('mut_blind')) multiplier *= 5;
    if (active.contains('mut_tax')) multiplier *= 10;
    return multiplier;
  }

  static int mutatorRangeMultiplier(Set<String> mutators) =>
      mutators.contains('mut_hardcore') ? 2 : 1;

  ProgressionState setMutators(ProgressionState state, Set<String> selected) =>
      state.copyWith(systems: state.systems.copyWith(
        activeMutators: selected.intersection(mutatorIds),
      ));

  ProgressionState buyTalent(ProgressionState state, String id) {
    final talent = talentCatalog.where((item) => item.id == id).firstOrNull;
    if (talent == null || state.systems.unlockedTalents.contains(id)) return state;
    if (talent.parentId != null && !state.systems.unlockedTalents.contains(talent.parentId)) return state;
    final cost = BigNumber.fromInt(talent.cost);
    if (state.prestige.compareTo(cost) < 0) return state;
    return state.copyWith(
      prestige: state.prestige - cost,
      systems: state.systems.copyWith(
        unlockedTalents: {...state.systems.unlockedTalents, id},
      ),
    );
  }

  ProgressionState upgradeHomeBase(ProgressionState state) {
    final level = state.systems.homeBaseLevel;
    if (level >= 20) return state;
    final cost = BigNumber.fromInt(50000 * (level + 1));
    if (state.money.compareTo(cost) < 0) return state;
    return state.copyWith(
      money: state.money - cost,
      systems: state.systems.copyWith(homeBaseLevel: level + 1),
    );
  }

  ProgressionState equipRelic(ProgressionState state, String relicId) {
    if (!relicCatalog.any((item) => item.id == relicId) ||
        !state.systems.relicInventory.contains(relicId)) return state;
    final equipped = Set<String>.of(state.systems.equippedRelics);
    if (equipped.contains(relicId)) {
      equipped.remove(relicId);
    } else {
      if (equipped.length >= 4) return state;
      equipped.add(relicId);
    }
    return state.copyWith(systems: state.systems.copyWith(equippedRelics: Set.unmodifiable(equipped)));
  }

  ProgressionState claimBossRelic(ProgressionState state, String bossId) {
    if (!state.defeatedBosses.contains(bossId) ||
        !relicCatalog.any((item) => item.id == bossId) ||
        state.systems.relicInventory.contains(bossId)) return state;
    return state.copyWith(systems: state.systems.copyWith(
      relicInventory: {...state.systems.relicInventory, bossId},
    ));
  }

  ProgressionState claimDailyReward(ProgressionState state, {DateTime? now}) {
    final today = _dateKey(now ?? DateTime.now());
    final systems = state.systems;
    if (systems.lastDailyRewardDate == today) return state;
    final yesterday = (now ?? DateTime.now()).subtract(const Duration(days: 1));
    final streak = systems.lastDailyRewardDate == _dateKey(yesterday)
        ? (systems.dailyRewardStreak >= 7 ? 1 : systems.dailyRewardStreak + 1)
        : 1;
    final base = dailyRewards[streak - 1];
    final traitBonus = activeTraits(state, now: now).where((trait) => trait.effect == 'nebula_bonus').length.clamp(0, 100);
    final multiplier = systems.activeMutators.contains('mut_blind') ? 1 : 1;
    final reward = (base + traitBonus) * multiplier;
    return state.copyWith(
      nebula: state.nebula + BigNumber.fromInt(reward),
      nebulaEarned: state.nebulaEarned + BigNumber.fromInt(reward),
      systems: systems.copyWith(lastDailyRewardDate: today, dailyRewardStreak: streak),
    );
  }

  ProgressionState claimDailyQuest(ProgressionState state, String questId, {DateTime? now}) {
    final today = _dateKey(now ?? DateTime.now());
    var systems = state.systems;
    if (systems.dailyQuestDate != today) {
      systems = systems.copyWith(
        dailyQuestDate: today,
        dailyQuestGuesses: 0,
        dailyQuestCorrectGuesses: 0,
        dailyQuestBestStreak: 0,
        dailyQuestUpgradePurchases: 0,
        claimedDailyQuests: const {},
      );
    }
    if (systems.claimedDailyQuests.contains(questId)) return state.copyWith(systems: systems);
    final quest = dailyQuests.where((item) => item.id == questId).firstOrNull;
    if (quest == null) return state;
    final progress = switch (questId) {
      'daily_guesses_10' => systems.dailyQuestGuesses,
      'daily_correct_5' => systems.dailyQuestCorrectGuesses,
      'daily_streak_5' => systems.dailyQuestBestStreak,
      'daily_upgrades_3' => systems.dailyQuestUpgradePurchases,
      _ => 0,
    };
    if (progress < quest.target) return state.copyWith(systems: systems);
    final nebulaMultiplier = state.nebulaItems['nebula_boost'] ?? 0 > 0 ? 2 : 1;
    final money = BigNumber.fromInt(quest.rewardMoney);
    final nebula = BigNumber.fromInt(quest.rewardNebula * nebulaMultiplier);
    return state.copyWith(
      money: state.money + money,
      moneyEarned: state.moneyEarned + money,
      nebula: state.nebula + nebula,
      nebulaEarned: state.nebulaEarned + nebula,
      systems: systems.copyWith(claimedDailyQuests: {...systems.claimedDailyQuests, questId}),
    );
  }

  ProgressionState openLootChest(ProgressionState state, String tier, {Random? random}) {
    final systems = state.systems;
    final count = switch (tier) {
      'common' => systems.lootCommonChests,
      'rare' => systems.lootRareChests,
      'epic' => systems.lootEpicChests,
      _ => 0,
    };
    if (count <= 0) return state;
    final rng = random ?? Random.secure();
    final giveNebula = rng.nextBool();
    final money = BigNumber.fromInt(switch (tier) {'common' => 5000, 'rare' => 25000, 'epic' => 100000, _ => 0});
    final nebula = BigNumber.fromInt(switch (tier) {'common' => 5, 'rare' => 25, 'epic' => 100, _ => 0});
    final updatedSystems = systems.copyWith(
      lootCommonChests: systems.lootCommonChests - (tier == 'common' ? 1 : 0),
      lootRareChests: systems.lootRareChests - (tier == 'rare' ? 1 : 0),
      lootEpicChests: systems.lootEpicChests - (tier == 'epic' ? 1 : 0),
      lootChestsOpened: systems.lootChestsOpened + 1,
    );
    return state.copyWith(
      money: state.money + (giveNebula ? BigNumber.fromInt(0) : money),
      moneyEarned: state.moneyEarned + (giveNebula ? BigNumber.fromInt(0) : money),
      nebula: state.nebula + (giveNebula ? nebula : BigNumber.fromInt(0)),
      nebulaEarned: state.nebulaEarned + (giveNebula ? nebula : BigNumber.fromInt(0)),
      systems: updatedSystems,
    );
  }

  StakeResult settleStake(ProgressionState state, BigNumber amount, {Random? random}) {
    final zero = BigNumber.fromInt(0);
    if (amount.compareTo(zero) <= 0 || state.money.compareTo(amount) < 0) {
      return StakeResult(state, false, amount, zero);
    }
    final won = (random ?? Random.secure()).nextBool();
    final multiplier = BigNumber.parse((2.0 + state.currentStreak * 0.1).toString());
    final payout = won ? amount * multiplier : zero;
    final next = state.copyWith(
      money: won ? state.money - amount + payout : state.money - amount,
      moneyEarned: state.moneyEarned + payout,
      systems: state.systems.copyWith(
        stakeWins: state.systems.stakeWins + (won ? 1 : 0),
        stakeLosses: state.systems.stakeLosses + (won ? 0 : 1),
        stakeMoneyWagered: (state.systems.stakeMoneyWagered ?? zero) + amount,
        stakeMoneyWon: (state.systems.stakeMoneyWon ?? zero) + payout,
      ),
    );
    return StakeResult(next, won, amount, payout);
  }

  /// Applies the GTN 1 post-guess pipeline: trait effects, sanctuary/relic/talent
  /// bonuses, daily quest progress, hidden discoveries and chest drops.
  ProgressionState applyGuessSystems(
    ProgressionState before,
    ProgressionState after, {
    required bool correct,
    Random? random,
    DateTime? now,
  }) {
    final rng = random ?? Random.secure();
    final date = now ?? DateTime.now();
    var systems = _refreshDailyQuestDate(after.systems, date);
    systems = systems.copyWith(
      dailyQuestGuesses: systems.dailyQuestGuesses + 1,
      dailyQuestCorrectGuesses: systems.dailyQuestCorrectGuesses + (correct ? 1 : 0),
      dailyQuestBestStreak: max(systems.dailyQuestBestStreak, after.currentStreak),
    );
    var updated = after.copyWith(systems: systems);

    if (correct) {
      final earned = (after.money - before.money);
      final positiveEarned = earned.compareTo(BigNumber.fromInt(0)) > 0 ? earned : BigNumber.fromInt(0);
      var bonusRate = 0.0;
      final unlocked = before.systems.unlockedTalents;
      if (unlocked.contains('talent_reward_1')) bonusRate += 0.50;
      bonusRate += before.systems.permanentEventBoosts.clamp(0, 25) * 0.02;
      bonusRate += (before.systems.worldMasteryLevels[before.systems.activeWorldId] ?? 0).clamp(0, 10) * 0.02;
      final equipped = before.systems.equippedRelics;
      if (equipped.contains('verdant_guardian')) bonusRate += 0.10;
      if (equipped.contains('crystal_golem') && rng.nextDouble() < 0.10) bonusRate += 0.50;
      if (equipped.contains('ember_dragon')) bonusRate += 0.25;
      if (equipped.contains('nebula_titan')) bonusRate += 0.25;
      final bossRelicCount = equipped.intersection({'verdant_guardian', 'crystal_golem', 'ember_dragon', 'nebula_titan'}).length;
      bonusRate += switch (bossRelicCount) {2 => 0.10, 3 => 0.20, 4 => 0.35, _ => 0.0};
      bonusRate += (before.systems.homeBaseLevel * 0.02).clamp(0, 0.40);
      final secretForWorld = const {
        'verdant_grove': 'whispering_hollow',
        'crystal_caverns': 'shard_archive',
        'ember_summit': 'ashen_vault',
        'nebula_rift': 'lost_observatory',
      }[before.systems.activeWorldId];
      if (secretForWorld != null && before.systems.discoveredSecrets.contains(secretForWorld)) bonusRate += 0.05;
      final bonusMoney = positiveEarned * BigNumber.parse(bonusRate.toString());
      final criticalChance = unlocked.contains('talent_crit_2') ? 0.15 : unlocked.contains('talent_crit_1') ? 0.05 : 0.0;
      final criticalBonus = criticalChance > 0 && rng.nextDouble() < criticalChance ? positiveEarned : BigNumber.fromInt(0);
      final bonusNebula = (unlocked.contains('talent_master_1') ? 1 : 0) +
          (before.systems.permanentEventBoosts.clamp(0, 25) ~/ 5) +
          (equipped.contains('ember_dragon') ? 1 : 0) +
          (bossRelicCount == 4 ? 1 : 0) +
          (before.systems.discoveredSecrets.length >= 4 ? 1 : 0) +
          (before.systems.activeWorldId == 'ember_summit' && before.systems.discoveredSecrets.contains('ashen_vault') ? 1 : 0);
      final nebulaBoost = (before.nebulaItems['nebula_boost'] ?? 0) > 0 ? 2 : 1;
      var moneyBonus = bonusMoney + criticalBonus;

      // Active gameplay traits use the same thresholds, arms and bounded effects as GTN 1.
      final traits = activeTraits(before, now: now);
      final ids = traits.map((item) => item.id).toSet();
      var traitMultiplier = 1.0;
      if (ids.contains('combo_momentum') || before.currentStreak >= 5) {
        final burst = before.systems.selectedTraitArms['combo_momentum'] == 'burst';
        traitMultiplier += min(before.currentStreak * (burst ? 0.03 : 0.02), burst ? 0.25 : 0.20);
      }
      if (ids.contains('risk_reward')) {
        traitMultiplier += before.systems.selectedTraitArms['risk_reward'] == 'high_risk' ? 0.40 : 0.25;
      }
      traitMultiplier += ids.contains('comeback_reward') ? 0.05 : 0;
      traitMultiplier += ids.contains('momentum_reward') ? 0.03 : 0;
      if (traitMultiplier > 1) moneyBonus += positiveEarned * BigNumber.parse((traitMultiplier - 1).toString());
      final totalNebula = (bonusNebula + traits.where((t) => t.effect == 'nebula_bonus').length).clamp(0, 100) * nebulaBoost;
      updated = updated.copyWith(
        money: updated.money + moneyBonus,
        moneyEarned: updated.moneyEarned + moneyBonus,
        nebula: updated.nebula + BigNumber.fromInt(totalNebula),
        nebulaEarned: updated.nebulaEarned + BigNumber.fromInt(totalNebula),
      );

      final roll = rng.nextInt(1000);
      final tier = roll < 10 ? 'epic' : roll < 60 ? 'rare' : roll < 240 ? 'common' : null;
      if (tier != null) {
        final current = updated.systems;
        updated = updated.copyWith(systems: current.copyWith(
          lootEpicChests: current.lootEpicChests + (tier == 'epic' ? 1 : 0),
          lootRareChests: current.lootRareChests + (tier == 'rare' ? 1 : 0),
          lootCommonChests: current.lootCommonChests + (tier == 'common' ? 1 : 0),
          lootDropsFound: current.lootDropsFound + 1,
          lastLootDropTier: tier,
        ));
      }
    } else {
      final active = activeTraits(before, now: now).map((item) => item.id).toSet();
      final taxRate = before.systems.activeMutators.contains('mut_tax') ? 0.05 : 0.0;
      final originalPenalty = before.money - after.money;
      final penalty = taxRate > 0 ? before.money * BigNumber.parse(taxRate.toString()) : BigNumber.fromInt(0);
      final refundRate = before.systems.selectedTraitArms['mistake_insurance'] == 'careful' ? 0.75 : 0.50;
      final refund = active.contains('mistake_insurance') ? penalty * BigNumber.parse(refundRate.toString()) : BigNumber.fromInt(0);
      final extraPenaltyRate = before.systems.selectedTraitArms['risk_reward'] == 'high_risk' ? 0.20 : 0.10;
      final extraPenalty = active.contains('risk_reward') ? before.money * BigNumber.parse(extraPenaltyRate.toString()) : BigNumber.fromInt(0);
      final totalPenalty = penalty + extraPenalty - refund;
      final money = totalPenalty.compareTo(BigNumber.fromInt(0)) > 0
          ? (updated.money - totalPenalty).compareTo(BigNumber.fromInt(0)) < 0 ? BigNumber.fromInt(0) : updated.money - totalPenalty
          : updated.money;
      updated = updated.copyWith(
        money: money,
        systems: updated.systems.copyWith(
          // Keep a streak when the matching gameplay trait is active.
          dailyQuestBestStreak: max(updated.systems.dailyQuestBestStreak, before.currentStreak),
        ),
      );
      if (active.contains('streak_guard')) {
        updated = updated.copyWith(currentStreak: before.currentStreak);
      }
      if (active.contains('range_scout')) {
        // The range hint is applied by the host to the next input bounds.
      }
    }

    updated = _discoverTraits(updated, date);
    updated = _unlockAchievements(updated);
    return updated;
  }

  List<Gtn1TraitDefinition> activeTraits(ProgressionState state, {DateTime? now}) {
    final date = now ?? DateTime.now();
    final season = _seasonFor(date);
    final eligible = gtn1TraitCatalog.where((trait) {
      if (trait.hidden && !state.systems.discoveredTraits.contains(trait.id)) return false;
      if (trait.category == 'seasonal' && trait.seasonId != season) return false;
      return state.correctGuesses >= trait.minimumCorrectGuesses &&
          state.prestigeResets >= trait.minimumPrestige &&
          state.bestStreak >= trait.minimumBestStreak;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));
    final accepted = <String, Gtn1TraitDefinition>{};
    for (final trait in eligible) {
      if (trait.conflicts.any(accepted.containsKey) ||
          accepted.values.any((item) => item.conflicts.contains(trait.id))) continue;
      accepted[trait.id] = trait;
    }
    var changed = true;
    while (changed) {
      changed = false;
      final remove = accepted.values.where((trait) =>
          trait.dependencies.any((id) => !accepted.containsKey(id))).map((t) => t.id).toList();
      for (final id in remove) {
        accepted.remove(id);
        changed = true;
      }
    }
    return accepted.values.toList(growable: false);
  }

  ProgressionState _discoverTraits(ProgressionState state, DateTime date) {
    final discovered = Set<String>.of(state.systems.discoveredTraits);
    var changed = true;
    while (changed) {
      changed = false;
      for (final trait in gtn1TraitCatalog.where((item) => item.hidden)) {
        if (discovered.contains(trait.id) ||
            trait.dependencies.any((id) => !discovered.contains(id)) ||
            (trait.category == 'seasonal' && trait.seasonId != _seasonFor(date)) ||
            state.prestigeResets < trait.minimumPrestige ||
            state.correctGuesses < trait.minimumCorrectGuesses ||
            state.bestStreak < trait.minimumBestStreak) continue;
        discovered.add(trait.id);
        changed = true;
      }
    }
    return state.copyWith(systems: state.systems.copyWith(discoveredTraits: Set.unmodifiable(discovered)));
  }

  ProgressionState _unlockAchievements(ProgressionState state) {
    final milestones = <String, bool>{
      'correct_10': state.correctGuesses >= 10,
      'correct_50': state.correctGuesses >= 50,
      'correct_100': state.correctGuesses >= 100,
      'correct_500': state.correctGuesses >= 500,
      'streak_5': state.bestStreak >= 5,
      'streak_10': state.bestStreak >= 10,
      'streak_25': state.bestStreak >= 25,
      'streak_50': state.bestStreak >= 50,
      'millionaire': state.money.compareTo(BigNumber.fromInt(1000000)) >= 0,
      'ten_millionaire': state.money.compareTo(BigNumber.fromInt(10000000)) >= 0,
      'hundred_millionaire': state.money.compareTo(BigNumber.fromInt(100000000)) >= 0,
      'billionaire': state.money.compareTo(BigNumber.fromInt(1000000000)) >= 0,
      'prestige_1': state.prestigeResets >= 1,
      'prestige_5': state.prestigeResets >= 5,
      'prestige_10': state.prestigeResets >= 10,
      'prestige_25': state.prestigeResets >= 25,
      'ultra_1': state.ultraResets >= 1,
      'ultra_3': state.ultraResets >= 3,
      'ultra_10': state.ultraResets >= 10,
      'ultra_25': state.ultraResets >= 25,
      'playtime_1h': state.systems.playtimeSeconds >= 3600,
      'playtime_10h': state.systems.playtimeSeconds >= 36000,
      'playtime_50h': state.systems.playtimeSeconds >= 180000,
      'frenzy_5': state.bestStreak >= 5,
      'frenzy_10': state.bestStreak >= 10,
      'frenzy_25': state.bestStreak >= 25,
      'frenzy_50': state.bestStreak >= 50,
    };
    final unlocked = milestones.entries.where((e) => e.value).map((e) => e.key).toSet();
    final newlyUnlocked = unlocked.difference(state.systems.achievements);
    if (newlyUnlocked.isEmpty) return state;
    const rewards = {
      'correct_10': 10, 'correct_50': 20, 'correct_100': 40, 'correct_500': 100,
      'streak_5': 25, 'streak_10': 50, 'streak_25': 100, 'streak_50': 250,
      'millionaire': 50, 'ten_millionaire': 100, 'hundred_millionaire': 200, 'billionaire': 500,
      'prestige_1': 25, 'prestige_5': 75, 'prestige_10': 150, 'prestige_25': 300,
      'ultra_1': 100, 'ultra_3': 250, 'ultra_10': 500, 'ultra_25': 1000,
      'playtime_1h': 25, 'playtime_10h': 100, 'playtime_50h': 300,
      'frenzy_5': 30, 'frenzy_10': 75, 'frenzy_25': 150, 'frenzy_50': 350,
    };
    final reward = newlyUnlocked.fold<int>(0, (sum, id) => sum + (rewards[id] ?? 0));
    return state.copyWith(
      nebula: state.nebula + BigNumber.fromInt(reward),
      nebulaEarned: state.nebulaEarned + BigNumber.fromInt(reward),
      systems: state.systems.copyWith(achievements: {...state.systems.achievements, ...newlyUnlocked}),
    );
  }

  Gtn1SystemsState _refreshDailyQuestDate(Gtn1SystemsState systems, DateTime date) {
    final today = _dateKey(date);
    if (systems.dailyQuestDate == today) return systems;
    return systems.copyWith(
      dailyQuestDate: today,
      dailyQuestGuesses: 0,
      dailyQuestCorrectGuesses: 0,
      dailyQuestBestStreak: 0,
      dailyQuestUpgradePurchases: 0,
      claimedDailyQuests: const {},
    );
  }

  String _seasonFor(DateTime date) {
    final month = date.month;
    if (month == 12 || month <= 2) return 'winter';
    if (month <= 5) return 'spring';
    if (month <= 8) return 'summer';
    return 'autumn';
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
