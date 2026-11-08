import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/builtin_trait_catalog.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  const engine = LegacySystemsEngine();
  BigNumber n(int value) => BigNumber.fromInt(value);

  group('mutators', () {
    test('stacks the canonical reward multipliers and range rule', () {
      final systems = LegacySystemsState.initial.copyWith(
        activeMutators: const {
          'mut_hardcore', 'mut_speed', 'mut_blind', 'mut_tax',
        },
      );
      expect(engine.mutatorRewardMultiplier(systems).compareTo(n(300)), 0);
      expect(engine.rangeMultiplier(systems), 2);
    });

    test('rejects unknown mutators without changing state', () {
      final result = engine.setMutator(
        ProgressionState.initial, LegacySystemsState.initial, 'mut_fake', true,
      );
      expect(result.accepted, isFalse);
      expect(result.systems.activeMutators, isEmpty);
    });
  });

  group('talents', () {
    test('requires parent talent, spends prestige and rejects duplicates', () {
      final progression = ProgressionState.initial.copyWith(prestige: n(10000));
      final systems = LegacySystemsState.initial;
      final blocked = engine.buyTalent(progression, systems, const TalentDefinition(id: 'talent_speed_2', cost: 500, requiredParentId: 'talent_speed_1'));
      expect(blocked.accepted, isFalse);
      final first = engine.buyTalent(progression, systems, const TalentDefinition(id: 'talent_speed_1', cost: 100));
      expect(first.accepted, isTrue);
      expect(first.progression.prestige.compareTo(n(9900)), 0);
      final duplicate = engine.buyTalent(
        first.progression, first.systems, const TalentDefinition(id: 'talent_speed_1', cost: 100),
      );
      expect(duplicate.accepted, isFalse);
      final second = engine.buyTalent(
        first.progression, first.systems, const TalentDefinition(id: 'talent_speed_2', cost: 500, requiredParentId: 'talent_speed_1'),
      );
      expect(second.accepted, isTrue);
      expect(second.progression.prestige.compareTo(n(9400)), 0);
    });

    test('rejects purchases when prestige is insufficient', () {
      final result = engine.buyTalent(
        ProgressionState.initial, LegacySystemsState.initial, const TalentDefinition(id: 'talent_speed_1', cost: 100),
      );
      expect(result.accepted, isFalse);
      expect(result.progression.prestige.compareTo(n(0)), 0);
    });
  });

  group('home base and relics', () {
    test('uses the escalating home base cost and enforces the level cap', () {
      final start = ProgressionState.initial.copyWith(money: n(150000));
      final first = engine.upgradeHomeBase(start, LegacySystemsState.initial);
      expect(first.accepted, isTrue);
      expect(first.systems.homeBaseLevel, 1);
      expect(first.progression.money.compareTo(n(100000)), 0);
      final second = engine.upgradeHomeBase(first.progression, first.systems);
      expect(second.accepted, isTrue);
      expect(second.systems.homeBaseLevel, 2);
      expect(second.progression.money.compareTo(n(0)), 0);
      final capped = engine.upgradeHomeBase(
        second.progression,
        second.systems.copyWith(homeBaseLevel: 20),
      );
      expect(capped.accepted, isFalse);
    });

    test('only owned relics can be equipped and four is the cap', () {
      final empty = engine.equipRelic(
        ProgressionState.initial, LegacySystemsState.initial, 'verdant_guardian',
      );
      expect(empty.accepted, isFalse);
      final owned = LegacySystemsState.initial.copyWith(
        relicInventory: const {
          'verdant_guardian', 'crystal_golem', 'ember_dragon', 'nebula_titan',
        },
      );
      var state = owned;
      for (final id in owned.relicInventory) {
        final result = engine.equipRelic(ProgressionState.initial, state, id);
        expect(result.accepted, isTrue);
        state = result.systems;
      }
      expect(state.equippedRelics, hasLength(4));
      final fifth = engine.equipRelic(
        ProgressionState.initial,
        state.copyWith(relicInventory: {...state.relicInventory, 'not_a_relic'}),
        'not_a_relic',
      );
      expect(fifth.accepted, isFalse);
    });
  });

  group('world mastery and secret progression', () {
    test('mastery recognizes defeated boss IDs and applies the first upgrade', () {
      final progression = ProgressionState.initial.copyWith(
        defeatedBosses: const {'verdant_guardian'},
        nebula: n(100),
      );
      final result = engine.upgradeWorldMastery(
        progression: progression,
        systems: LegacySystemsState.initial,
        worldId: 'verdant_grove',
      );

      expect(result.accepted, isTrue);
      expect(result.systems.worldMasteryLevels['verdant_grove'], 2);
      expect(result.progression.nebula.compareTo(n(80)), 0);
    });

    test('mastery requires the world to be unlocked and its boss defeated', () {
      final defeatedButLocked = ProgressionState.initial.copyWith(
        defeatedBosses: const {'crystal_golem'},
        nebula: n(100),
      );
      final lockedResult = engine.upgradeWorldMastery(
        progression: defeatedButLocked,
        systems: LegacySystemsState.initial,
        worldId: 'crystal_caverns',
      );
      expect(lockedResult.accepted, isFalse);

      final unlocked = defeatedButLocked.copyWith(
        legacySystems: LegacySystemsState.initial.copyWith(
          unlockedWorldIds: const {'verdant_grove', 'crystal_caverns'},
        ),
      );
      final accepted = engine.upgradeWorldMastery(
        progression: unlocked,
        systems: unlocked.legacySystems,
        worldId: 'crystal_caverns',
      );
      expect(accepted.accepted, isTrue);
      expect(accepted.systems.worldMasteryLevels['crystal_caverns'], 2);
    });

    test('mastery level five and ten grant the exact Nebula milestones', () {
      final progression = ProgressionState.initial.copyWith(
        defeatedBosses: const {'verdant_guardian'},
        nebula: n(150),
      );
      final systems = LegacySystemsState.initial.copyWith(
        worldMasteryLevels: const {'verdant_grove': 4},
      );
      final levelFive = engine.upgradeWorldMastery(
        progression: progression,
        systems: systems,
        worldId: 'verdant_grove',
      );

      expect(levelFive.accepted, isTrue);
      expect(levelFive.systems.worldMasteryLevels['verdant_grove'], 5);
      expect(levelFive.progression.nebula.compareTo(n(125)), 0);
      expect(levelFive.progression.nebulaEarned.compareTo(n(25)), 0);
      expect(
        levelFive.systems.codexEntries,
        contains('mastery:verdant_grove:5'),
      );

      final levelNineSystems = levelFive.systems.copyWith(
        worldMasteryLevels: const {'verdant_grove': 9},
      );
      final levelTen = engine.upgradeWorldMastery(
        progression: levelFive.progression.copyWith(nebula: n(100)),
        systems: levelNineSystems,
        worldId: 'verdant_grove',
      );

      expect(levelTen.accepted, isTrue);
      expect(levelTen.systems.worldMasteryLevels['verdant_grove'], 10);
      expect(levelTen.progression.nebula.compareTo(n(100)), 0);
      expect(levelTen.progression.nebulaEarned.compareTo(n(125)), 0);
      expect(
        levelTen.systems.codexEntries,
        contains('mastery:verdant_grove:10'),
      );
    });

    test('mastery applies stacked discounts with a forty percent cap', () {
      final progression = ProgressionState.initial.copyWith(
        defeatedBosses: const {'verdant_guardian'},
        nebula: n(60),
      );
      final systems = LegacySystemsState.initial.copyWith(
        worldMasteryLevels: const {'verdant_grove': 9},
        discoveredSecrets: const {'whispering_hollow'},
        homeBaseLevel: 20,
        equippedRelics: const {
          'verdant_guardian',
          'crystal_golem',
          'ember_dragon',
          'nebula_titan',
        },
      );
      final result = engine.upgradeWorldMastery(
        progression: progression,
        systems: systems,
        worldId: 'verdant_grove',
      );

      expect(result.accepted, isTrue);
      // Base cost 100, capped discount 40%, exact final cost 60.
      expect(result.progression.nebula.compareTo(n(100)), 0);
    });

    test('secret discovery requires its world unlock and guess threshold', () {
      final progression = ProgressionState.initial.copyWith(
        correctGuesses: 150,
      );
      final systems = LegacySystemsState.initial.copyWith(
        unlockedWorldIds: const {'verdant_grove', 'crystal_caverns'},
      );
      final result = engine.discoverSecret(
        progression: progression,
        systems: systems,
        secretId: 'shard_archive',
      );

      expect(result.accepted, isTrue);
      expect(result.systems.discoveredSecrets, contains('shard_archive'));
      expect(result.progression.money.compareTo(n(50000)), 0);
      expect(result.progression.nebula.compareTo(n(15)), 0);
    });

    test('secret discovery rejects a locked world even after the threshold', () {
      final progression = ProgressionState.initial.copyWith(
        correctGuesses: 150,
        defeatedBosses: const {'verdant_guardian'},
      );
      final result = engine.discoverSecret(
        progression: progression,
        systems: LegacySystemsState.initial,
        secretId: 'shard_archive',
      );

      expect(result.accepted, isFalse);
      expect(result.progression.money.compareTo(n(0)), 0);
    });
  });

  group('lucky stake and rewards', () {
    test('settles a winning stake with the GTN1 streak multiplier', () {
      final result = engine.settleLuckyStake(
        progression: ProgressionState.initial.copyWith(money: n(100)),
        systems: LegacySystemsState.initial,
        stake: n(10),
        won: true,
        currentStreak: 5,
      );
      expect(result.accepted, isTrue);
      // GTN1 payout is stake * (2.0 + 0.1 * streak): 10 * 2.5.
      expect(result.progression.money.compareTo(n(115)), 0);
      expect(result.systems.stakesPlaced, 1);
      expect(result.systems.stakesWon, 1);
      expect(result.systems.stakesLost, 0);
    });

    test('rejects non-positive and unaffordable stakes atomically', () {
      final progression = ProgressionState.initial.copyWith(money: n(5));
      final zero = engine.settleLuckyStake(
        progression: progression, systems: LegacySystemsState.initial,
        stake: n(0), won: true, currentStreak: 0,
      );
      final unaffordable = engine.settleLuckyStake(
        progression: progression, systems: LegacySystemsState.initial,
        stake: n(10), won: false, currentStreak: 0,
      );
      expect(zero.accepted, isFalse);
      expect(unaffordable.accepted, isFalse);
      expect(unaffordable.progression.money.compareTo(n(5)), 0);
      expect(unaffordable.systems.stakesPlaced, 0);
    });
  });

  group('Endless Rift', () {
    test('starts a fresh run and advances tiers with scaled boss rewards', () {
      final defeated = ProgressionState.initial.copyWith(
        defeatedBosses: const {
          'verdant_grove', 'crystal_caverns', 'ember_summit', 'nebula_rift',
        },
        bossDamage: const {
          'verdant_grove': 3, 'crystal_caverns': 5, 'ember_summit': 7, 'nebula_rift': 10,
        },
      );
      final started = engine.setEndlessRift(
        progression: defeated,
        systems: LegacySystemsState.initial,
        active: true,
      );
      expect(started.accepted, isTrue);
      expect(started.systems.endlessRiftTier, 1);
      expect(started.progression.bossDamage['verdant_grove'], 0);
      var progression = started.progression;
      var systems = started.systems;
      for (var hit = 0; hit < 3; hit++) {
        final result = engine.attackEndlessRiftBoss(progression, systems);
        expect(result.accepted, isTrue);
        progression = result.progression;
        systems = result.systems;
      }
      expect(systems.activeWorldId, 'crystal_caverns');
      expect(systems.endlessRiftTier, 2);
      expect(systems.endlessRiftBestTier, 1);
      expect(progression.money.compareTo(n(25000)), 0);
      expect(progression.nebula.compareTo(n(10)), 0);
      expect(progression.bossDamage['crystal_caverns'], 0);
    });

    test('misses regress Rift boss damage according to its current phase', () {
      final defeated = ProgressionState.initial.copyWith(
        defeatedBosses: const {
          'verdant_grove', 'crystal_caverns', 'ember_summit', 'nebula_rift',
        },
      );
      final started = engine.setEndlessRift(
        progression: defeated,
        systems: LegacySystemsState.initial,
        active: true,
      );
      var progression = started.progression;
      var systems = started.systems;
      for (var hit = 0; hit < 2; hit++) {
        final result = engine.attackEndlessRiftBoss(progression, systems);
        progression = result.progression;
        systems = result.systems;
      }
      final firstMiss = engine.recordEndlessRiftMiss(progression, systems);
      expect(firstMiss.progression.bossDamage['verdant_grove'], 2);
      final secondMiss = engine.recordEndlessRiftMiss(firstMiss.progression, firstMiss.systems);
      expect(secondMiss.progression.bossDamage['verdant_grove'], 1);
    });
  });
  group('daily rewards and challenge claims', () {
    test('prevents duplicate daily rewards and advances a consecutive streak', () {
      final first = engine.claimDailyReward(
        progression: ProgressionState.initial,
        systems: LegacySystemsState.initial,
        today: '2026-11-07',
      );
      expect(first.accepted, isTrue);
      expect(first.progression.nebula.compareTo(n(5)), 0);
      final duplicate = engine.claimDailyReward(
        progression: first.progression,
        systems: first.systems,
        today: '2026-11-07',
      );
      expect(duplicate.accepted, isFalse);
      final next = engine.claimDailyReward(
        progression: first.progression,
        systems: first.systems,
        today: '2026-11-08',
      );
      expect(next.accepted, isTrue);
      expect(next.systems.dailyRewardStreak, 2);
      expect(next.progression.nebula.compareTo(n(15)), 0);
    });

    test('requires eligibility and prevents duplicate challenge rewards', () {
      final blocked = engine.claimChallenge(
        progression: ProgressionState.initial,
        systems: LegacySystemsState.initial,
        challengeId: 'weekly_test',
        nebulaReward: 20,
        eligible: false,
      );
      expect(blocked.accepted, isFalse);
      final claimed = engine.claimChallenge(
        progression: ProgressionState.initial,
        systems: LegacySystemsState.initial,
        challengeId: 'weekly_test',
        nebulaReward: 20,
        eligible: true,
      );
      expect(claimed.accepted, isTrue);
      expect(claimed.progression.nebula.compareTo(n(20)), 0);
      final duplicate = engine.claimChallenge(
        progression: claimed.progression,
        systems: claimed.systems,
        challengeId: 'weekly_test',
        nebulaReward: 20,
        eligible: true,
      );
      expect(duplicate.accepted, isFalse);
      expect(duplicate.progression.nebula.compareTo(n(20)), 0);
    });
  });

  group('catalog and save integrity', () {
    test('hidden trait discovery follows GTN1 progression gates, not player level', () {
      final discovered = engine.discoverEligibleTraits(
        progression: ProgressionState.initial.copyWith(correctGuesses: 100),
        systems: LegacySystemsState.initial,
        activeSeasonId: null,
      );
      expect(discovered.discoveredTraits, contains('hidden_night_owl'));
      expect(discovered.discoveredTraits, isNot(contains('hidden_century_club')));

      final activation = engine.evaluateTraits(
        progression: ProgressionState.initial.copyWith(correctGuesses: 100),
        systems: discovered,
        playerLevel: 0,
        activeSeasonId: null,
      );
      expect(activation.activeTraitIds, isNot(contains('hidden_night_owl')));
    });

    test('hidden trait dependency chains unlock in one discovery pass', () {
      final discovered = engine.discoverEligibleTraits(
        progression: ProgressionState.initial.copyWith(correctGuesses: 500),
        systems: LegacySystemsState.initial,
        activeSeasonId: null,
      );

      expect(
        discovered.discoveredTraits,
        containsAll({
          'hidden_night_owl',
          'hidden_century_club',
          'hidden_precision_mind',
        }),
      );
    });

    test('contains the full GTN1 built-in trait catalog', () {
      expect(builtInTraitCatalog, hasLength(320));
      final ids = builtInTraitCatalog.map((trait) => trait['id']).toSet();
      expect(ids, hasLength(320));
    });

    test('round-trips every persisted legacy subsystem', () {
      final systems = LegacySystemsState.initial.copyWith(
        discoveredTraits: const {'hidden_night_owl'},
        selectedTraitArms: const {'combo_momentum': 'steady'},
        activeMutators: const {'mut_hardcore'},
        talents: const {'talent_speed_1'},
        relicInventory: const {'verdant_guardian'},
        equippedRelics: const {'verdant_guardian'},
        homeBaseLevel: 4,
        lastDailyRewardDate: '2026-11-07',
        dailyRewardStreak: 3,
        lootChests: const {'common': 2, 'rare': 1, 'epic': 0},
        completedChallenges: const {'weekly_2026_45'},
        stakesPlaced: 4,
        stakesWon: 2,
        stakesLost: 2,
        musicLibrary: const ['track_a', 'track_b'],
        musicQueue: const ['track_b'],
        musicPlaylists: const {'favorites': ['track_a']},
        currentTrackId: 'track_b',
        worldBossVictories: 12,
        unlockedWorldIds: const {'verdant_grove', 'crystal_caverns'},
      );
      expect(LegacySystemsState.fromJson(systems.toJson()).toJson(), systems.toJson());
    });

    test('defaults world boss victories when loading older saves', () {
      final legacyJson = Map<String, dynamic>.of(LegacySystemsState.initial.toJson())
        ..remove('worldBossVictories')
        ..remove('unlockedWorldIds')
        ..remove('worldUnlockMigrationPending');
      final restored = LegacySystemsState.fromJson(legacyJson);
      expect(restored.worldBossVictories, 0);
      expect(restored.unlockedWorldIds, const {'verdant_grove'});
      expect(restored.worldUnlockMigrationPending, isTrue);
    });

    test('round-trips bot sequence, last feedback and save timestamp', () {
      final systems = LegacySystemsState.initial.copyWith(
        autoClickerActive: true,
        autoClickerSpeed: 1.5,
        botTotalGuesses: 4,
        botCorrectGuesses: 1,
        botIncorrectGuesses: 3,
        botActionSequence: 9,
        lastBotGuess: 63,
        lastBotFeedback: 'TOO_HIGH',
        lastBotId: 'bot_byte',
        lastSaveTimestamp: 1794100000000,
        timeTravelPenaltyUntil: 1794186400000,
      );
      final restored = LegacySystemsState.fromJson(systems.toJson());
      expect(restored.botActionSequence, 9);
      expect(restored.lastBotGuess, 63);
      expect(restored.lastBotFeedback, 'TOO_HIGH');
      expect(restored.lastBotId, 'bot_byte');
      expect(restored.lastSaveTimestamp, 1794100000000);
      expect(restored.timeTravelPenaltyUntil, 1794186400000);
      expect(restored.autoClickerActive, isTrue);
      expect(restored.autoClickerSpeed, 1.5);
    });

    test('rejects invalid persisted bot feedback and identity', () {
      expect(
        () => LegacySystemsState.fromJson(<String, dynamic>{
          ...LegacySystemsState.initial.toJson(),
          'lastBotFeedback': 'SECRET_READ',
        }),
        throwsFormatException,
      );
      expect(
        () => LegacySystemsState.fromJson(<String, dynamic>{
          ...LegacySystemsState.initial.toJson(),
          'lastBotId': 'unknown_bot',
        }),
        throwsFormatException,
      );
      expect(
        () => LegacySystemsState.fromJson(<String, dynamic>{
          ...LegacySystemsState.initial.toJson(),
          'lastBotGuess': 501,
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid equipped relic and music references', () {
      expect(
        () => LegacySystemsState.fromJson(<String, dynamic>{
          ...LegacySystemsState.initial.toJson(),
          'equippedRelics': <String>['verdant_guardian'],
          'relicInventory': <String>[],
        }),
        throwsFormatException,
      );
      expect(
        () => LegacySystemsState.fromJson(<String, dynamic>{
          ...LegacySystemsState.initial.toJson(),
          'musicLibrary': <String>['track_a'],
          'musicQueue': <String>['missing_track'],
        }),
        throwsFormatException,
      );
    });
  });
}
