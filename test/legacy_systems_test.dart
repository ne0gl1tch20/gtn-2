import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/builtin_trait_catalog.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  const engine = LegacySystemsEngine();

  group('GTN 1 trait catalog and activation', () {
    test('contains every stable built-in trait ID without duplicates', () {
      final ids = builtInTraitCatalog.map((item) => item['id']).toSet();
      expect(builtInTraitCatalog, hasLength(320));
      expect(ids, hasLength(320));
    });

    test('gameplay traits expose GTN1 combo, insurance and risk modifiers', () {
      final progression = ProgressionState.initial.copyWith(
        correctGuesses: 100,
        currentStreak: 5,
        bestStreak: 100,
      );
      final systems = LegacySystemsState.initial.copyWith(
        selectedTraitArms: const {
          'combo_momentum': 'burst',
          'mistake_insurance': 'careful',
          'risk_reward': 'high_risk',
        },
      );
      final effects = engine.evaluateTraits(
        progression: progression,
        systems: systems,
        playerLevel: 1,
        activeSeasonId: null,
      );
      expect(
        effects.activeTraitIds,
        containsAll({
          'combo_momentum',
          'mistake_insurance',
          'risk_reward',
          'streak_guard',
        }),
      );
      // Burst: 5 × 3% = 15%; high-risk: +40%.
      expect(effects.correctGuessMultiplier, 1.55);
      expect(effects.missPenaltyRefundRate, 0.75);
      expect(effects.riskMissPenaltyRate, 0.20);
      expect(effects.streakProtection, isTrue);
      expect(effects.rangeHint, isTrue);
    });

    test('activation resolves dependencies and reports bounded effects', () {
      final state = ProgressionState.initial.copyWith(
        correctGuesses: 25,
        prestigeResets: 1,
      );
      final systems = LegacySystemsState.initial.copyWith(
        discoveredTraits: const {'hidden_night_owl'},
      );
      final result = engine.evaluateTraits(
        progression: state,
        systems: systems,
        playerLevel: 10,
        activeSeasonId: null,
      );
      expect(result.activeTraitIds, contains('steady_start'));
      expect(result.xpMultiplier, inInclusiveRange(1.0, 2.0));
      expect(result.nebulaBonusPerClaim, inInclusiveRange(0, 100));
    });
  });

  group('authoritative legacy transactions', () {
    test(
      'talent purchases enforce canonical cost, prerequisites and duplicates',
      () {
        final initial = ProgressionState.initial.copyWith(
          prestige: BigNumber.fromInt(10000),
        );
        final blocked = engine.buyTalent(
          initial,
          LegacySystemsState.initial,
          const TalentDefinition(
            id: 'talent_speed_2',
            cost: 500,
            requiredParentId: 'talent_speed_1',
          ),
        );
        expect(blocked.accepted, isFalse);
        expect(blocked.progression.prestige, initial.prestige);

        final first = engine.buyTalent(
          initial,
          LegacySystemsState.initial,
          const TalentDefinition(id: 'talent_speed_1', cost: 100),
        );
        expect(first.accepted, isTrue);
        expect(first.progression.prestige, BigNumber.fromInt(9900));
        final second = engine.buyTalent(
          first.progression,
          first.systems,
          const TalentDefinition(id: 'talent_speed_1', cost: 100),
        );
        expect(second.accepted, isFalse);
        final child = engine.buyTalent(
          first.progression,
          first.systems,
          const TalentDefinition(
            id: 'talent_speed_2',
            cost: 500,
            requiredParentId: 'talent_speed_1',
          ),
        );
        expect(child.accepted, isTrue);
        expect(child.progression.prestige, BigNumber.fromInt(9400));
      },
    );

    test('Home Base uses canonical linear restoration cost and level cap', () {
      final state = ProgressionState.initial.copyWith(
        money: BigNumber.fromInt(150000),
      );
      final first = engine.upgradeHomeBase(state, LegacySystemsState.initial);
      expect(first.accepted, isTrue);
      expect(first.progression.money, BigNumber.fromInt(100000));
      expect(first.systems.homeBaseLevel, 1);
      final second = engine.upgradeHomeBase(first.progression, first.systems);
      expect(second.accepted, isTrue);
      expect(second.progression.money, BigNumber.fromInt(0));
      expect(second.systems.homeBaseLevel, 2);
      expect(
        engine.upgradeHomeBase(second.progression, second.systems).accepted,
        isFalse,
      );
    });

    test('mutators reject unknown IDs and apply shared reward multipliers', () {
      final invalid = engine.setMutator(
        ProgressionState.initial,
        LegacySystemsState.initial,
        'not_real',
        true,
      );
      expect(invalid.accepted, isFalse);
      final enabled = engine.setMutator(
        ProgressionState.initial,
        LegacySystemsState.initial,
        'mut_hardcore',
        true,
      );
      final all = enabled.systems.copyWith(
        activeMutators: const {
          'mut_hardcore',
          'mut_speed',
          'mut_blind',
          'mut_tax',
        },
      );
      expect(engine.mutatorRewardMultiplier(all), BigNumber.fromInt(300));
      expect(engine.rangeMultiplier(all), 2);
    });

    test('relic equipment requires ownership and is capped at four', () {
      var systems = LegacySystemsState.initial.copyWith(
        relicInventory: const {
          'verdant_guardian',
          'crystal_golem',
          'ember_dragon',
          'nebula_titan',
        },
      );
      for (final id in systems.relicInventory) {
        final result = engine.equipRelic(ProgressionState.initial, systems, id);
        expect(result.accepted, isTrue);
        systems = result.systems;
      }
      expect(systems.equippedRelics, hasLength(4));
      expect(
        engine
            .equipRelic(ProgressionState.initial, systems, 'unknown_relic')
            .accepted,
        isFalse,
      );
    });

    test('Lucky Stake settles exactly using the GTN1 streak multiplier', () {
      final progression = ProgressionState.initial.copyWith(
        money: BigNumber.fromInt(1000),
      );
      final won = engine.settleLuckyStake(
        progression: progression,
        systems: LegacySystemsState.initial,
        stake: BigNumber.fromInt(100),
        won: true,
        currentStreak: 5,
      );
      expect(won.accepted, isTrue);
      expect(won.progression.money, BigNumber.fromInt(1150));
      expect(won.systems.stakesPlaced, 1);
      expect(won.systems.stakesWon, 1);

      final lost = engine.settleLuckyStake(
        progression: progression,
        systems: LegacySystemsState.initial,
        stake: BigNumber.fromInt(100),
        won: false,
        currentStreak: 5,
      );
      expect(lost.progression.money, BigNumber.fromInt(900));
      expect(lost.systems.stakesLost, 1);
    });

    test(
      'daily reward is consecutive, capped at day seven and one claim per day',
      () {
        final yesterday = LegacySystemsState.initial.copyWith(
          lastDailyRewardDate: '2026-11-06',
          dailyRewardStreak: 6,
        );
        final today = engine.claimDailyReward(
          progression: ProgressionState.initial,
          systems: yesterday,
          today: '2026-11-07',
        );
        expect(today.accepted, isTrue);
        expect(today.progression.nebula, BigNumber.fromInt(50));
        expect(today.systems.dailyRewardStreak, 7);
        expect(
          engine
              .claimDailyReward(
                progression: today.progression,
                systems: today.systems,
                today: '2026-11-07',
              )
              .accepted,
          isFalse,
        );
      },
    );

    test('daily quests are claim-once and validate objective progress', () {
      final ready = LegacySystemsState.initial.copyWith(
        dailyQuestDate: '2026-11-07',
        dailyQuestGuesses: 10,
      );
      final claimed = engine.claimDailyQuest(
        progression: ProgressionState.initial,
        systems: ready,
        questId: 'daily_guesses_10',
        today: '2026-11-07',
      );
      expect(claimed.accepted, isTrue);
      expect(claimed.progression.money, BigNumber.fromInt(10000));
      expect(
        engine
            .claimDailyQuest(
              progression: claimed.progression,
              systems: claimed.systems,
              questId: 'daily_guesses_10',
              today: '2026-11-07',
            )
            .accepted,
        isFalse,
      );
    });

    test('loot chest consumes one chest and pays only the selected reward', () {
      final systems = LegacySystemsState.initial.copyWith(
        lootChests: const {'common': 1, 'rare': 0, 'epic': 0},
      );
      final result = engine.openLootChest(
        progression: ProgressionState.initial,
        systems: systems,
        tier: 'common',
        rewardNebula: true,
      );
      expect(result.accepted, isTrue);
      expect(result.progression.nebula, BigNumber.fromInt(5));
      expect(result.progression.money, BigNumber.fromInt(0));
      expect(result.systems.lootChests['common'], 0);
      expect(
        engine
            .openLootChest(
              progression: result.progression,
              systems: result.systems,
              tier: 'common',
              rewardNebula: false,
            )
            .accepted,
        isFalse,
      );
    });
  });
}
