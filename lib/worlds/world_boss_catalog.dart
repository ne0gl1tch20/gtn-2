import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';

class WorldBossDefinition {
  const WorldBossDefinition({
    required this.id,
    required this.name,
    required this.worldName,
    required this.description,
    required this.correctRequirement,
    required this.upgradeRequirement,
    required this.prestigeRequirement,
    required this.ultraRequirement,
    required this.hits,
    required this.moneyReward,
    required this.nebulaReward,
    this.previousBossId,
  });

  final String id;
  final String name;
  final String worldName;
  final String description;
  final int correctRequirement;
  final int upgradeRequirement;
  final int prestigeRequirement;
  final int ultraRequirement;
  final int hits;
  final int moneyReward;
  final int nebulaReward;
  final String? previousBossId;
}

class WorldBossCatalog {
  WorldBossCatalog._();

  static const worlds = <WorldBossDefinition>[
    WorldBossDefinition(
      id: 'verdant_grove',
      name: 'Verdant Guardian',
      worldName: 'Verdant Grove',
      description: 'The first guardian protects the overgrown path.',
      correctRequirement: 10,
      upgradeRequirement: 3,
      prestigeRequirement: 0,
      ultraRequirement: 0,
      hits: 3,
      moneyReward: 25000,
      nebulaReward: 10,
    ),
    WorldBossDefinition(
      id: 'crystal_caverns',
      name: 'Crystal Sentinel',
      worldName: 'Crystal Caverns',
      description: 'A crystal beast guards the cavern entrance.',
      correctRequirement: 25,
      upgradeRequirement: 5,
      prestigeRequirement: 0,
      ultraRequirement: 0,
      previousBossId: 'verdant_grove',
      hits: 5,
      moneyReward: 100000,
      nebulaReward: 25,
    ),
    WorldBossDefinition(
      id: 'ember_summit',
      name: 'Ember Warden',
      worldName: 'Ember Summit',
      description: 'A blazing guardian waits above the clouds.',
      correctRequirement: 100,
      upgradeRequirement: 15,
      prestigeRequirement: 1,
      ultraRequirement: 0,
      previousBossId: 'crystal_caverns',
      hits: 7,
      moneyReward: 500000,
      nebulaReward: 75,
    ),
    WorldBossDefinition(
      id: 'nebula_rift',
      name: 'Rift Devourer',
      worldName: 'Nebula Rift',
      description: 'The final guardian watches over the rift.',
      correctRequirement: 250,
      upgradeRequirement: 40,
      prestigeRequirement: 3,
      ultraRequirement: 1,
      previousBossId: 'ember_summit',
      hits: 10,
      moneyReward: 5000000,
      nebulaReward: 250,
    ),
  ];

  static int ownedUpgradeLevels(ProgressionState state) =>
      state.upgrades.values.fold(0, (sum, level) => sum + level);

  static bool isUnlocked(ProgressionState state, WorldBossDefinition boss) {
    if (boss.previousBossId != null &&
        !state.defeatedBosses.contains(boss.previousBossId)) {
      return false;
    }
    return state.correctGuesses >= boss.correctRequirement &&
        ownedUpgradeLevels(state) >= boss.upgradeRequirement &&
        state.prestigeResets >= boss.prestigeRequirement &&
        state.ultraResets >= boss.ultraRequirement;
  }

  static int damage(ProgressionState state, WorldBossDefinition boss) =>
      (state.bossDamage[boss.id] ?? 0).clamp(0, boss.hits);

  static bool isDefeated(ProgressionState state, WorldBossDefinition boss) =>
      state.defeatedBosses.contains(boss.id);
}
