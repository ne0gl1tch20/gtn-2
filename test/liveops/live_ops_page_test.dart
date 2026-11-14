import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/liveops/live_ops_repository.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/liveops/live_ops_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'LiveOps page displays event claims and invokes the claim action',
    (tester) async {
      final repository = LiveOpsRepository(
        loadAsset: (path) async => path.endsWith('liveops_manifest.json')
            ? '''
            {
              "schemaVersion": 1,
              "manifestVersion": 2,
              "events": [{
                "id": "test_event",
                "title": "Test Seasonal Event",
                "description": "Claim a reward during the event.",
                "status": "ACTIVE",
                "startDate": "2026-11-01T00:00:00Z",
                "endDate": "2026-12-31T23:59:59Z",
                "currencyName": "Nebula",
                "maxClaims": 2,
                "rewardNebula": 10,
                "permanentBoostPerClaim": 1,
                "minCorrectGuesses": 100,
                "minPrestigeCount": 0,
                "minUltraCount": 0
              }]
            }
            '''
            : '{"schemaVersion":1,"flags":{"live_ops":true,"seasonal_rewards":true}}',
        clock: () => DateTime.utc(2026, 11, 14, 12),
      );
      final progression = ProgressionState.initial.copyWith(
        totalGuesses: 100,
        correctGuesses: 100,
      );
      String? claimedId;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
          fontFamily: 'Manrope',
          autoTheming: false,
          initialTheme: Brightness.light,
          home: LiveOpsPage(
            progression: progression,
            repository: repository,
            onClaim: (event) async {
              claimedId = event.id;
              return progression.copyWith(
                legacySystems: progression.legacySystems.copyWith(
                  liveOpsClaims: {'test_event': 1},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seasonal Events'), findsNWidgets(2));
      expect(find.text('Test Seasonal Event'), findsOneWidget);
      expect(find.text('Claims: 0 / 2'), findsOneWidget);
      await tester.tap(find.text('Claim Reward (+10 Nebula)'));
      await tester.pumpAndSettle();
      expect(claimedId, 'test_event');
      expect(find.text('Claims: 1 / 2'), findsOneWidget);
    },
  );
}
