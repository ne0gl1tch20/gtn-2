import '../../worlds/world_boss_battle_engine.dart';
import '../../worlds/world_boss_catalog.dart';
import '../numbers/big_number.dart';
import '../progression/progression_state.dart';
import 'builtin_trait_catalog.dart';
import 'legacy_systems_state.dart';

/// A validated definition loaded from the pinned GTN1 talent catalog.
class TalentDefinition {
  const TalentDefinition({
    required this.id,
    required this.cost,
    this.requiredParentId,
  });

  final String id;
  final int cost;
  final String? requiredParentId;
}

class LegacyActionResult {
  const LegacyActionResult({
    required this.progression,
    required this.systems,
    required this.accepted,
    this.message = '',
  });
  final ProgressionState progression;
  final LegacySystemsState systems;
  final bool accepted;
  final String message;
}

/// Deterministic economy and progression rules ported from GTN 1's shared Kotlin rules.
class LegacySystemsEngine {
  const LegacySystemsEngine();

  static final _zero = BigNumber.fromInt(0);
  static final _mutators = <String>{
    'mut_hardcore',
    'mut_speed',
    'mut_blind',
    'mut_tax',
  };
  static const _bossRelics = <String>{
    'verdant_guardian',
    'crystal_golem',
    'ember_dragon',
    'nebula_titan',
  };

  static const gameplayArms = <String, Set<String>>{
    'combo_momentum': {'steady', 'burst'},
    'mistake_insurance': {'half_refund', 'careful'},
    'risk_reward': {'balanced', 'high_risk'},
  };

  LegacyActionResult setMutator(
    ProgressionState progression,
    LegacySystemsState systems,
    String id,
    bool active,
  ) {
    if (!_mutators.contains(id)) {
      return _reject(progression, systems, 'Unknown mutator.');
    }
    final next = Set<String>.of(systems.activeMutators);
    if (active) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return _accept(
      progression,
      systems.copyWith(activeMutators: Set.unmodifiable(next)),
    );
  }

  /// Matches shared MutatorRules.kt. Hardcore doubles the search range.
  BigNumber mutatorRewardMultiplier(LegacySystemsState systems) {
    var multiplier = BigNumber.fromInt(1);
    for (final entry in const <String, int>{
      'mut_hardcore': 2,
      'mut_speed': 3,
      'mut_blind': 5,
      'mut_tax': 10,
    }.entries) {
      if (systems.activeMutators.contains(entry.key)) {
        multiplier = multiplier.multiplyInt(entry.value);
      }
    }
    return multiplier;
  }

  int rangeMultiplier(LegacySystemsState systems) =>
      systems.activeMutators.contains('mut_hardcore') ? 2 : 1;

  LegacyActionResult buyTalent(
    ProgressionState progression,
    LegacySystemsState systems,
    TalentDefinition definition,
  ) {
    final talentId = definition.id;
    if (talentId.isEmpty ||
        definition.cost <= 0 ||
        definition.requiredParentId == talentId) {
      return _reject(progression, systems, 'Invalid talent definition.');
    }
    if (systems.talents.contains(talentId)) {
      return _reject(progression, systems, 'Talent already purchased.');
    }
    final parent = definition.requiredParentId;
    if (parent != null && !systems.talents.contains(parent)) {
      return _reject(progression, systems, 'Unlock the parent talent first.');
    }
    final cost = BigNumber.fromInt(definition.cost);
    if (progression.prestige.compareTo(cost) < 0) {
      return _reject(progression, systems, 'Not enough Prestige.');
    }
    final owned = Set<String>.of(systems.talents)..add(talentId);
    return _accept(
      progression.copyWith(prestige: progression.prestige - cost),
      systems.copyWith(talents: Set.unmodifiable(owned)),
    );
  }

  LegacyActionResult upgradeHomeBase(
    ProgressionState progression,
    LegacySystemsState systems,
  ) {
    if (systems.homeBaseLevel >= 20) {
      return _reject(progression, systems, 'Home Base is fully restored.');
    }
    final cost = BigNumber.fromInt(50000 * (systems.homeBaseLevel + 1));
    if (progression.money.compareTo(cost) < 0) {
      return _reject(progression, systems, 'Not enough Money.');
    }
    return _accept(
      progression.copyWith(
        money: progression.money - cost,
        moneyEarned: progression.moneyEarned,
      ),
      systems.copyWith(homeBaseLevel: systems.homeBaseLevel + 1),
    );
  }

  LegacyActionResult equipRelic(
    ProgressionState progression,
    LegacySystemsState systems,
    String relicId,
  ) {
    if (!_bossRelics.contains(relicId) ||
        !systems.relicInventory.contains(relicId)) {
      return _reject(progression, systems, 'Relic is not owned.');
    }
    final equipped = Set<String>.of(systems.equippedRelics);
    if (equipped.contains(relicId)) {
      equipped.remove(relicId);
    } else {
      if (equipped.length >= 4) {
        return _reject(
          progression,
          systems,
          'Only four relics can be equipped.',
        );
      }
      equipped.add(relicId);
    }
    return _accept(
      progression,
      systems.copyWith(equippedRelics: Set.unmodifiable(equipped)),
    );
  }

  LegacySystemsState unlockBossRelic(
    LegacySystemsState systems,
    String bossId,
  ) {
    if (!_bossRelics.contains(bossId)) return systems;
    return systems.copyWith(
      relicInventory: Set.unmodifiable({...systems.relicInventory, bossId}),
    );
  }

  /// Applies deterministic reward bonuses; criticalHit is decided by the caller's injected RNG.
  BigNumber correctGuessReward({
    required BigNumber baseReward,
    required LegacySystemsState systems,
    required bool criticalHit,
  }) {
    var multiplier = BigNumber.fromInt(1);
    if (systems.talents.contains('talent_reward_1')) {
      multiplier += BigNumber.parse('0.5');
    }
    multiplier += BigNumber.parse(
      (systems.homeBaseLevel * 0.02).clamp(0, 0.40).toStringAsFixed(2),
    );
    final equipped = systems.equippedRelics.intersection(_bossRelics);
    final setBonus = switch (equipped.length) {
      2 => '0.10',
      3 => '0.20',
      4 => '0.35',
      _ => '0',
    };
    multiplier += BigNumber.parse(setBonus);
    if (equipped.contains('verdant_guardian')) {
      multiplier += BigNumber.parse('0.10');
    }
    if (equipped.contains('crystal_golem') && criticalHit) {
      multiplier += BigNumber.parse('0.50');
    }
    if (equipped.contains('ember_dragon')) {
      multiplier += BigNumber.parse('0.25');
    }
    if (equipped.contains('nebula_titan')) {
      multiplier += BigNumber.parse('0.25');
    }
    return baseReward * multiplier;
  }

  ProgressionState applyCorrectGuessBonuses({
    required ProgressionState before,
    required ProgressionState after,
    required LegacySystemsState systems,
    bool criticalHit = false,
    bool crystalCoreProc = false,
    bool nebulaBoostOwned = false,
  }) {
    final earned = after.money - before.money;
    if (earned.compareTo(_zero) <= 0) return after;
    var bonusMoney = _zero;
    if (systems.talents.contains('talent_reward_1')) {
      bonusMoney += earned * BigNumber.parse('0.5');
    }
    final eventBoost = systems.permanentEventBoosts.clamp(0, 25);
    if (eventBoost > 0) {
      bonusMoney +=
          earned * BigNumber.parse((eventBoost * 0.02).toStringAsFixed(2));
    }
    final mastery = (systems.worldMasteryLevels[systems.activeWorldId] ?? 0)
        .clamp(0, 10);
    if (mastery > 0) {
      bonusMoney +=
          earned * BigNumber.parse((mastery * 0.02).toStringAsFixed(2));
    }
    if (criticalHit &&
        (systems.talents.contains('talent_crit_1') ||
            systems.talents.contains('talent_crit_2'))) {
      bonusMoney += earned;
    }
    final equipped = systems.equippedRelics.intersection(_bossRelics);
    if (equipped.contains('verdant_guardian')) {
      bonusMoney += earned * BigNumber.parse('0.10');
    }
    if (equipped.contains('crystal_golem') && crystalCoreProc) {
      bonusMoney += earned * BigNumber.parse('0.50');
    }
    if (equipped.contains('ember_dragon')) {
      bonusMoney += earned * BigNumber.parse('0.25');
    }
    if (equipped.contains('nebula_titan')) {
      bonusMoney += earned * BigNumber.parse('0.25');
    }
    final setBonus = switch (equipped.length) {
      2 => '0.10',
      3 => '0.20',
      4 => '0.35',
      _ => '0',
    };
    bonusMoney += earned * BigNumber.parse(setBonus);
    bonusMoney +=
        earned *
        BigNumber.parse(
          (systems.homeBaseLevel * 0.02).clamp(0, 0.40).toStringAsFixed(2),
        );
    const secretForWorld = <String, String>{
      'verdant_grove': 'whispering_hollow',
      'crystal_caverns': 'shard_archive',
      'ember_summit': 'ashen_vault',
      'nebula_rift': 'lost_observatory',
    };
    final activeSecret = secretForWorld[systems.activeWorldId];
    if (activeSecret != null &&
        systems.discoveredSecrets.contains(activeSecret)) {
      bonusMoney += earned * BigNumber.parse('0.05');
    }
    final bonusNebula =
        (systems.talents.contains('talent_master_1') ? 1 : 0) +
        (eventBoost ~/ 5) +
        (equipped.contains('ember_dragon') ? 1 : 0) +
        (equipped.length == 4 ? 1 : 0) +
        (systems.discoveredSecrets.length >= 4 ? 1 : 0) +
        (systems.activeWorldId == 'ember_summit' &&
                systems.discoveredSecrets.contains('ashen_vault')
            ? 1
            : 0);
    final actualNebula = bonusNebula * (nebulaBoostOwned ? 2 : 1);
    final nebula = BigNumber.fromInt(actualNebula);
    return after.copyWith(
      money: after.money + bonusMoney,
      moneyEarned: after.moneyEarned + bonusMoney,
      nebula: after.nebula + nebula,
      nebulaEarned: after.nebulaEarned + nebula,
    );
  }

  /// Validates a wager before the caller consumes randomness.
  String? validateLuckyStake({
    required ProgressionState progression,
    required BigNumber stake,
  }) {
    if (stake.compareTo(_zero) <= 0) return 'Stake must be positive.';
    if (progression.money.compareTo(stake) < 0) return 'Not enough Money.';
    return null;
  }

  LegacyActionResult settleLuckyStake({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required BigNumber stake,
    required bool won,
    required int currentStreak,
  }) {
    final validationError = validateLuckyStake(
      progression: progression,
      stake: stake,
    );
    if (validationError != null) {
      return _reject(progression, systems, validationError);
    }
    final payout = won
        ? stake * BigNumber.fromParts(BigInt.from(20 + currentStreak), 1)
        : _zero;
    final money = progression.money - stake + payout;
    final updated = progression.copyWith(
      money: money,
      moneyEarned: progression.moneyEarned + payout,
    );
    return _accept(
      updated,
      systems.copyWith(
        stakesPlaced: systems.stakesPlaced + 1,
        stakesWon: systems.stakesWon + (won ? 1 : 0),
        stakesLost: systems.stakesLost + (won ? 0 : 1),
      ),
    );
  }

  LegacyActionResult claimDailyReward({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String today,
    int traitNebulaBonus = 0,
    bool nebulaBoostOwned = false,
  }) {
    if (!_validDate(today)) {
      return _reject(progression, systems, 'Invalid claim date.');
    }
    if (systems.lastDailyRewardDate == today) {
      return _reject(progression, systems, 'Daily reward already claimed.');
    }
    final yesterday = DateTime.parse(today)
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final streak = systems.lastDailyRewardDate == yesterday
        ? (systems.dailyRewardStreak >= 7 ? 1 : systems.dailyRewardStreak + 1)
              .clamp(1, 7)
        : 1;
    const rewards = [5, 10, 15, 20, 25, 30, 50];
    final base = rewards[streak - 1] + traitNebulaBonus;
    final reward = base * (nebulaBoostOwned ? 2 : 1);
    return _accept(
      progression.copyWith(
        nebula: progression.nebula + BigNumber.fromInt(reward),
        nebulaEarned: progression.nebulaEarned + BigNumber.fromInt(reward),
      ),
      systems.copyWith(lastDailyRewardDate: today, dailyRewardStreak: streak),
    );
  }

  LegacyActionResult claimDailyQuest({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String questId,
    required String today,
    bool nebulaBoostOwned = false,
  }) {
    if (!_validDate(today)) {
      return _reject(progression, systems, 'Invalid claim date.');
    }
    var current = systems;
    if (current.dailyQuestDate != today) {
      current = current.copyWith(
        dailyQuestDate: today,
        dailyQuestGuesses: 0,
        dailyQuestCorrectGuesses: 0,
        dailyQuestBestStreak: 0,
        dailyQuestUpgradePurchases: 0,
        claimedDailyQuests: const {},
      );
    }
    final requirements = <String, bool>{
      'daily_guesses_10': current.dailyQuestGuesses >= 10,
      'daily_correct_5': current.dailyQuestCorrectGuesses >= 5,
      'daily_streak_5': current.dailyQuestBestStreak >= 5,
      'daily_upgrades_3': current.dailyQuestUpgradePurchases >= 3,
    };
    if (requirements[questId] != true ||
        current.claimedDailyQuests.contains(questId)) {
      return _reject(progression, current, 'Quest is not claimable.');
    }
    final multiplier = nebulaBoostOwned ? 2 : 1;
    var updated = progression;
    switch (questId) {
      case 'daily_guesses_10':
        final reward = BigNumber.fromInt(10000);
        updated = updated.copyWith(
          money: updated.money + reward,
          moneyEarned: updated.moneyEarned + reward,
        );
        break;
      case 'daily_correct_5':
        updated = _addNebula(updated, 25 * multiplier);
        break;
      case 'daily_streak_5':
        updated = _addNebula(updated, 50 * multiplier);
        break;
      case 'daily_upgrades_3':
        updated = _addNebula(updated, 35 * multiplier);
        break;
    }
    return _accept(
      updated,
      current.copyWith(
        claimedDailyQuests: Set.unmodifiable({
          ...current.claimedDailyQuests,
          questId,
        }),
      ),
    );
  }

  LegacyActionResult openLootChest({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String tier,
    required bool rewardNebula,
  }) {
    const money = {'common': 5000, 'rare': 25000, 'epic': 100000};
    const nebula = {'common': 5, 'rare': 25, 'epic': 100};
    final available = systems.lootChests[tier];
    if (available == null || available <= 0) {
      return _reject(progression, systems, 'No chest available.');
    }
    final chests = Map<String, int>.of(systems.lootChests)
      ..[tier] = available - 1;
    var updated = progression;
    if (rewardNebula) {
      updated = _addNebula(updated, nebula[tier]!);
    } else {
      final reward = BigNumber.fromInt(money[tier]!);
      updated = updated.copyWith(
        money: updated.money + reward,
        moneyEarned: updated.moneyEarned + reward,
      );
    }
    return _accept(
      updated,
      systems.copyWith(
        lootChests: Map.unmodifiable(chests),
        lootChestsOpened: systems.lootChestsOpened + 1,
      ),
    );
  }

  LegacyActionResult upgradeWorldMastery({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String worldId,
  }) {
    const relicByWorld = <String, String>{
      'verdant_grove': 'verdant_guardian',
      'crystal_caverns': 'crystal_golem',
      'ember_summit': 'ember_dragon',
      'nebula_rift': 'nebula_titan',
    };
    final relicId = relicByWorld[worldId];
    final worldMatches = WorldBossCatalog.worlds.where(
      (world) => world.id == worldId,
    );
    final world = worldMatches.isEmpty ? null : worldMatches.first;
    if (relicId == null ||
        world == null ||
        !systems.unlockedWorldIds.contains(worldId) ||
        !WorldBossCatalog.isDefeated(progression, world)) {
      return _reject(
        progression,
        systems,
        'Defeat this world guardian before upgrading mastery.',
      );
    }
    final current = systems.worldMasteryLevels[worldId] ?? 1;
    if (current >= 10) {
      return _reject(progression, systems, 'Mastery is already at level 10.');
    }
    final secretId = const <String, String>{
      'verdant_grove': 'whispering_hollow',
      'crystal_caverns': 'shard_archive',
      'ember_summit': 'ashen_vault',
      'nebula_rift': 'lost_observatory',
    }[worldId]!;
    final secretDiscount = systems.discoveredSecrets.contains(secretId)
        ? 0.20
        : 0.0;
    final sanctuaryDiscount = (systems.homeBaseLevel * 0.01)
        .clamp(0.0, 0.20)
        .toDouble();
    final allRelics = systems.equippedRelics.containsAll(_bossRelics);
    final relicDiscount = allRelics ? 0.10 : 0.0;
    final discount = (secretDiscount + sanctuaryDiscount + relicDiscount)
        .clamp(0.0, 0.40)
        .toDouble();
    final cost =
        BigNumber.fromInt(10 * (current + 1)) *
        BigNumber.parse((1 - discount).toStringAsFixed(2));
    if (progression.nebula.compareTo(cost) < 0) {
      return _reject(
        progression,
        systems,
        'Not enough Nebula for this mastery upgrade.',
      );
    }
    final nextLevel = current + 1;
    final reward = nextLevel == 5
        ? 25
        : nextLevel == 10
        ? 100
        : 0;
    final entries = <String>{...systems.codexEntries};
    if (nextLevel == 5 || nextLevel == 10) {
      entries.add('mastery:$worldId:$nextLevel');
    }
    final levels = Map<String, int>.of(systems.worldMasteryLevels)
      ..[worldId] = nextLevel;
    final nebulaReward = BigNumber.fromInt(reward);
    return _accept(
      progression.copyWith(
        nebula: progression.nebula - cost + nebulaReward,
        nebulaEarned: progression.nebulaEarned + nebulaReward,
      ),
      systems.copyWith(
        worldMasteryLevels: Map.unmodifiable(levels),
        codexEntries: Set.unmodifiable(entries),
      ),
    );
  }

  LegacyActionResult discoverSecret({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String secretId,
  }) {
    const worlds = <String, String>{
      'whispering_hollow': 'verdant_grove',
      'shard_archive': 'crystal_caverns',
      'ashen_vault': 'ember_summit',
      'lost_observatory': 'nebula_rift',
    };
    const thresholds = <String, int>{
      'whispering_hollow': 50,
      'shard_archive': 150,
      'ashen_vault': 300,
      'lost_observatory': 600,
    };
    const moneyRewards = <String, int>{
      'whispering_hollow': 10000,
      'shard_archive': 50000,
      'ashen_vault': 250000,
      'lost_observatory': 1000000,
    };
    const nebulaRewards = <String, int>{
      'whispering_hollow': 5,
      'shard_archive': 15,
      'ashen_vault': 50,
      'lost_observatory': 150,
    };
    final worldId = worlds[secretId];
    if (worldId == null) {
      return _reject(progression, systems, 'Unknown secret area.');
    }
    if (systems.discoveredSecrets.contains(secretId)) {
      return _reject(progression, systems, 'Secret area already discovered.');
    }
    final worldMatches = WorldBossCatalog.worlds.where(
      (world) => world.id == worldId,
    );
    final world = worldMatches.isEmpty ? null : worldMatches.first;
    if (world == null ||
        !systems.unlockedWorldIds.contains(worldId) ||
        progression.correctGuesses < thresholds[secretId]!) {
      return _reject(progression, systems, 'Secret area is still hidden.');
    }
    final money = BigNumber.fromInt(moneyRewards[secretId]!);
    final nebula = BigNumber.fromInt(nebulaRewards[secretId]!);
    return _accept(
      progression.copyWith(
        money: progression.money + money,
        moneyEarned: progression.moneyEarned + money,
        nebula: progression.nebula + nebula,
        nebulaEarned: progression.nebulaEarned + nebula,
      ),
      systems.copyWith(
        discoveredSecrets: Set.unmodifiable({
          ...systems.discoveredSecrets,
          secretId,
        }),
        codexEntries: Set.unmodifiable({
          ...systems.codexEntries,
          'secret:$secretId',
        }),
      ),
    );
  }

  LegacyActionResult claimCodexCompletionReward(
    ProgressionState progression,
    LegacySystemsState systems,
  ) {
    const required = <String>{
      'world:verdant_grove',
      'world:crystal_caverns',
      'world:ember_summit',
      'world:nebula_rift',
      'boss:verdant_guardian',
      'boss:crystal_golem',
      'boss:ember_dragon',
      'boss:nebula_titan',
      'secret:whispering_hollow',
      'secret:shard_archive',
      'secret:ashen_vault',
      'secret:lost_observatory',
    };
    if (systems.codexRewardClaimed) {
      return _reject(
        progression,
        systems,
        'Codex completion reward already claimed.',
      );
    }
    if (!systems.codexEntries.containsAll(required)) {
      return _reject(
        progression,
        systems,
        'Discover all 12 Codex entries first.',
      );
    }
    return _accept(
      _addNebula(progression, 100),
      systems.copyWith(codexRewardClaimed: true),
    );
  }

  LegacyActionResult claimEndgameReward(
    ProgressionState progression,
    LegacySystemsState systems,
    String rewardId,
  ) {
    const allWorlds = <String>{
      'verdant_grove',
      'crystal_caverns',
      'ember_summit',
      'nebula_rift',
    };
    const allSecrets = <String>{
      'whispering_hollow',
      'shard_archive',
      'ashen_vault',
      'lost_observatory',
    };
    const rewards = <String, (int, int)>{
      'all_bosses': (250, 2000000),
      'all_secrets': (200, 1000000),
      'all_relics': (300, 1000000),
      'sanctuary_10': (500, 5000000),
      'rift_tier_10': (1000, 10000000),
      'mastery_all_5': (400, 5000000),
    };
    if (systems.endgameRewardsClaimed.contains(rewardId)) {
      return _reject(progression, systems, 'Endgame reward already claimed.');
    }
    final eligible = switch (rewardId) {
      'all_bosses' => progression.defeatedBosses.containsAll(allWorlds),
      'all_secrets' => systems.discoveredSecrets.containsAll(allSecrets),
      'all_relics' => systems.relicInventory.containsAll(_bossRelics),
      'sanctuary_10' => systems.homeBaseLevel >= 10,
      'rift_tier_10' => systems.endlessRiftBestTier >= 10,
      'mastery_all_5' => allWorlds.every(
        (id) => (systems.worldMasteryLevels[id] ?? 0) >= 5,
      ),
      _ => false,
    };
    final reward = rewards[rewardId];
    if (!eligible || reward == null) {
      return _reject(progression, systems, 'Endgame goal is not complete.');
    }
    final nebula = BigNumber.fromInt(reward.$1);
    final money = BigNumber.fromInt(reward.$2);
    return _accept(
      progression.copyWith(
        money: progression.money + money,
        moneyEarned: progression.moneyEarned + money,
        nebula: progression.nebula + nebula,
        nebulaEarned: progression.nebulaEarned + nebula,
      ),
      systems.copyWith(
        endgameRewardsClaimed: Set.unmodifiable({
          ...systems.endgameRewardsClaimed,
          rewardId,
        }),
      ),
    );
  }

  LegacyActionResult setEndlessRift({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required bool active,
  }) {
    if (active) {
      if (systems.endlessRiftActive) {
        return _reject(progression, systems, 'Endless Rift is already active.');
      }
      if (!WorldBossCatalog.worlds.every(
        (world) => WorldBossCatalog.isDefeated(progression, world),
      )) {
        return _reject(
          progression,
          systems,
          'Defeat all four world bosses first.',
        );
      }
      final tier = systems.endlessRiftBestTier + 1 > 1
          ? systems.endlessRiftBestTier + 1
          : 1;
      final firstWorld = WorldBossCatalog.worlds.first;
      final bossDamage = Map<String, int>.of(progression.bossDamage)
        ..[firstWorld.bossId] = 0
        ..[firstWorld.id] = 0;
      return _accept(
        progression.copyWith(bossDamage: Map.unmodifiable(bossDamage)),
        systems.copyWith(
          endlessRiftActive: true,
          endlessRiftTier: tier,
          activeWorldId: firstWorld.id,
          activeBossBattleWorldId: firstWorld.id,
          unlockedWorldIds: Set.unmodifiable(
            WorldBossCatalog.worlds.map((world) => world.id),
          ),
          bossBattleMistakes: Map.unmodifiable({
            ...systems.bossBattleMistakes,
            firstWorld.bossId: 0,
          }),
        ),
      );
    }
    if (!systems.endlessRiftActive) {
      return _reject(progression, systems, 'Endless Rift is not active.');
    }
    return _accept(
      progression,
      systems.copyWith(endlessRiftActive: false, clearActiveBossBattle: true),
    );
  }

  LegacyActionResult attackEndlessRiftBoss(
    ProgressionState progression,
    LegacySystemsState systems,
  ) {
    final result = const WorldBossBattleEngine().recordGuess(
      progression.copyWith(legacySystems: systems),
      correct: true,
    );
    return LegacyActionResult(
      progression: result.progression,
      systems: result.progression.legacySystems,
      accepted: result.accepted,
      message: result.message,
    );
  }

  LegacyActionResult recordEndlessRiftMiss(
    ProgressionState progression,
    LegacySystemsState systems,
  ) {
    final result = const WorldBossBattleEngine().recordGuess(
      progression.copyWith(legacySystems: systems),
      correct: false,
    );
    return LegacyActionResult(
      progression: result.progression,
      systems: result.progression.legacySystems,
      accepted: result.accepted,
      message: result.message,
    );
  }

  LegacyActionResult claimChallenge({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String challengeId,
    required int nebulaReward,
    required bool eligible,
    bool nebulaBoostOwned = false,
  }) {
    if (challengeId.isEmpty ||
        nebulaReward <= 0 ||
        !eligible ||
        systems.completedChallenges.contains(challengeId)) {
      return _reject(progression, systems, 'Challenge is not claimable.');
    }
    final reward = nebulaReward * (nebulaBoostOwned ? 2 : 1);
    return _accept(
      _addNebula(progression, reward),
      systems.copyWith(
        completedChallenges: Set.unmodifiable({
          ...systems.completedChallenges,
          challengeId,
        }),
      ),
    );
  }

  LegacySystemsState recordGuessProgress(
    LegacySystemsState systems, {
    required bool correct,
    required int currentStreak,
    String? today,
    int? lootRoll,
  }) {
    final date = today ?? DateTime.now().toIso8601String().substring(0, 10);
    final current = systems.dailyQuestDate == date
        ? systems
        : systems.copyWith(
            dailyQuestDate: date,
            dailyQuestGuesses: 0,
            dailyQuestCorrectGuesses: 0,
            dailyQuestBestStreak: 0,
            dailyQuestUpgradePurchases: 0,
            claimedDailyQuests: const {},
          );
    final progressed = current.copyWith(
      dailyQuestGuesses: current.dailyQuestGuesses + 1,
      dailyQuestCorrectGuesses:
          current.dailyQuestCorrectGuesses + (correct ? 1 : 0),
      dailyQuestBestStreak: currentStreak > current.dailyQuestBestStreak
          ? currentStreak
          : current.dailyQuestBestStreak,
    );
    if (!correct || lootRoll == null || lootRoll < 0 || lootRoll > 999) {
      return progressed;
    }
    final tier = switch (lootRoll) {
      >= 0 && <= 9 => 'epic',
      >= 10 && <= 59 => 'rare',
      >= 60 && <= 239 => 'common',
      _ => null,
    };
    if (tier == null) return progressed;
    final chests = Map<String, int>.of(progressed.lootChests)
      ..[tier] = (progressed.lootChests[tier] ?? 0) + 1;
    return progressed.copyWith(
      lootChests: Map.unmodifiable(chests),
      lootDropsFound: progressed.lootDropsFound + 1,
      lastLootDropTier: tier,
      lootEventId: progressed.lootEventId + 1,
    );
  }

  LegacySystemsState recordUpgradePurchase(LegacySystemsState systems) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final current = systems.dailyQuestDate == today
        ? systems
        : systems.copyWith(
            dailyQuestDate: today,
            dailyQuestGuesses: 0,
            dailyQuestCorrectGuesses: 0,
            dailyQuestBestStreak: 0,
            dailyQuestUpgradePurchases: 0,
            claimedDailyQuests: const {},
          );
    return current.copyWith(
      dailyQuestUpgradePurchases: current.dailyQuestUpgradePurchases + 1,
    );
  }

  TraitEffectSummary evaluateTraits({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required int playerLevel,
    required String? activeSeasonId,
  }) {
    final definitions = builtInTraitCatalog
        .map((item) => _Trait.fromMap(item))
        .toList();
    final eligible = definitions.where((trait) {
      if (trait.category == 'SEASONAL' && trait.seasonId != activeSeasonId) {
        return false;
      }
      if (trait.visibility == 'HIDDEN' &&
          !systems.discoveredTraits.contains(trait.id)) {
        return false;
      }
      return playerLevel >= trait.minimumLevel &&
          progression.prestigeResets >= trait.minimumPrestige &&
          progression.correctGuesses >= trait.minimumCorrect &&
          progression.bestStreak >= trait.minimumBestStreak;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));
    final accepted = <String, _Trait>{};
    for (final trait in eligible) {
      if (trait.conflicts.any(accepted.containsKey) ||
          accepted.values.any((value) => value.conflicts.contains(trait.id))) {
        continue;
      }
      accepted[trait.id] = trait;
    }
    var changed = true;
    while (changed) {
      changed = false;
      final remove = accepted.values
          .where(
            (trait) =>
                trait.dependencies.any((id) => !accepted.containsKey(id)),
          )
          .map((trait) => trait.id)
          .toList();
      for (final id in remove) {
        accepted.remove(id);
        changed = true;
      }
    }
    final active = accepted.values.toList();
    final activeIds = active.map((trait) => trait.id).toSet();
    final xpCount = active
        .where((trait) => trait.effect == 'XP_MULTIPLIER')
        .length;
    final nebulaCount = active
        .where((trait) => trait.effect == 'NEBULA_BONUS')
        .length;
    var correctGuessBonus = 0.0;
    if (activeIds.contains('combo_momentum')) {
      final burst = systems.selectedTraitArms['combo_momentum'] == 'burst';
      final perStreak = burst ? 0.03 : 0.02;
      final cap = burst ? 0.25 : 0.20;
      correctGuessBonus += (progression.currentStreak * perStreak).clamp(
        0.0,
        cap,
      );
    }
    if (activeIds.contains('risk_reward')) {
      correctGuessBonus +=
          systems.selectedTraitArms['risk_reward'] == 'high_risk' ? 0.40 : 0.25;
    }
    final hasInsurance = activeIds.contains('mistake_insurance');
    final highRisk = systems.selectedTraitArms['risk_reward'] == 'high_risk';
    final cosmeticBadgeTraitIds = active
        .where((trait) => trait.effect == 'COSMETIC_BADGE')
        .map((trait) => trait.id)
        .toSet();
    return TraitEffectSummary(
      xpMultiplier: (1 + xpCount * 0.05).clamp(1.0, 2.0).toDouble(),
      nebulaBonusPerClaim: nebulaCount.clamp(0, 100).toInt(),
      streakProtection:
          activeIds.contains('streak_guard') ||
          activeIds.contains('focus_streak'),
      correctGuessMultiplier: 1.0 + correctGuessBonus,
      missPenaltyRefundRate: hasInsurance
          ? (systems.selectedTraitArms['mistake_insurance'] == 'careful'
                ? 0.75
                : 0.50)
          : 0.0,
      riskMissPenaltyRate: activeIds.contains('risk_reward')
          ? (highRisk ? 0.20 : 0.10)
          : 0.0,
      rangeHint: activeIds.contains('range_scout'),
      activeTraitIds: Set.unmodifiable(activeIds),
      discoveredHiddenTraitIds: Set.unmodifiable(
        definitions
            .where(
              (trait) =>
                  trait.visibility == 'HIDDEN' &&
                  systems.discoveredTraits.contains(trait.id),
            )
            .map((trait) => trait.id),
      ),
      cosmeticBadgeTraitIds: Set.unmodifiable(cosmeticBadgeTraitIds),
    );
  }

  LegacySystemsState discoverEligibleTraits({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String? activeSeasonId,
  }) {
    final discovered = Set<String>.of(systems.discoveredTraits);
    var changed = true;
    while (changed) {
      changed = false;
      for (final item in builtInTraitCatalog) {
        if (item['visibility'] != 'HIDDEN') {
          continue;
        }
        final traitId = item['id']! as String;
        if (discovered.contains(traitId)) {
          continue;
        }
        if (item['category'] == 'SEASONAL' &&
            item['seasonId'] != activeSeasonId) {
          continue;
        }
        final dependencies = (item['dependencies']! as List<Object?>)
            .cast<String>();
        if (progression.prestigeResets < (item['minPrestige']! as int) ||
            progression.correctGuesses < (item['minCorrect']! as int) ||
            progression.bestStreak < (item['minStreak']! as int) ||
            !dependencies.every(discovered.contains)) {
          continue;
        }
        discovered.add(traitId);
        changed = true;
      }
    }
    return systems.copyWith(discoveredTraits: Set.unmodifiable(discovered));
  }

  LegacyActionResult selectTraitArm({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String traitId,
    required String armId,
    required int playerLevel,
    required String? activeSeasonId,
  }) {
    final allowed = gameplayArms[traitId];
    if (allowed == null || !allowed.contains(armId)) {
      return _reject(progression, systems, 'Unknown trait arm.');
    }
    final active = evaluateTraits(
      progression: progression,
      systems: systems,
      playerLevel: playerLevel,
      activeSeasonId: activeSeasonId,
    );
    if (!active.activeTraitIds.contains(traitId)) {
      return _reject(progression, systems, 'Trait is not active.');
    }
    return _accept(
      progression,
      systems.copyWith(
        selectedTraitArms: Map.unmodifiable({
          ...systems.selectedTraitArms,
          traitId: armId,
        }),
      ),
    );
  }

  static ProgressionState _addNebula(ProgressionState state, int amount) {
    final reward = BigNumber.fromInt(amount);
    return state.copyWith(
      nebula: state.nebula + reward,
      nebulaEarned: state.nebulaEarned + reward,
    );
  }

  static bool _validDate(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
      DateTime.tryParse(value) != null;

  static LegacyActionResult _accept(ProgressionState p, LegacySystemsState s) =>
      LegacyActionResult(progression: p, systems: s, accepted: true);

  static LegacyActionResult _reject(
    ProgressionState p,
    LegacySystemsState s,
    String message,
  ) => LegacyActionResult(
    progression: p,
    systems: s,
    accepted: false,
    message: message,
  );
}

class _Trait {
  const _Trait({
    required this.id,
    required this.category,
    required this.effect,
    required this.visibility,
    required this.seasonId,
    required this.minimumLevel,
    required this.minimumPrestige,
    required this.minimumCorrect,
    required this.minimumBestStreak,
    required this.dependencies,
    required this.conflicts,
  });
  final String id, category, effect, visibility;
  final String? seasonId;
  final int minimumLevel, minimumPrestige, minimumCorrect, minimumBestStreak;
  final Set<String> dependencies, conflicts;

  factory _Trait.fromMap(Map<String, Object?> map) => _Trait(
    id: map['id']! as String,
    category: map['category']! as String,
    effect: map['effect']! as String,
    visibility: map['visibility']! as String,
    seasonId: map['seasonId'] as String?,
    minimumLevel: map['minLevel']! as int,
    minimumPrestige: map['minPrestige']! as int,
    minimumCorrect: map['minCorrect']! as int,
    minimumBestStreak: map['minStreak']! as int,
    dependencies: Set<String>.from(
      (map['dependencies']! as List).cast<String>(),
    ),
    conflicts: Set<String>.from((map['conflicts']! as List).cast<String>()),
  );
}
