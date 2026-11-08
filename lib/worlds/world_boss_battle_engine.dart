import '../core/numbers/big_number.dart';
import '../core/game/guess_economy_rules.dart';
import '../core/progression/progression_state.dart';
import 'world_boss_catalog.dart';

class WorldBossActionResult {
  const WorldBossActionResult({
    required this.progression,
    required this.accepted,
    this.message = '',
  });

  final ProgressionState progression;
  final bool accepted;
  final String message;
}

/// Deterministic port of GTN1's worldProgressAction boss battle rules.
class WorldBossBattleEngine {
  const WorldBossBattleEngine();

  static const _bossIds = {
    'verdant_guardian', 'crystal_golem', 'ember_dragon', 'nebula_titan',
  };

  ProgressionState migrateLegacyWorldUnlocks(ProgressionState state) {
    final systems = state.legacySystems;
    if (!systems.worldUnlockMigrationPending) return state;
    final unlocked = Set<String>.of(systems.unlockedWorldIds);
    final totalUpgrades = WorldBossCatalog.ownedUpgradeLevels(state);
    for (var index = 1; index < WorldBossCatalog.worlds.length; index++) {
      final world = WorldBossCatalog.worlds[index];
      final previousWorld = WorldBossCatalog.worlds[index - 1];
      final previousBossDefeated =
          state.defeatedBosses.contains(previousWorld.id) ||
          state.defeatedBosses.contains(previousWorld.bossId) ||
          systems.relicInventory.contains(previousWorld.bossId);
      final wasUnlockedByLegacyFlutter = previousBossDefeated &&
          state.correctGuesses >= world.unlockCorrectGuesses &&
          totalUpgrades >= world.unlockUpgradeCount &&
          state.prestigeResets >= world.unlockPrestigeCount &&
          state.ultraResets >= world.unlockUltraCount;
      if (wasUnlockedByLegacyFlutter) unlocked.add(world.id);
    }
    return state.copyWith(
      legacySystems: systems.copyWith(
        unlockedWorldIds: Set.unmodifiable(unlocked),
        worldUnlockMigrationPending: false,
      ),
    );
  }

  WorldBossActionResult discoverSecret(ProgressionState state, String secretId) {
    final matches = WorldBossCatalog.worlds.where((item) => item.secretId == secretId);
    final world = matches.isEmpty ? null : matches.first;
    if (world == null ||
        !WorldBossCatalog.isUnlocked(state, world) ||
        state.correctGuesses < world.secretAt ||
        state.legacySystems.discoveredSecrets.contains(secretId)) {
      return WorldBossActionResult(
        progression: state,
        accepted: false,
        message: 'Secret area is not discoverable yet.',
      );
    }
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
    final moneyReward = BigNumber.fromInt(moneyRewards[secretId]!);
    final nebulaReward = BigNumber.fromInt(nebulaRewards[secretId]!);
    final secrets = Set<String>.of(state.legacySystems.discoveredSecrets)
      ..add(secretId);
    final codex = Set<String>.of(state.legacySystems.codexEntries)
      ..add('secret:$secretId');
    return WorldBossActionResult(
      progression: state.copyWith(
        money: state.money + moneyReward,
        moneyEarned: state.moneyEarned + moneyReward,
        nebula: state.nebula + nebulaReward,
        nebulaEarned: state.nebulaEarned + nebulaReward,
        legacySystems: state.legacySystems.copyWith(
          discoveredSecrets: Set.unmodifiable(secrets),
          codexEntries: Set.unmodifiable(codex),
        ),
      ),
      accepted: true,
      message: 'Discovered secret area: $secretId.',
    );
  }

  WorldBossActionResult unlockWorld(ProgressionState state, String worldId) {
    final matches = WorldBossCatalog.worlds.where((item) => item.id == worldId);
    final world = matches.isEmpty ? null : matches.first;
    if (world == null || !WorldBossCatalog.canUnlock(state, world)) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'World unlock requirements are not met.',
      );
    }
    final unlocked = Set<String>.of(state.legacySystems.unlockedWorldIds)
      ..add(worldId);
    return WorldBossActionResult(
      progression: state.copyWith(
        legacySystems: state.legacySystems.copyWith(
          unlockedWorldIds: Set.unmodifiable(unlocked),
          worldUnlockMigrationPending: false,
          activeWorldId: worldId,
        ),
      ),
      accepted: true,
      message: 'Unlocked ${world.worldName}.',
    );
  }

  WorldBossActionResult selectWorld(ProgressionState state, String worldId) {
    final matches = WorldBossCatalog.worlds.where((item) => item.id == worldId);
    final world = matches.isEmpty ? null : matches.first;
    if (world == null || !WorldBossCatalog.isUnlocked(state, world)) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'World is locked.',
      );
    }
    if (state.legacySystems.endlessRiftActive &&
        worldId != state.legacySystems.activeWorldId) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'Stop the Endless Rift before changing worlds.',
      );
    }
    final systems = state.legacySystems.copyWith(
      activeWorldId: worldId,
      clearActiveBossBattle: state.legacySystems.activeBossBattleWorldId != worldId,
    );
    return WorldBossActionResult(
      progression: state.copyWith(legacySystems: systems),
      accepted: true,
      message: 'Selected ${world.worldName}.',
    );
  }

  WorldBossActionResult toggleBossBattle(ProgressionState state, String worldId) {
    final matches = WorldBossCatalog.worlds.where((item) => item.id == worldId);
    final world = matches.isEmpty ? null : matches.first;
    if (world == null || !WorldBossCatalog.isUnlocked(state, world) ||
        (WorldBossCatalog.isDefeated(state, world) &&
            !state.legacySystems.endlessRiftActive)) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'Boss battle is not available.',
      );
    }
    if (state.legacySystems.activeBossBattleWorldId == worldId) {
      return WorldBossActionResult(
        progression: state.copyWith(
          legacySystems: state.legacySystems.copyWith(clearActiveBossBattle: true),
        ),
        accepted: true,
        message: 'Boss battle paused.',
      );
    }
    if (!state.legacySystems.endlessRiftActive &&
        !WorldBossCatalog.canFight(state, world)) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'Boss fight requirements are not met.',
      );
    }
    final mistakes = Map<String, int>.of(state.legacySystems.bossBattleMistakes)
      ..putIfAbsent(world.bossId, () => 0);
    return WorldBossActionResult(
      progression: state.copyWith(
        legacySystems: state.legacySystems.copyWith(
          activeWorldId: worldId,
          activeBossBattleWorldId: worldId,
          bossBattleMistakes: Map.unmodifiable(mistakes),
        ),
      ),
      accepted: true,
      message: 'Boss battle started: ${world.name}.',
    );
  }

  WorldBossActionResult recordGuess(
    ProgressionState state, {
    required bool correct,
  }) {
    final systems = state.legacySystems;
    final matches = WorldBossCatalog.worlds
        .where((item) => item.id == systems.activeBossBattleWorldId);
    final world = matches.isEmpty ? null : matches.first;
    if (world == null || !WorldBossCatalog.isUnlocked(state, world) ||
        (WorldBossCatalog.isDefeated(state, world) && !systems.endlessRiftActive)) {
      return WorldBossActionResult(
        progression: state, accepted: false, message: 'No active world boss.',
      );
    }

    final tier = systems.endlessRiftActive ? systems.endlessRiftTier.clamp(1, 1000000).toInt() : 1;
    final hp = world.hits + (systems.endlessRiftActive ? (tier - 1) * 2 : 0);
    final oldDamage = state.bossDamage[world.bossId] ?? state.bossDamage[world.id] ?? 0;
    final mistakes = Map<String, int>.of(systems.bossBattleMistakes);
    final damage = Map<String, int>.of(state.bossDamage);

    if (!correct) {
      final nextMisses = (mistakes[world.bossId] ?? 0) + 1;
      final phase = ((oldDamage * 3) ~/ hp + 1).clamp(1, 3);
      final interval = switch (phase) { 1 => 4, 2 => 3, _ => 2 };
      final nextDamage = nextMisses % interval == 0
          ? (oldDamage - 1).clamp(0, hp).toInt()
          : oldDamage;
      damage[world.bossId] = nextDamage;
      damage[world.id] = nextDamage;
      mistakes[world.bossId] = nextMisses;
      return WorldBossActionResult(
        progression: state.copyWith(
          bossDamage: Map.unmodifiable(damage),
          legacySystems: systems.copyWith(bossBattleMistakes: Map.unmodifiable(mistakes)),
        ),
        accepted: true,
        message: 'Boss resisted the miss.',
      );
    }

    final nextDamage = oldDamage + 1;
    if (nextDamage < hp) {
      final oldPhase = ((oldDamage * 3) ~/ hp + 1).clamp(1, 3);
      final newPhase = ((nextDamage * 3) ~/ hp + 1).clamp(1, 3);
      if (newPhase != oldPhase) mistakes[world.bossId] = 0;
      damage[world.bossId] = nextDamage;
      damage[world.id] = nextDamage;
      return WorldBossActionResult(
        progression: state.copyWith(
          bossDamage: Map.unmodifiable(damage),
          legacySystems: systems.copyWith(bossBattleMistakes: Map.unmodifiable(mistakes)),
        ),
        accepted: true,
        message: 'Boss hit: $nextDamage/$hp.',
      );
    }

    final (bonusMoney, bonusNebula) = _progressionRewardBonus(state, world);
    final baseMoney = BigNumber.fromInt(world.moneyReward);
    final baseNebula = BigNumber.fromInt(world.nebulaReward);
    final rewardMultiplier = BigNumber.fromInt(tier);
    final riftMoneyReward = (baseMoney + bonusMoney) * rewardMultiplier;
    // GTN1 applies permanent Prestige/Ultra Money boosts to normal boss
    // victories, while Endless Rift uses its tier-scaled reward directly.
    final moneyReward = systems.endlessRiftActive
        ? riftMoneyReward
        : riftMoneyReward * GuessEconomyRules.moneyEarningMultiplier(state);
    final nebulaReward = (baseNebula + BigNumber.fromInt(bonusNebula)) * rewardMultiplier;
    damage[world.bossId] = hp;
    damage[world.id] = hp;
    final nextSystems = systems.copyWith(
      worldBossVictories: systems.worldBossVictories + 1,
      bossBattleMistakes: Map.unmodifiable(mistakes),
    );

    if (systems.endlessRiftActive) {
      final nextIndex = (WorldBossCatalog.worlds.indexOf(world) + 1) % WorldBossCatalog.worlds.length;
      final nextWorld = WorldBossCatalog.worlds[nextIndex];
      damage[nextWorld.bossId] = 0;
      damage[nextWorld.id] = 0;
      mistakes[nextWorld.bossId] = 0;
      return WorldBossActionResult(
        progression: state.copyWith(
          money: state.money + moneyReward,
          moneyEarned: state.moneyEarned + moneyReward,
          nebula: state.nebula + nebulaReward,
          nebulaEarned: state.nebulaEarned + nebulaReward,
          bossDamage: Map.unmodifiable(damage),
          legacySystems: nextSystems.copyWith(
            activeWorldId: nextWorld.id,
            activeBossBattleWorldId: nextWorld.id,
            endlessRiftTier: tier + 1,
            endlessRiftBestTier: systems.endlessRiftBestTier > tier
                ? systems.endlessRiftBestTier : tier,
            bossBattleMistakes: Map.unmodifiable(mistakes),
          ),
        ),
        accepted: true,
        message: 'Endless Rift tier $tier cleared.',
      );
    }

    final defeated = Set<String>.of(state.defeatedBosses)..add(world.bossId);
    final relics = Set<String>.of(systems.relicInventory)..add(world.bossId);
    final codex = Set<String>.of(systems.codexEntries)
      ..add('world:${world.id}')
      ..add('boss:${world.bossId}');
    final mastery = Map<String, int>.of(systems.worldMasteryLevels)
      ..[world.id] = (systems.worldMasteryLevels[world.id] ?? 0) + 1;
    return WorldBossActionResult(
      progression: state.copyWith(
        defeatedBosses: Set.unmodifiable(defeated),
        money: state.money + moneyReward,
        moneyEarned: state.moneyEarned + moneyReward,
        nebula: state.nebula + nebulaReward,
        nebulaEarned: state.nebulaEarned + nebulaReward,
        bossDamage: Map.unmodifiable(damage),
        legacySystems: nextSystems.copyWith(
          clearActiveBossBattle: true,
          relicInventory: Set.unmodifiable(relics),
          codexEntries: Set.unmodifiable(codex),
          worldMasteryLevels: Map.unmodifiable(mastery),
        ),
      ),
      accepted: true,
      message: '${world.name} defeated! Rewards claimed.',
    );
  }

  (BigNumber, int) _progressionRewardBonus(
    ProgressionState state,
    WorldBossDefinition world,
  ) {
    final relicCount = state.legacySystems.equippedRelics.intersection(_bossIds).length;
    final setRate = switch (relicCount) { 2 => 0.10, 3 => 0.20, 4 => 0.35, _ => 0.0 };
    final masteryRate = (state.legacySystems.worldMasteryLevels[world.id] ?? 0)
        .clamp(0, 10).toDouble() * 0.02;
    final sanctuaryRate = (state.legacySystems.homeBaseLevel.clamp(0, 20) * 0.02)
        .clamp(0.0, 0.40).toDouble();
    final eventRate = state.legacySystems.permanentEventBoosts.clamp(0, 25).toDouble() * 0.02;
    final secretRate = state.legacySystems.discoveredSecrets.contains(world.secretId) ? 0.05 : 0.0;
    final bonusMoney = BigNumber.fromInt(world.moneyReward) *
        BigNumber.parse((setRate + masteryRate + sanctuaryRate + eventRate + secretRate).toStringAsFixed(2));
    final bonusNebula = (relicCount == 4 ? 10 : 0) +
        ((state.legacySystems.worldMasteryLevels[world.id] ?? 0) >= 5 ? 5 : 0) +
        (state.legacySystems.discoveredSecrets.contains(world.secretId) ? 5 : 0);
    return (bonusMoney, bonusNebula);
  }
}
