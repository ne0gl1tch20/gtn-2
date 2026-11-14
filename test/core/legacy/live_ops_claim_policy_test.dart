import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/legacy/live_ops_claim_policy.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';

void main() {
  const event = LiveOpsClaimDefinition(
    id: 'test_season',
    maxClaims: 2,
    rewardNebula: 10,
    permanentBoostPerClaim: 1,
    minCorrectGuesses: 100,
    minPrestigeCount: 1,
    minUltraCount: 0,
  );

  final eligibleProgression = ProgressionState.initial.copyWith(
    correctGuesses: 100,
    prestigeResets: 1,
    nebula: BigNumber.fromInt(5),
  );
  final initialSystems = LegacySystemsState.initial.copyWith(
    permanentEventBoosts: 3,
  );

  group('LiveOpsClaimPolicy', () {
    test(
      'awards Nebula, lifetime earnings, claim progress and permanent boost',
      () {
        final result = LiveOpsClaimPolicy.apply(
          progression: eligibleProgression,
          systems: initialSystems,
          event: event,
        );

        expect(result, isNotNull);
        expect(result!.progression.nebula.compareTo(BigNumber.fromInt(15)), 0);
        expect(
          result.progression.nebulaEarned.compareTo(BigNumber.fromInt(10)),
          0,
        );
        expect(result.systems.liveOpsClaims['test_season'], 1);
        expect(result.systems.permanentEventBoosts, 4);
      },
    );

    test('enforces all three progression requirements', () {
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(correctGuesses: 99),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(prestigeResets: 0),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(ultraResets: 0),
          systems: initialSystems,
          event: event.copyWithForTest(minUltraCount: 1),
        ),
        isNull,
      );
    });

    test('enforces per-event claim cap and rejects negative stored claims', () {
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression,
          systems: initialSystems.copyWith(
            liveOpsClaims: const {'test_season': 2},
          ),
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression,
          systems: initialSystems.copyWith(
            liveOpsClaims: const {'test_season': -1},
          ),
          event: event,
        ),
        isNull,
      );
    });

    test('caps permanent boost at level twenty-five', () {
      final result = LiveOpsClaimPolicy.apply(
        progression: eligibleProgression,
        systems: initialSystems.copyWith(permanentEventBoosts: 25),
        event: event,
      );
      expect(result!.systems.permanentEventBoosts, 25);
    });

    test('rejects corrupted progression and boost counters', () {
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(correctGuesses: -1),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(prestigeResets: -1),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(ultraResets: -1),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression,
          systems: initialSystems.copyWith(permanentEventBoosts: -1),
          event: event,
        ),
        isNull,
      );
    });

    test('rejects invalid definitions', () {
      final invalidEvents = [
        const LiveOpsClaimDefinition(
          id: ' ',
          maxClaims: 2,
          rewardNebula: 10,
          permanentBoostPerClaim: 1,
          minCorrectGuesses: 0,
          minPrestigeCount: 0,
          minUltraCount: 0,
        ),
        event.copyWithForTest(maxClaims: 0),
        event.copyWithForTest(rewardNebula: -1),
        event.copyWithForTest(permanentBoostPerClaim: -1),
        event.copyWithForTest(minCorrectGuesses: -1),
        event.copyWithForTest(minPrestigeCount: -1),
        event.copyWithForTest(minUltraCount: -1),
      ];
      for (final invalid in invalidEvents) {
        expect(
          LiveOpsClaimPolicy.apply(
            progression: eligibleProgression,
            systems: initialSystems,
            event: invalid,
          ),
          isNull,
        );
      }
    });

    test('rejects lifetime Nebula statistic overflow and negative value', () {
      final maxLong = BigNumber.parse('9223372036854775807');
      final overflow = eligibleProgression.copyWith(
        nebulaEarned: maxLong - BigNumber.fromInt(5),
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: overflow,
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
      expect(
        LiveOpsClaimPolicy.apply(
          progression: eligibleProgression.copyWith(
            nebulaEarned: BigNumber.fromInt(-1),
          ),
          systems: initialSystems,
          event: event,
        ),
        isNull,
      );
    });

    test('zero Nebula reward is valid and still records the claim', () {
      final result = LiveOpsClaimPolicy.apply(
        progression: eligibleProgression,
        systems: initialSystems,
        event: event.copyWithForTest(rewardNebula: 0),
      );
      expect(result, isNotNull);
      expect(
        result!.progression.nebula.compareTo(eligibleProgression.nebula),
        0,
      );
      expect(result.systems.liveOpsClaims['test_season'], 1);
    });

    test('persists a settled claim across a save JSON round trip', () {
      final result = LiveOpsClaimPolicy.apply(
        progression: eligibleProgression,
        systems: initialSystems,
        event: event,
      )!;
      final save = SaveData(
        secret: 42,
        attempts: 0,
        gamesWon: 0,
        progression: result.progression.copyWith(legacySystems: result.systems),
      );

      final restored = SaveData.fromJson(save.toJson()).progression;
      expect(restored.nebula.compareTo(BigNumber.fromInt(15)), 0);
      expect(restored.nebulaEarned.compareTo(BigNumber.fromInt(10)), 0);
      expect(restored.legacySystems.liveOpsClaims['test_season'], 1);
      expect(restored.legacySystems.permanentEventBoosts, 4);
    });

    test('LegacySystemsEngine exposes the same atomic claim transaction', () {
      final result = const LegacySystemsEngine().claimLiveOpsReward(
        progression: eligibleProgression,
        systems: initialSystems,
        event: event,
      );
      expect(result.accepted, isTrue);
      expect(result.progression.nebula.compareTo(BigNumber.fromInt(15)), 0);
      expect(result.systems.liveOpsClaims['test_season'], 1);
    });
  });
}

extension on LiveOpsClaimDefinition {
  LiveOpsClaimDefinition copyWithForTest({
    String? id,
    int? maxClaims,
    int? rewardNebula,
    int? permanentBoostPerClaim,
    int? minCorrectGuesses,
    int? minPrestigeCount,
    int? minUltraCount,
  }) => LiveOpsClaimDefinition(
    id: id ?? this.id,
    maxClaims: maxClaims ?? this.maxClaims,
    rewardNebula: rewardNebula ?? this.rewardNebula,
    permanentBoostPerClaim:
        permanentBoostPerClaim ?? this.permanentBoostPerClaim,
    minCorrectGuesses: minCorrectGuesses ?? this.minCorrectGuesses,
    minPrestigeCount: minPrestigeCount ?? this.minPrestigeCount,
    minUltraCount: minUltraCount ?? this.minUltraCount,
  );
}
