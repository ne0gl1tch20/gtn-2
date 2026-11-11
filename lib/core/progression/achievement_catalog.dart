import '../numbers/big_number.dart';
import 'progression_state.dart';

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardNebula,
    required this.tier,
  });

  final String id;
  final String name;
  final String description;
  final int rewardNebula;
  final String tier;
}

/// Exact milestone catalog and unlock rules from pinned GTN1
/// app/src/main/assets/game/achievements.json and GameEngine.evaluateAchievements.
class AchievementCatalog {
  AchievementCatalog._();

  static const all = <AchievementDefinition>[
    AchievementDefinition(id: 'correct_10', name: 'Novice Guesser', description: 'Successfully guess the number 10 times.', rewardNebula: 10, tier: 'bronze'),
    AchievementDefinition(id: 'correct_50', name: 'Skilled Guesser', description: 'Successfully guess the number 50 times.', rewardNebula: 20, tier: 'silver'),
    AchievementDefinition(id: 'correct_100', name: 'Expert Guesser', description: 'Successfully guess the number 100 times.', rewardNebula: 40, tier: 'gold'),
    AchievementDefinition(id: 'correct_500', name: 'Master Guesser', description: 'Successfully guess the number 500 times.', rewardNebula: 100, tier: 'diamond'),
    AchievementDefinition(id: 'streak_5', name: 'Streak Master', description: 'Achieve a winning guess streak of 5.', rewardNebula: 25, tier: 'bronze'),
    AchievementDefinition(id: 'streak_10', name: 'Streak Champion', description: 'Achieve a winning guess streak of 10.', rewardNebula: 50, tier: 'silver'),
    AchievementDefinition(id: 'streak_25', name: 'Streak Legend', description: 'Achieve a winning guess streak of 25.', rewardNebula: 100, tier: 'gold'),
    AchievementDefinition(id: 'streak_50', name: 'Unbreakable', description: 'Achieve a winning guess streak of 50.', rewardNebula: 250, tier: 'diamond'),
    AchievementDefinition(id: 'millionaire', name: 'Number Millionaire', description: 'Accumulate 1,000,000 money.', rewardNebula: 50, tier: 'bronze'),
    AchievementDefinition(id: 'ten_millionaire', name: 'Ten Million Club', description: 'Accumulate 10,000,000 money.', rewardNebula: 100, tier: 'silver'),
    AchievementDefinition(id: 'hundred_millionaire', name: 'Hundred Million Club', description: 'Accumulate 100,000,000 money.', rewardNebula: 200, tier: 'gold'),
    AchievementDefinition(id: 'billionaire', name: 'Number Billionaire', description: 'Accumulate 1,000,000,000 money.', rewardNebula: 500, tier: 'diamond'),
    AchievementDefinition(id: 'prestige_1', name: 'First Prestige', description: 'Perform your first Prestige reset.', rewardNebula: 25, tier: 'bronze'),
    AchievementDefinition(id: 'prestige_5', name: 'Prestige Veteran', description: 'Perform 5 Prestige resets.', rewardNebula: 75, tier: 'silver'),
    AchievementDefinition(id: 'prestige_10', name: 'Prestige Master', description: 'Perform 10 Prestige resets.', rewardNebula: 150, tier: 'gold'),
    AchievementDefinition(id: 'prestige_25', name: 'Prestige Eternal', description: 'Perform 25 Prestige resets.', rewardNebula: 300, tier: 'diamond'),
    AchievementDefinition(id: 'ultra_1', name: 'First Ultra', description: 'Perform your first Ultra reset.', rewardNebula: 100, tier: 'bronze'),
    AchievementDefinition(id: 'ultra_3', name: 'Ultra Voyager', description: 'Perform 3 Ultra resets.', rewardNebula: 250, tier: 'silver'),
    AchievementDefinition(id: 'ultra_10', name: 'Ultra Master', description: 'Perform 10 Ultra resets.', rewardNebula: 500, tier: 'gold'),
    AchievementDefinition(id: 'ultra_25', name: 'Ultra Eternal', description: 'Perform 25 Ultra resets.', rewardNebula: 1000, tier: 'diamond'),
    AchievementDefinition(id: 'playtime_1h', name: 'One Hour In', description: 'Play for 1 hour.', rewardNebula: 25, tier: 'bronze'),
    AchievementDefinition(id: 'playtime_10h', name: 'Dedicated Player', description: 'Play for 10 hours.', rewardNebula: 100, tier: 'silver'),
    AchievementDefinition(id: 'playtime_50h', name: 'No Sleep Guesser', description: 'Play for 50 hours.', rewardNebula: 300, tier: 'gold'),
    AchievementDefinition(id: 'frenzy_5', name: 'Frenzy Ignition', description: 'Reach Frenzy tier 1.', rewardNebula: 30, tier: 'bronze'),
    AchievementDefinition(id: 'frenzy_10', name: 'Frenzy Runner', description: 'Reach a 10 streak.', rewardNebula: 75, tier: 'silver'),
    AchievementDefinition(id: 'frenzy_25', name: 'Frenzy Master', description: 'Reach a 25 streak.', rewardNebula: 150, tier: 'gold'),
    AchievementDefinition(id: 'frenzy_50', name: 'Frenzy Eternal', description: 'Reach a 50 streak.', rewardNebula: 350, tier: 'diamond'),
  ];

  static ProgressionState evaluate(ProgressionState state) {
    final zero = BigNumber.fromInt(0);
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
      'playtime_1h': state.playtimeSeconds >= 3600,
      'playtime_10h': state.playtimeSeconds >= 36000,
      'playtime_50h': state.playtimeSeconds >= 180000,
      'frenzy_5': state.bestStreak >= 5,
      'frenzy_10': state.bestStreak >= 10,
      'frenzy_25': state.bestStreak >= 25,
      'frenzy_50': state.bestStreak >= 50,
    };
    final newlyUnlocked = all
        .where((item) => milestones[item.id] == true && !state.achievements.contains(item.id))
        .toList(growable: false);
    if (newlyUnlocked.isEmpty) return state;
    final baseReward = newlyUnlocked.fold<int>(0, (sum, item) => sum + item.rewardNebula);
    final upgradeLevel = (state.ultraUpgrades['ultra_nebula_boost'] ?? 0).clamp(0, 15);
    final shopMultiplier = (state.nebulaItems['nebula_boost'] ?? 0) > 0 ? 2 : 1;
    final reward = BigNumber.fromInt(baseReward * (1 + upgradeLevel) * shopMultiplier);
    return state.copyWith(
      achievements: Set.unmodifiable({...state.achievements, ...newlyUnlocked.map((item) => item.id)}),
      nebula: state.nebula + reward,
      nebulaEarned: state.nebulaEarned + reward,
    );
  }

  static int progress(ProgressionState state, String id) => switch (id) {
    'correct_10' || 'correct_50' || 'correct_100' || 'correct_500' => state.correctGuesses,
    'streak_5' || 'streak_10' || 'streak_25' || 'streak_50' ||
    'frenzy_5' || 'frenzy_10' || 'frenzy_25' || 'frenzy_50' => state.bestStreak,
    'prestige_1' || 'prestige_5' || 'prestige_10' || 'prestige_25' => state.prestigeResets,
    'ultra_1' || 'ultra_3' || 'ultra_10' || 'ultra_25' => state.ultraResets,
    'playtime_1h' || 'playtime_10h' || 'playtime_50h' => state.playtimeSeconds,
    _ => 0,
  };

  static int target(String id) => switch (id) {
    'correct_10' => 10, 'correct_50' => 50, 'correct_100' => 100, 'correct_500' => 500,
    'streak_5' || 'frenzy_5' => 5, 'streak_10' || 'frenzy_10' => 10,
    'streak_25' || 'frenzy_25' => 25, 'streak_50' || 'frenzy_50' => 50,
    'prestige_1' => 1, 'prestige_5' => 5, 'prestige_10' => 10, 'prestige_25' => 25,
    'ultra_1' => 1, 'ultra_3' => 3, 'ultra_10' => 10, 'ultra_25' => 25,
    'playtime_1h' => 3600, 'playtime_10h' => 36000, 'playtime_50h' => 180000,
    _ => 0,
  };

  static String progressLabel(ProgressionState state, AchievementDefinition item) {
    if (state.achievements.contains(item.id)) return 'Unlocked';
    final goal = target(item.id);
    if (goal > 0) return '${progress(state, item.id).clamp(0, goal)} / $goal';
    final amount = switch (item.id) {
      'millionaire' => 1000000,
      'ten_millionaire' => 10000000,
      'hundred_millionaire' => 100000000,
      'billionaire' => 1000000000,
      _ => 0,
    };
    return amount == 0 ? 'Locked' : '${state.money.toString()} / $amount';
  }
}
