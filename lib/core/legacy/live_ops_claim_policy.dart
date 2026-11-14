import '../numbers/big_number.dart';
import '../progression/progression_state.dart';
import 'legacy_systems_state.dart';

/// Bounded reward definition supplied by the trusted LiveOps event catalog.
///
/// Date-window and feature-flag checks remain the caller's responsibility.
class LiveOpsClaimDefinition {
  const LiveOpsClaimDefinition({
    required this.id,
    required this.maxClaims,
    required this.rewardNebula,
    required this.permanentBoostPerClaim,
    required this.minCorrectGuesses,
    required this.minPrestigeCount,
    required this.minUltraCount,
  });

  final String id;
  final int maxClaims;
  final int rewardNebula;
  final int permanentBoostPerClaim;
  final int minCorrectGuesses;
  final int minPrestigeCount;
  final int minUltraCount;
}

class LiveOpsClaimSettlement {
  const LiveOpsClaimSettlement({
    required this.progression,
    required this.systems,
  });

  final ProgressionState progression;
  final LegacySystemsState systems;
}

/// Mirrors GTN1's Kotlin-owned LiveOpsClaimPolicy.
///
/// Scripts and event content cannot mutate currencies or progression directly.
class LiveOpsClaimPolicy {
  static const int _maxLong = 0x7fffffffffffffff;

  static LiveOpsClaimSettlement? apply({
    required ProgressionState progression,
    required LegacySystemsState systems,
    required LiveOpsClaimDefinition event,
  }) {
    if (event.id.trim().isEmpty ||
        event.maxClaims <= 0 ||
        event.rewardNebula < 0 ||
        event.rewardNebula > _maxLong ||
        event.permanentBoostPerClaim < 0 ||
        event.minCorrectGuesses < 0 ||
        event.minPrestigeCount < 0 ||
        event.minUltraCount < 0) {
      return null;
    }

    if (progression.correctGuesses < 0 ||
        progression.prestigeResets < 0 ||
        progression.ultraResets < 0 ||
        systems.permanentEventBoosts < 0) {
      return null;
    }

    final claims = systems.liveOpsClaims[event.id] ?? 0;
    if (claims < 0 || claims >= event.maxClaims) return null;

    final nebulaEarned = progression.nebulaEarned;
    if (nebulaEarned.compareTo(BigNumber.fromInt(0)) < 0 ||
        nebulaEarned.compareTo(BigNumber.fromInt(_maxLong - event.rewardNebula)) >
            0) {
      return null;
    }

    final eligible =
        progression.correctGuesses >= event.minCorrectGuesses &&
        progression.prestigeResets >= event.minPrestigeCount &&
        progression.ultraResets >= event.minUltraCount;
    if (!eligible) return null;

    final reward = BigNumber.fromInt(event.rewardNebula);
    final nextClaims = Map<String, int>.of(systems.liveOpsClaims)
      ..[event.id] = claims + 1;
    final nextBoost = (systems.permanentEventBoosts +
            event.permanentBoostPerClaim)
        .clamp(0, 25)
        .toInt();

    return LiveOpsClaimSettlement(
      progression: progression.copyWith(
        nebula: progression.nebula + reward,
        nebulaEarned: nebulaEarned + reward,
      ),
      systems: systems.copyWith(
        liveOpsClaims: Map.unmodifiable(nextClaims),
        permanentEventBoosts: nextBoost,
      ),
    );
  }
}
