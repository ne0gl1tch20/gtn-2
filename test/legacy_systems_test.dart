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
      expect(result.cosmeticBadgeTraitIds, contains('core_spark'));
      expect(result.cosmeticBadgeTraitIds, isNot(contains('combo_momentum')));
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

  group('daily reward, quest and loot parity', () {
    test('daily claim adds the trait bonus before applying Nebula Boost', () {
      final progression = ProgressionState.initial.copyWith(
        nebula: BigNumber.fromInt(2),
        nebulaEarned: BigNumber.fromInt(2),
      );
      final systems = LegacySystemsState.initial.copyWith(
        lastDailyRewardDate: '2026-11-06',
        dailyRewardStreak: 1,
      );

      final result = engine.claimDailyReward(
        progression: progression,
        systems: systems,
        today: '2026-11-07',
        traitNebulaBonus: 3,
        nebulaBoostOwned: true,
      );

      // Day two: (10 base + 3 trait bonus) × 2 boost = 26.
      expect(result.accepted, isTrue);
      expect(result.systems.dailyRewardStreak, 2);
      expect(result.systems.lastDailyRewardDate, '2026-11-07');
      expect(result.progression.nebula, BigNumber.fromInt(28));
      expect(result.progression.nebulaEarned, BigNumber.fromInt(28));
    });

    test('all four daily quest payouts and lifetime totals match GTN1', () {
      const today = '2026-11-07';
      final cases = <(String, LegacySystemsState, int, int)>[
        (
          'daily_guesses_10',
          LegacySystemsState.initial.copyWith(
            dailyQuestDate: today,
            dailyQuestGuesses: 10,
          ),
          10000,
          0,
        ),
        (
          'daily_correct_5',
          LegacySystemsState.initial.copyWith(
            dailyQuestDate: today,
            dailyQuestCorrectGuesses: 5,
          ),
          0,
          50,
        ),
        (
          'daily_streak_5',
          LegacySystemsState.initial.copyWith(
            dailyQuestDate: today,
            dailyQuestBestStreak: 5,
          ),
          0,
          100,
        ),
        (
          'daily_upgrades_3',
          LegacySystemsState.initial.copyWith(
            dailyQuestDate: today,
            dailyQuestUpgradePurchases: 3,
          ),
          0,
          70,
        ),
      ];

      for (final (questId, systems, moneyReward, nebulaReward) in cases) {
        final result = engine.claimDailyQuest(
          progression: ProgressionState.initial.copyWith(
            moneyEarned: BigNumber.fromInt(5),
            nebulaEarned: BigNumber.fromInt(7),
          ),
          systems: systems,
          questId: questId,
          today: today,
          nebulaBoostOwned: true,
        );

        expect(result.accepted, isTrue, reason: questId);
        expect(
          result.progression.money,
          BigNumber.fromInt(moneyReward),
          reason: '$questId Money payout',
        );
        expect(
          result.progression.moneyEarned,
          BigNumber.fromInt(5 + moneyReward),
          reason: '$questId lifetime Money',
        );
        expect(
          result.progression.nebula,
          BigNumber.fromInt(nebulaReward),
          reason: '$questId Nebula payout',
        );
        expect(
          result.progression.nebulaEarned,
          BigNumber.fromInt(7 + nebulaReward),
          reason: '$questId lifetime Nebula',
        );
        expect(result.systems.claimedDailyQuests, contains(questId));

        final duplicate = engine.claimDailyQuest(
          progression: result.progression,
          systems: result.systems,
          questId: questId,
          today: today,
          nebulaBoostOwned: true,
        );
        expect(duplicate.accepted, isFalse, reason: '$questId duplicate');
        expect(duplicate.progression, result.progression);
      }
    });

    test(
      'daily guess progress resets on date change before recording the guess',
      () {
        final previous = LegacySystemsState.initial.copyWith(
          dailyQuestDate: '2026-11-06',
          dailyQuestGuesses: 9,
          dailyQuestCorrectGuesses: 4,
          dailyQuestBestStreak: 6,
          dailyQuestUpgradePurchases: 3,
          claimedDailyQuests: const {'daily_guesses_10'},
          lootChests: const {'common': 2, 'rare': 1, 'epic': 0},
        );

        final next = engine.recordGuessProgress(
          previous,
          correct: false,
          currentStreak: 0,
          today: '2026-11-07',
          lootRoll: 0,
        );

        expect(next.dailyQuestDate, '2026-11-07');
        expect(next.dailyQuestGuesses, 1);
        expect(next.dailyQuestCorrectGuesses, 0);
        expect(next.dailyQuestBestStreak, 0);
        expect(next.dailyQuestUpgradePurchases, 0);
        expect(next.claimedDailyQuests, isEmpty);
        expect(next.lootChests, const {'common': 2, 'rare': 1, 'epic': 0});
        expect(next.lootDropsFound, 0);
      },
    );

    test('loot-drop roll boundaries match the source tier probabilities', () {
      const today = '2026-11-07';
      const cases = <(int, String?)>[
        (0, 'epic'),
        (9, 'epic'),
        (10, 'rare'),
        (59, 'rare'),
        (60, 'common'),
        (239, 'common'),
        (240, null),
        (999, null),
      ];

      for (final (roll, expectedTier) in cases) {
        final result = engine.recordGuessProgress(
          LegacySystemsState.initial.copyWith(dailyQuestDate: today),
          correct: true,
          currentStreak: 3,
          today: today,
          lootRoll: roll,
        );

        expect(result.dailyQuestGuesses, 1, reason: 'roll $roll');
        expect(result.dailyQuestCorrectGuesses, 1, reason: 'roll $roll');
        expect(result.dailyQuestBestStreak, 3, reason: 'roll $roll');
        expect(result.lastLootDropTier, expectedTier, reason: 'roll $roll');
        expect(result.lootDropsFound, expectedTier == null ? 0 : 1);
        expect(result.lootEventId, expectedTier == null ? 0 : 1);
        for (final tier in const ['common', 'rare', 'epic']) {
          expect(
            result.lootChests[tier],
            tier == expectedTier ? 1 : 0,
            reason: 'roll $roll $tier inventory',
          );
        }
      }
    });

    test(
      'upgrade purchases reset stale daily progress then count the purchase',
      () {
        final result = engine.recordUpgradePurchase(
          LegacySystemsState.initial.copyWith(
            dailyQuestDate: '2026-11-06',
            dailyQuestGuesses: 9,
            dailyQuestCorrectGuesses: 4,
            dailyQuestBestStreak: 5,
            dailyQuestUpgradePurchases: 2,
            claimedDailyQuests: const {'daily_guesses_10'},
          ),
        );
        final today = DateTime.now().toIso8601String().substring(0, 10);

        expect(result.dailyQuestDate, today);
        expect(result.dailyQuestGuesses, 0);
        expect(result.dailyQuestCorrectGuesses, 0);
        expect(result.dailyQuestBestStreak, 0);
        expect(result.dailyQuestUpgradePurchases, 1);
        expect(result.claimedDailyQuests, isEmpty);
      },
    );

    test(
      'all chest tiers consume one chest and credit only the selected currency',
      () {
        const rewards = <String, (int, int)>{
          'common': (5000, 5),
          'rare': (25000, 25),
          'epic': (100000, 100),
        };

        for (final entry in rewards.entries) {
          for (final rewardNebula in [false, true]) {
            final result = engine.openLootChest(
              progression: ProgressionState.initial.copyWith(
                money: BigNumber.fromInt(20),
                moneyEarned: BigNumber.fromInt(10),
                nebula: BigNumber.fromInt(5),
                nebulaEarned: BigNumber.fromInt(3),
              ),
              systems: LegacySystemsState.initial.copyWith(
                lootChests: {'common': 0, 'rare': 0, 'epic': 0, entry.key: 1},
              ),
              tier: entry.key,
              rewardNebula: rewardNebula,
            );

            expect(
              result.accepted,
              isTrue,
              reason: '${entry.key} $rewardNebula',
            );
            expect(result.systems.lootChests[entry.key], 0);
            expect(result.systems.lootChestsOpened, 1);
            expect(
              result.progression.money,
              BigNumber.fromInt(20 + (rewardNebula ? 0 : entry.value.$1)),
            );
            expect(
              result.progression.moneyEarned,
              BigNumber.fromInt(10 + (rewardNebula ? 0 : entry.value.$1)),
            );
            expect(
              result.progression.nebula,
              BigNumber.fromInt(5 + (rewardNebula ? entry.value.$2 : 0)),
            );
            expect(
              result.progression.nebulaEarned,
              BigNumber.fromInt(3 + (rewardNebula ? entry.value.$2 : 0)),
            );
          }
        }
      },
    );
  });
}
