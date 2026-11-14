import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/liveops/live_ops_repository.dart';

const _manifest = '''
{
  "schemaVersion": 1,
  "manifestVersion": 2,
  "events": [
    {
      "id": "upcoming_event",
      "title": "Upcoming Event",
      "description": "Starts later.",
      "status": "UPCOMING",
      "startDate": "2026-12-01T00:00:00Z",
      "endDate": "2026-12-31T23:59:59Z",
      "currencyName": "Nebula",
      "maxClaims": 3,
      "rewardNebula": 10,
      "permanentBoostPerClaim": 1,
      "minCorrectGuesses": 0,
      "minPrestigeCount": 0,
      "minUltraCount": 0
    },
    {
      "id": "active_event",
      "title": "Active Event",
      "description": "Available now.",
      "status": "UPCOMING",
      "startDate": "2026-11-01T00:00:00Z",
      "endDate": "2026-12-31T23:59:59Z",
      "currencyName": "Nebula",
      "maxClaims": 5,
      "rewardNebula": 20,
      "permanentBoostPerClaim": 1,
      "minCorrectGuesses": 100,
      "minPrestigeCount": 0,
      "minUltraCount": 0
    },
    {
      "id": "ending_event",
      "title": "Ending Event",
      "description": "Ending soon.",
      "status": "ENDING",
      "startDate": "2026-11-01T00:00:00Z",
      "endDate": "2026-12-31T23:59:59Z",
      "currencyName": "Nebula",
      "maxClaims": 5,
      "rewardNebula": 10,
      "permanentBoostPerClaim": 0,
      "minCorrectGuesses": 0,
      "minPrestigeCount": 0,
      "minUltraCount": 0
    }
  ]
}
''';

const _flags = '''
{
  "schemaVersion": 1,
  "flags": {
    "live_ops": true,
    "seasonal_rewards": true
  }
}
''';

void main() {
  LiveOpsRepository repository({
    String manifest = _manifest,
    String flags = _flags,
    DateTime? now,
  }) => LiveOpsRepository(
    loadAsset: (path) async => switch (path) {
      'assets/game/liveops_manifest.json' => manifest,
      'assets/game/feature_flags.json' => flags,
      _ => throw StateError('Unexpected asset: $path'),
    },
    clock: () => now ?? DateTime.utc(2026, 11, 14, 12),
  );

  test('derives Upcoming, Active and Ending statuses from event dates', () async {
    final result = await repository().load();
    expect(result.enabled, isTrue);
    expect(result.events.map((event) => event.status).toList(), [
      'UPCOMING',
      'ACTIVE',
      'ENDING',
    ]);
  });

  test('feature flags gate event offers without discarding manifest data', () async {
    const disabledFlags = '''
    {"schemaVersion":1,"flags":{"live_ops":false,"seasonal_rewards":true}}
    ''';
    final result = await repository(flags: disabledFlags).load();
    expect(result.enabled, isFalse);
    expect(result.events, hasLength(3));
  });

  test('archives expired events and preserves explicitly archived events', () async {
    final expired = _manifest.replaceFirst(
      '"startDate": "2026-11-01T00:00:00Z",\n      "endDate": "2026-12-31T23:59:59Z"',
      '"startDate": "2026-10-01T00:00:00Z",\n      "endDate": "2026-11-01T00:00:00Z"',
    );
    final result = await repository(manifest: expired).load();
    expect(result.events[1].status, 'ARCHIVED');
  });

  test('rejects duplicate IDs and invalid date windows', () async {
    final duplicate = _manifest.replaceFirst(
      '"id": "ending_event"',
      '"id": "active_event"',
    );
    expect((await repository(manifest: duplicate).load()).events, isEmpty);

    final invalidDate = _manifest.replaceFirst(
      '2026-12-31T23:59:59Z',
      '2026-10-01T00:00:00Z',
    );
    expect((await repository(manifest: invalidDate).load()).events, isEmpty);
  });

  test('rejects invalid feature flag schema and invalid reward limits', () async {
    expect(
      (await repository(flags: '{"schemaVersion":2,"flags":{}}').load()).enabled,
      isFalse,
    );
    final invalidReward = _manifest.replaceFirst('"rewardNebula": 20', '"rewardNebula": -1');
    expect((await repository(manifest: invalidReward).load()).events, isEmpty);
  });

  test('bundled manifest and flags load as a usable offline catalog', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final result = await LiveOpsRepository(
      clock: () => DateTime.utc(2026, 11, 14, 12),
    ).load();
    expect(result.enabled, isTrue);
    expect(result.events.map((event) => event.id).toSet(), {
      'season_1_cyber_guess',
      'holiday_neon_rush',
    });
    expect(result.events.every((event) => event.maxClaims > 0), isTrue);
  });
}
