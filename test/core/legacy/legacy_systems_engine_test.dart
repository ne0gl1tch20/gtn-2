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
      final blocked = engine.buyTalent(progression, systems, 'talent_speed_2');
      expect(blocked.accepted, isFalse);
      final first = engine.buyTalent(progression, systems, 'talent_speed_1');
      expect(first.accepted, isTrue);
      expect(first.progression.prestige.compareTo(n(9900)), 0);
      final duplicate = engine.buyTalent(
        first.progression, first.systems, 'talent_speed_1',
      );
      expect(duplicate.accepted, isFalse);
      final second = engine.buyTalent(
        first.progression, first.systems, 'talent_speed_2',
      );
      expect(second.accepted, isTrue);
      expect(second.progression.prestige.compareTo(n(9400)), 0);
    });

    test('rejects purchases when prestige is insufficient', () {
      final result = engine.buyTalent(
        ProgressionState.initial, LegacySystemsState.initial, 'talent_speed_1',
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
      );
      expect(LegacySystemsState.fromJson(systems.toJson()).toJson(), systems.toJson());
    });

    test('rejects invalid equipped relic and music references', () {
      expect(
        () => LegacySystemsState.fromJson({
          ...LegacySystemsState.initial.toJson(),
          'equippedRelics': ['verdant_guardian'],
          'relicInventory': [],
        }),
        throwsFormatException,
      );
      expect(
        () => LegacySystemsState.fromJson({
          ...LegacySystemsState.initial.toJson(),
          'musicLibrary': ['track_a'],
          'musicQueue': ['missing_track'],
        }),
        throwsFormatException,
      );
    });
  });
}
