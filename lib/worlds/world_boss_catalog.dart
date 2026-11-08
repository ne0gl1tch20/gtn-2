import '../core/progression/progression_state.dart';

class WorldBossDefinition {
  const WorldBossDefinition({
    required this.id,
    required this.bossId,
    required this.name,
    required this.worldName,
    required this.worldNameKey,
    required this.bossNameKey,
    required this.worldRequirementKey,
    required this.bossRequirementKey,
    required this.bossRewardKey,
    required this.x,
    required this.y,
    required this.secretId,
    required this.secretAt,
    required this.unlockCorrectGuesses,
    required this.unlockUpgradeCount,
    required this.unlockPrestigeCount,
    required this.unlockUltraCount,
    required this.fightCorrectGuesses,
    required this.fightUpgradeCount,
    required this.fightPrestigeCount,
    required this.fightUltraCount,
    required this.hits,
    required this.moneyReward,
    required this.nebulaReward,
    this.unlockBossId,
  });

  final String id;
  final String bossId;
  final String name;
  final String worldName;
  final String worldNameKey;
  final String bossNameKey;
  final String worldRequirementKey;
  final String bossRequirementKey;
  final String bossRewardKey;
  final double x;
  final double y;
  final String secretId;
  final int secretAt;
  final String? unlockBossId;
  final int unlockCorrectGuesses;
  final int unlockUpgradeCount;
  final int unlockPrestigeCount;
  final int unlockUltraCount;
  final int fightCorrectGuesses;
  final int fightUpgradeCount;
  final int fightPrestigeCount;
  final int fightUltraCount;
  final int hits;
  final int moneyReward;
  final int nebulaReward;

  // Compatibility aliases for the earlier simplified Flutter map.
  int get correctRequirement => fightCorrectGuesses;
  int get upgradeRequirement => fightUpgradeCount;
  int get prestigeRequirement => fightPrestigeCount;
  int get ultraRequirement => fightUltraCount;
  String? get previousBossId => unlockBossId;
}

class WorldBossCatalog {
  WorldBossCatalog._();

  static const worlds = <WorldBossDefinition>[
    WorldBossDefinition(
      id: 'verdant_grove', bossId: 'verdant_guardian',
      name: 'Verdant Guardian',
      worldName: 'Verdant Grove', worldNameKey: 'world_verdant_name',
      bossNameKey: 'boss_verdant_name',
      worldRequirementKey: 'world_verdant_requirement',
      bossRequirementKey: 'boss_verdant_requirement', bossRewardKey: 'boss_verdant_reward',
      x: 0.16, y: 0.24, secretId: 'whispering_hollow', secretAt: 50,
      unlockCorrectGuesses: 0, unlockUpgradeCount: 0,
      unlockPrestigeCount: 0, unlockUltraCount: 0,
      fightCorrectGuesses: 10, fightUpgradeCount: 3,
      fightPrestigeCount: 0, fightUltraCount: 0,
      hits: 3, moneyReward: 25000, nebulaReward: 10,
    ),
    WorldBossDefinition(
      id: 'crystal_caverns', bossId: 'crystal_golem',
      name: 'Crystal Golem',
      worldName: 'Crystal Caverns', worldNameKey: 'world_crystal_name',
      bossNameKey: 'boss_crystal_name',
      worldRequirementKey: 'world_crystal_requirement',
      bossRequirementKey: 'boss_crystal_requirement', bossRewardKey: 'boss_crystal_reward',
      x: 0.43, y: 0.43, secretId: 'shard_archive', secretAt: 150,
      unlockBossId: 'verdant_guardian', unlockCorrectGuesses: 25,
      unlockUpgradeCount: 5, unlockPrestigeCount: 0, unlockUltraCount: 0,
      fightCorrectGuesses: 50, fightUpgradeCount: 10,
      fightPrestigeCount: 0, fightUltraCount: 0,
      hits: 5, moneyReward: 100000, nebulaReward: 25,
    ),
    WorldBossDefinition(
      id: 'ember_summit', bossId: 'ember_dragon',
      name: 'Ember Dragon',
      worldName: 'Ember Summit', worldNameKey: 'world_ember_name',
      bossNameKey: 'boss_ember_name',
      worldRequirementKey: 'world_ember_requirement',
      bossRequirementKey: 'boss_ember_requirement', bossRewardKey: 'boss_ember_reward',
      x: 0.67, y: 0.24, secretId: 'ashen_vault', secretAt: 300,
      unlockBossId: 'crystal_golem', unlockCorrectGuesses: 100,
      unlockUpgradeCount: 15, unlockPrestigeCount: 1, unlockUltraCount: 0,
      fightCorrectGuesses: 150, fightUpgradeCount: 25,
      fightPrestigeCount: 1, fightUltraCount: 0,
      hits: 7, moneyReward: 500000, nebulaReward: 75,
    ),
    WorldBossDefinition(
      id: 'nebula_rift', bossId: 'nebula_titan',
      name: 'Nebula Titan',
      worldName: 'Nebula Rift', worldNameKey: 'world_nebula_name',
      bossNameKey: 'boss_nebula_name',
      worldRequirementKey: 'world_nebula_requirement',
      bossRequirementKey: 'boss_nebula_requirement', bossRewardKey: 'boss_nebula_reward',
      x: 0.82, y: 0.59, secretId: 'lost_observatory', secretAt: 600,
      unlockBossId: 'ember_dragon', unlockCorrectGuesses: 250,
      unlockUpgradeCount: 40, unlockPrestigeCount: 3, unlockUltraCount: 1,
      fightCorrectGuesses: 500, fightUpgradeCount: 75,
      fightPrestigeCount: 5, fightUltraCount: 1,
      hits: 10, moneyReward: 5000000, nebulaReward: 250,
    ),
  ];

  static int ownedUpgradeLevels(ProgressionState state) =>
      state.upgrades.values.fold(0, (sum, level) => sum + level);

  static bool canUnlock(ProgressionState state, WorldBossDefinition boss) {
    if (isUnlocked(state, boss)) return false;
    final requiredBossId = boss.unlockBossId;
    if (requiredBossId == null) return true;
    return state.defeatedBosses.contains(requiredBossId) &&
        state.correctGuesses >= boss.unlockCorrectGuesses &&
        ownedUpgradeLevels(state) >= boss.unlockUpgradeCount &&
        state.prestigeResets >= boss.unlockPrestigeCount &&
        state.ultraResets >= boss.unlockUltraCount;
  }

  static bool isUnlocked(ProgressionState state, WorldBossDefinition boss) =>
      state.legacySystems.unlockedWorldIds.contains(boss.id);

  static bool canFight(ProgressionState state, WorldBossDefinition boss) =>
      isUnlocked(state, boss) &&
      state.correctGuesses >= boss.fightCorrectGuesses &&
      ownedUpgradeLevels(state) >= boss.fightUpgradeCount &&
      state.prestigeResets >= boss.fightPrestigeCount &&
      state.ultraResets >= boss.fightUltraCount;

  static int damage(ProgressionState state, WorldBossDefinition boss) {
    final riftTier = state.legacySystems.endlessRiftActive
        ? state.legacySystems.endlessRiftTier.clamp(1, 1000000).toInt()
        : 1;
    final hp = boss.hits + (state.legacySystems.endlessRiftActive ? (riftTier - 1) * 2 : 0);
    return (state.bossDamage[boss.bossId] ?? state.bossDamage[boss.id] ?? 0)
        .clamp(0, hp);
  }

  static bool isDefeated(ProgressionState state, WorldBossDefinition boss) =>
      state.defeatedBosses.contains(boss.bossId) ||
      state.defeatedBosses.contains(boss.id);
}
