import '../numbers/big_number.dart';
import '../progression/progression_state.dart';
import 'builtin_trait_catalog.dart';
import 'legacy_systems_state.dart';

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
  static final _mutators = <String>{'mut_hardcore', 'mut_speed', 'mut_blind', 'mut_tax'};
  static const _bossRelics = <String>{
    'verdant_guardian', 'crystal_golem', 'ember_dragon', 'nebula_titan',
  };

  static const talents = <String, ({int cost, String? parent})>{
    'talent_speed_1': (cost: 100, parent: null),
    'talent_crit_1': (cost: 250, parent: null),
    'talent_speed_2': (cost: 500, parent: 'talent_speed_1'),
    'talent_crit_2': (cost: 1000, parent: 'talent_crit_1'),
    'talent_reward_1': (cost: 2500, parent: 'talent_crit_2'),
    'talent_master_1': (cost: 10000, parent: 'talent_reward_1'),
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
    if (!_mutators.contains(id)) return _reject(progression, systems, 'Unknown mutator.');
    final next = Set<String>.of(systems.activeMutators);
    if (active) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return _accept(progression, systems.copyWith(activeMutators: Set.unmodifiable(next)));
  }

  /// Matches shared MutatorRules.kt. Hardcore doubles the search range.
  BigNumber mutatorRewardMultiplier(LegacySystemsState systems) {
    var multiplier = BigNumber.fromInt(1);
    for (final entry in const <String, int>{
      'mut_hardcore': 2, 'mut_speed': 3, 'mut_blind': 5, 'mut_tax': 10,
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
    String talentId,
  ) {
    final definition = talents[talentId];
    if (definition == null) return _reject(progression, systems, 'Unknown talent.');
    if (systems.talents.contains(talentId)) {
      return _reject(progression, systems, 'Talent already purchased.');
    }
    final parent = definition.parent;
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
    if (systems.homeBaseLevel >= 20) return _reject(progression, systems, 'Home Base is fully restored.');
    final cost = BigNumber.fromInt(50000 * (systems.homeBaseLevel + 1));
    if (progression.money.compareTo(cost) < 0) return _reject(progression, systems, 'Not enough Money.');
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
    if (!_bossRelics.contains(relicId) || !systems.relicInventory.contains(relicId)) {
      return _reject(progression, systems, 'Relic is not owned.');
    }
    final equipped = Set<String>.of(systems.equippedRelics);
    if (equipped.contains(relicId)) {
      equipped.remove(relicId);
    } else {
      if (equipped.length >= 4) return _reject(progression, systems, 'Only four relics can be equipped.');
      equipped.add(relicId);
    }
    return _accept(progression, systems.copyWith(equippedRelics: Set.unmodifiable(equipped)));
  }

  LegacySystemsState unlockBossRelic(LegacySystemsState systems, String bossId) {
    if (!_bossRelics.contains(bossId)) return systems;
    return systems.copyWith(relicInventory: Set.unmodifiable({...systems.relicInventory, bossId}));
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
    if (equipped.contains('verdant_guardian')) multiplier += BigNumber.parse('0.10');
    if (equipped.contains('crystal_golem') && criticalHit) {
      multiplier += BigNumber.parse('0.50');
    }
    if (equipped.contains('ember_dragon')) multiplier += BigNumber.parse('0.25');
    if (equipped.contains('nebula_titan')) multiplier += BigNumber.parse('0.25');
    if (criticalHit && systems.talents.contains('talent_crit_1')) {
      multiplier += BigNumber.fromInt(1);
    }
    if (criticalHit && systems.talents.contains('talent_crit_2')) {
      multiplier += BigNumber.parse('0.5');
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
      bonusMoney += earned * BigNumber.parse((eventBoost * 0.02).toStringAsFixed(2));
    }
    final mastery = (systems.worldMasteryLevels[systems.activeWorldId] ?? 0).clamp(0, 10);
    if (mastery > 0) {
      bonusMoney += earned * BigNumber.parse((mastery * 0.02).toStringAsFixed(2));
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
    bonusMoney += earned * BigNumber.parse(
      (systems.homeBaseLevel * 0.02).clamp(0, 0.40).toStringAsFixed(2),
    );
    const secretForWorld = <String, String>{
      'verdant_grove': 'whispering_hollow',
      'crystal_caverns': 'shard_archive',
      'ember_summit': 'ashen_vault',
      'nebula_rift': 'lost_observatory',
    };
    final activeSecret = secretForWorld[systems.activeWorldId];
    if (activeSecret != null && systems.discoveredSecrets.contains(activeSecret)) {
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

  LegacyActionResult settleLuckyStake({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required BigNumber stake,
    required bool won,
    required int currentStreak,
  }) {
    if (stake.compareTo(_zero) <= 0) return _reject(progression, systems, 'Stake must be positive.');
    if (progression.money.compareTo(stake) < 0) return _reject(progression, systems, 'Not enough Money.');
    final payout = won
        ? stake * BigNumber.fromParts(BigInt.from(20 + currentStreak), 1)
        : _zero;
    final money = progression.money - stake + payout;
    final updated = progression.copyWith(
      money: money,
      moneyEarned: progression.moneyEarned + payout,
    );
    return _accept(updated, systems.copyWith(
      stakesPlaced: systems.stakesPlaced + 1,
      stakesWon: systems.stakesWon + (won ? 1 : 0),
      stakesLost: systems.stakesLost + (won ? 0 : 1),
    ));
  }

  LegacyActionResult claimDailyReward({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String today,
    int traitNebulaBonus = 0,
    bool nebulaBoostOwned = false,
  }) {
    if (!_validDate(today)) return _reject(progression, systems, 'Invalid claim date.');
    if (systems.lastDailyRewardDate == today) {
      return _reject(progression, systems, 'Daily reward already claimed.');
    }
    final yesterday = DateTime.parse(today).subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final streak = systems.lastDailyRewardDate == yesterday
        ? (systems.dailyRewardStreak >= 7 ? 1 : systems.dailyRewardStreak + 1).clamp(1, 7)
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
    if (!_validDate(today)) return _reject(progression, systems, 'Invalid claim date.');
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
    if (requirements[questId] != true || current.claimedDailyQuests.contains(questId)) {
      return _reject(progression, current, 'Quest is not claimable.');
    }
    final multiplier = nebulaBoostOwned ? 2 : 1;
    var updated = progression;
    switch (questId) {
      case 'daily_guesses_10':
        final reward = BigNumber.fromInt(10000);
        updated = updated.copyWith(money: updated.money + reward, moneyEarned: updated.moneyEarned + reward);
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
    return _accept(updated, current.copyWith(
      claimedDailyQuests: Set.unmodifiable({...current.claimedDailyQuests, questId}),
    ));
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
    if (available == null || available <= 0) return _reject(progression, systems, 'No chest available.');
    final chests = Map<String, int>.of(systems.lootChests)..[tier] = available - 1;
    var updated = progression;
    if (rewardNebula) {
      updated = _addNebula(updated, nebula[tier]!);
    } else {
      final reward = BigNumber.fromInt(money[tier]!);
      updated = updated.copyWith(money: updated.money + reward, moneyEarned: updated.moneyEarned + reward);
    }
    return _accept(updated, systems.copyWith(
      lootChests: Map.unmodifiable(chests),
      lootChestsOpened: systems.lootChestsOpened + 1,
    ));
  }

  LegacyActionResult claimChallenge({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required String challengeId,
    required int nebulaReward,
    required bool eligible,
    bool nebulaBoostOwned = false,
  }) {
    if (challengeId.isEmpty || nebulaReward <= 0 || !eligible ||
        systems.completedChallenges.contains(challengeId)) {
      return _reject(progression, systems, 'Challenge is not claimable.');
    }
    final reward = nebulaReward * (nebulaBoostOwned ? 2 : 1);
    return _accept(
      _addNebula(progression, reward),
      systems.copyWith(completedChallenges: Set.unmodifiable({...systems.completedChallenges, challengeId})),
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
      dailyQuestCorrectGuesses: current.dailyQuestCorrectGuesses + (correct ? 1 : 0),
      dailyQuestBestStreak: currentStreak > current.dailyQuestBestStreak
          ? currentStreak : current.dailyQuestBestStreak,
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
    return current.copyWith(dailyQuestUpgradePurchases: current.dailyQuestUpgradePurchases + 1);
  }

  TraitEffectSummary evaluateTraits({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required int playerLevel,
    required String? activeSeasonId,
  }) {
    final definitions = builtInTraitCatalog.map((item) => _Trait.fromMap(item)).toList();
    final eligible = definitions.where((trait) {
      if (trait.category == 'SEASONAL' && trait.seasonId != activeSeasonId) {
        return false;
      }
      if (trait.visibility == 'HIDDEN' && !systems.discoveredTraits.contains(trait.id)) {
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
          .where((trait) => trait.dependencies.any((id) => !accepted.containsKey(id)))
          .map((trait) => trait.id).toList();
      for (final id in remove) {
        accepted.remove(id);
        changed = true;
      }
    }
    final active = accepted.values.toList();
    final activeIds = active.map((trait) => trait.id).toSet();
    final xpCount = active.where((trait) => trait.effect == 'XP_MULTIPLIER').length;
    final nebulaCount = active.where((trait) => trait.effect == 'NEBULA_BONUS').length;
    var correctGuessBonus = 0.0;
    if (activeIds.contains('combo_momentum')) {
      final burst = systems.selectedTraitArms['combo_momentum'] == 'burst';
      final perStreak = burst ? 0.03 : 0.02;
      final cap = burst ? 0.25 : 0.20;
      correctGuessBonus += (progression.currentStreak * perStreak).clamp(0.0, cap);
    }
    if (activeIds.contains('risk_reward')) {
      correctGuessBonus += systems.selectedTraitArms['risk_reward'] == 'high_risk' ? 0.40 : 0.25;
    }
    final hasInsurance = activeIds.contains('mistake_insurance');
    final highRisk = systems.selectedTraitArms['risk_reward'] == 'high_risk';
    return TraitEffectSummary(
      xpMultiplier: (1 + xpCount * 0.05).clamp(1.0, 2.0).toDouble(),
      nebulaBonusPerClaim: nebulaCount.clamp(0, 100).toInt(),
      streakProtection: activeIds.contains('streak_guard') || activeIds.contains('focus_streak'),
      correctGuessMultiplier: 1.0 + correctGuessBonus,
      missPenaltyRefundRate: hasInsurance
          ? (systems.selectedTraitArms['mistake_insurance'] == 'careful' ? 0.75 : 0.50)
          : 0.0,
      riskMissPenaltyRate: activeIds.contains('risk_reward') ? (highRisk ? 0.20 : 0.10) : 0.0,
      rangeHint: activeIds.contains('range_scout'),
      activeTraitIds: Set.unmodifiable(activeIds),
      discoveredHiddenTraitIds: Set.unmodifiable(
        definitions.where((trait) => trait.visibility == 'HIDDEN' && systems.discoveredTraits.contains(trait.id))
            .map((trait) => trait.id),
      ),
    );
  }

  LegacySystemsState discoverEligibleTraits({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required int playerLevel,
    required String? activeSeasonId,
  }) {
    final discovered = Set<String>.of(systems.discoveredTraits);
    for (final item in builtInTraitCatalog) {
      if (item['visibility'] != 'HIDDEN') {
        continue;
      }
      if (item['category'] == 'SEASONAL' && item['seasonId'] != activeSeasonId) {
        continue;
      }
      final dependencies = (item['dependencies']! as List<Object?>).cast<String>();
      if (progression.prestigeResets < (item['minPrestige']! as int) ||
          progression.correctGuesses < (item['minCorrect']! as int) ||
          progression.bestStreak < (item['minStreak']! as int) ||
          !dependencies.every(discovered.contains)) {
        continue;
      }
      discovered.add(item['id']! as String);
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
    if (allowed == null || !allowed.contains(armId)) return _reject(progression, systems, 'Unknown trait arm.');
    final active = evaluateTraits(
      progression: progression,
      systems: systems,
      playerLevel: playerLevel,
      activeSeasonId: activeSeasonId,
    );
    if (!active.activeTraitIds.contains(traitId)) return _reject(progression, systems, 'Trait is not active.');
    return _accept(progression, systems.copyWith(
      selectedTraitArms: Map.unmodifiable({...systems.selectedTraitArms, traitId: armId}),
    ));
  }

  static ProgressionState _addNebula(ProgressionState state, int amount) {
    final reward = BigNumber.fromInt(amount);
    return state.copyWith(nebula: state.nebula + reward, nebulaEarned: state.nebulaEarned + reward);
  }

  static bool _validDate(String value) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
      DateTime.tryParse(value) != null;

  static LegacyActionResult _accept(ProgressionState p, LegacySystemsState s) =>
      LegacyActionResult(progression: p, systems: s, accepted: true);

  static LegacyActionResult _reject(ProgressionState p, LegacySystemsState s, String message) =>
      LegacyActionResult(progression: p, systems: s, accepted: false, message: message);
}

class _Trait {
  const _Trait({
    required this.id, required this.category, required this.effect,
    required this.visibility, required this.seasonId, required this.minimumLevel,
    required this.minimumPrestige, required this.minimumCorrect,
    required this.minimumBestStreak, required this.dependencies, required this.conflicts,
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
    dependencies: Set<String>.from((map['dependencies']! as List).cast<String>()),
    conflicts: Set<String>.from((map['conflicts']! as List).cast<String>()),
  );
}
