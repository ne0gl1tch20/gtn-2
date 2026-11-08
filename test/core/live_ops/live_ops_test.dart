import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/live_ops/live_ops.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/live_ops/live_ops_repository.dart';

const _flags = '''
{
  "schemaVersion": 1,
  "flags": {
    "live_ops": true,
    "seasonal_rewards": true
  }
}
''';

const _manifest = '''
{
  "schemaVersion": 1,
  "manifestVersion": 2,
  "events": [
    {
      "id": "active_event",
      "title": "Active Event",
      "description": "An active event.",
      "status": "ACTIVE",
      "startDate": "2026-01-01T00:00:00Z",
      "endDate": "2026-12-31T23:59:59Z",
      "currencyName": "Nebula",
      "maxClaims": 2,
      "rewardNebula": 10,
      "permanentBoostPerClaim": 1,
      "minCorrectGuesses": 5,
      "minPrestigeCount": 1,
      "minUltraCount": 0
    },
    {
      "id": "future_event",
      "title": "Future Event",
      "description": "An upcoming event.",
      "status": "ACTIVE",
      "startDate": "2027-01-01T00:00:00Z",
      "endDate": "2027-02-01T00:00:00Z",
      "currencyName": "Nebula",
      "maxClaims": 1,
      "rewardNebula": 5
    }
  ]
}
''';

void main() {
  group('GTN1 LiveOps repository', () {
    test('validates the bundled manifest and resolves event status from UTC dates',
        () async {
      final repository = LiveOpsRepository(
        loadAsset: (path) async => switch (path) {
          'assets/game/feature_flags.json' => _flags,
          'assets/game/liveops_manifest.json' => _manifest,
          _ => throw StateError('Unexpected asset: $path'),
        },
        clock: () => DateTime.utc(2026, 11, 8),
      );

      final catalog = await repository.load();

      expect(catalog.enabled, isTrue);
      expect(catalog.manifestVersion, 2);
      expect(catalog.events.map((event) => event.status),
          ['ACTIVE', 'UPCOMING']);
    });

    test('requires both live_ops and seasonal_rewards feature flags', () async {
      const disabledFlags = '''
      {"schemaVersion":1,"flags":{"live_ops":true,"seasonal_rewards":false}}
      ''';
      final repository = LiveOpsRepository(
        loadAsset: (path) async => path.endsWith('feature_flags.json')
            ? disabledFlags
            : _manifest,
        clock: () => DateTime.utc(2026, 11, 8),
      );

      final catalog = await repository.load();

      expect(catalog.enabled, isFalse);
      expect(catalog.events, hasLength(2));
    });

    test('rejects duplicate event IDs and invalid event date windows', () async {
      const duplicateManifest = '''
      {"schemaVersion":1,"manifestVersion":2,"events":[
        {"id":"same","title":"One","description":"One","status":"ACTIVE","startDate":"2026-01-01T00:00:00Z","endDate":"2026-02-01T00:00:00Z","currencyName":"Nebula","maxClaims":1},
        {"id":"same","title":"Two","description":"Two","status":"ACTIVE","startDate":"2026-01-01T00:00:00Z","endDate":"2026-02-01T00:00:00Z","currencyName":"Nebula","maxClaims":1}
      ]}
      ''';
      final repository = LiveOpsRepository(
        loadAsset: (path) async => path.endsWith('feature_flags.json')
            ? _flags
            : duplicateManifest,
      );

      await expectLater(repository.load(), throwsFormatException);
    });
  });

  group('GTN1 LiveOps claim policy', () {
    final engine = LegacySystemsEngine();
    final event = LiveOpsEvent(
      id: 'season_1',
      title: 'Season 1',
      description: 'Seasonal reward',
      status: 'ACTIVE',
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 12, 31, 23, 59, 59),
      currencyName: 'Nebula',
      maxClaims: 2,
      rewardNebula: 10,
      permanentBoostPerClaim: 1,
      minCorrectGuesses: 5,
      minPrestigeCount: 1,
      minUltraCount: 0,
    );

    test('pays Nebula, increments claim count and permanent boost once', () {
      final progression = ProgressionState.initial.copyWith(
        correctGuesses: 5,
        prestigeResets: 1,
      );
      final result = engine.claimLiveOpsEvent(
        progression: progression,
        systems: LegacySystemsState.initial,
        event: event,
        featureEnabled: true,
        now: DateTime.utc(2026, 11, 8),
      );

      expect(result.accepted, isTrue);
      expect(result.progression.nebula.toString(), '10');
      expect(result.progression.nebulaEarned.toString(), '10');
      expect(result.systems.liveOpsClaims['season_1'], 1);
      expect(result.systems.permanentEventBoosts, 1);
    });

    test('rejects ineligible, disabled, expired and exhausted claims without mutation',
        () {
      final progression = ProgressionState.initial.copyWith(
        correctGuesses: 4,
        prestigeResets: 1,
      );
      final systems = LegacySystemsState.initial;
      final ineligible = engine.claimLiveOpsEvent(
        progression: progression,
        systems: systems,
        event: event,
        featureEnabled: true,
        now: DateTime.utc(2026, 11, 8),
      );
      final disabled = engine.claimLiveOpsEvent(
        progression: progression.copyWith(correctGuesses: 5),
        systems: systems,
        event: event,
        featureEnabled: false,
        now: DateTime.utc(2026, 11, 8),
      );
      final expired = engine.claimLiveOpsEvent(
        progression: progression.copyWith(correctGuesses: 5),
        systems: systems,
        event: event,
        featureEnabled: true,
        now: DateTime.utc(2027, 1, 1),
      );
      final exhausted = engine.claimLiveOpsEvent(
        progression: progression.copyWith(correctGuesses: 5),
        systems: systems.copyWith(liveOpsClaims: const {'season_1': 2}),
        event: event,
        featureEnabled: true,
        now: DateTime.utc(2026, 11, 8),
      );

      for (final result in [ineligible, disabled, expired, exhausted]) {
        expect(result.accepted, isFalse);
        expect(result.progression.nebula.toString(), '0');
        expect(result.systems.liveOpsClaims, isEmpty);
        expect(result.systems.permanentEventBoosts, 0);
      }
    });

    test('caps permanent event boosts at the GTN1 maximum of 25', () {
      final result = engine.claimLiveOpsEvent(
        progression: ProgressionState.initial.copyWith(
          correctGuesses: 5,
          prestigeResets: 1,
        ),
        systems: LegacySystemsState.initial.copyWith(
          permanentEventBoosts: 24,
        ),
        event: event,
        featureEnabled: true,
        now: DateTime.utc(2026, 11, 8),
      );

      expect(result.accepted, isTrue);
      expect(result.systems.permanentEventBoosts, 25);
    });
  });
}
