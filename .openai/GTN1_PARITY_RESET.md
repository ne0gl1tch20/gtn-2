# GTN1 → GTN2 parity reset

## Authority

- Source repository: `ne0gl1tch20/GuessTheNumber`
- Pinned source revision: `fe9cf567169e19059e0330d08769fe454336ef94`
- Target repository: `ne0gl1tch20/gtn-2`
- Target baseline: `main`
- Active reset branch: `port/gtn1-parity-reset`

GTN1 is the behavioral source of truth. Do not invent new rules where a tested GTN1 implementation exists. Port its inputs, validation, state transitions, rewards, persistence and edge cases. Keep Flutter/Dart as the target implementation.

## Verified baseline (not a completion claim)

| Area | GTN2 evidence | Reset status |
|---|---|---|
| Guessing, difficulty, progression and upgrades | `lib/core/game`, `lib/core/progression`, engine tests | Implemented; exact formula parity still needs a source-by-source audit |
| Bot team | `lib/core/automation/guessing_bot.dart`, `bot_team.dart`, timer integration in `lib/main.dart` | Implemented; policy tests exist; lifecycle integration needs verification |
| Offline earnings and clock rollback | `offline_earnings_policy.dart`, `clock_rollback_policy.dart`, restore flow | Implemented; policy tests exist; compare every GTN1 boundary |
| World map and bosses | `lib/worlds/world_map_page.dart`, `world_boss_battle_engine.dart`, catalog and tests | Implemented; verify all unlock/reward paths against GTN1 |
| Trait catalog and activation | Pinned GTN1 catalog bundle, `legacy_systems_engine.dart`, invisible trait engine | Implemented; verify every gameplay effect and adaptive bonus against GTN1 |
| Talents, mutators, relics, sanctuary, stakes, daily quests, loot and challenges | `legacy_systems_engine.dart` and `legacy_systems_page.dart` | Implemented in one systems screen; transaction-by-transaction parity audit remains |
| Arcade | `lib/arcade`, seven-game catalog and reward tests | Implemented; each game loop and payout still needs direct GTN1 comparison |
| Music | Offline file import, audio playback, queue, playlists, shuffle and repeat in legacy systems page | Partial parity; verify lifecycle, queue and error behavior |
| Random events | Added Dart selector (35% chance every 60 seconds), all seven Kotlin-owned reward effects, persisted event ID/count and eight-second event banner lifecycle | Ported and covered by deterministic tests; validation run #587 passed |
| LiveOps and seasonal events | `LiveOpsRepository`, `LiveOpsEvent`, `LegacySystemsEngine.claimLiveOpsEvent`, bundled manifest and feature flags | Ported on reset branch with claim, eligibility, date-window, max-claim, reward and permanent-boost tests; remote signed Lua refresh remains unported |
| Random events | GTN1 `RandomEventEngine`, Lua selector and 60-second scheduler; target only stores `lastRandomEventId` | Missing: event selection, effects, persistence, timer and notification behavior |
| About and updater | `lib/data/updates/update_checker.dart` and About section | Update check/install code exists; publishing is intentionally disabled until parity gate passes |
| Creative Mode | Runtime and schema in `lib/core/creative/creative_mode.dart`; UI and entry points on reset branch | UI added on reset branch; deterministic widget test now uses in-memory storage |
| Save profiles and metadata | `SaveData.copyWith`, atomic `SaveStorage.update/createIfEmpty/duplicateTo`, profile updates | Ported onto reset branch with regression tests; CI verification pending |

## Confirmed work on the reset branch

- Added Creative Mode entry points from the More hub and per-slot menu.
- Added the Creative Mode page using the existing GTN1-compatible runtime and per-slot save model.
- Replaced the slow, real-filesystem Creative Mode widget test with a deterministic in-memory storage fake. File persistence remains covered by SaveStorage tests.
- Ported save metadata preservation and serialized read/modify/write operations. Gameplay autosaves now update the existing save rather than rebuilding a reduced save object that drops profile or Creative Mode metadata.
- Ported regression tests for save metadata, concurrent slot creation and duplicate-slot collisions.
- Kept Android/Windows debug publishing disabled until the full parity gate is met.

## Known parity gaps still open

- GTN1 signed remote LiveOps bundle refresh and verified script/event cache are not yet ported. GTN2 currently uses the bundled, validated event manifest and feature flags offline; do not mark remote LiveOps delivery complete.
- The random-event timer pauses while the Flutter app is inactive and restarts its 60-second interval on resume. GTN1 runs its coroutine while the process remains alive. Verify whether background timing is required before calling lifecycle parity complete.
- Lua parity is partial: the current sandbox uses a 500 ms wall-clock budget rather than LuaJ's exact 100,000-instruction hook, does not yet expose GTN1's full input snapshot/host API, and does not refresh the signed remote LiveOps script bundle. The developer-only Lua Testing Hub/typed command console is not yet exposed in Flutter.
- Finish the per-feature comparison for every catalog, rule, UI action, migration and failure path. The inventory above is not an exhaustive completion certificate.

## Android CI investigation

- Validation run [#587](https://github.com/ne0gl1tch20/gtn-2/actions/runs/42472569299) passed on commit `f04b3dc02690424dfb7c4de93c8d3362c78ceb02`: formatting, `flutter analyze --fatal-infos`, full `flutter test`, Android debug APK build and Windows desktop debug build.
- After the Lua Activity Hub port, validation run [#602](https://github.com/ne0gl1tch20/gtn-2/actions/runs/42473519760) passed on commit `f3aca2e8bcfdc6e97cd940bed70fe18f869c2b67`: formatting, `flutter analyze --fatal-infos`, full `flutter test`, Android debug APK build and Windows desktop debug build.
- The validation workflow compiles the APK but does not upload an artifact. The separate artifact workflow only runs on pushes to `main`/`master`, and the publish job remains explicitly disabled until the full parity gate passes. No APK artifact or release was published from this feature branch.

The Android job failed while downloading Gradle 9.3.1 from the GitHub release asset endpoint (HTTP 504). An attempted direct-host rewrite changed the Gradle wrapper cache key, bypassing the already-populated cache, and was therefore counterproductive. That rewrite was removed from both `main` and this branch. The existing Gradle cache setup and bounded retry remain.

Windows debug builds have succeeded. No verified Android APK has been produced by this reset branch yet.

## Completion gate

Do not call GTN2 complete and do not publish `debug-latest` until all are true:

1. Every GTN1 player-facing feature has a corresponding GTN2 implementation or an explicitly documented source-side absence.
2. Gameplay calculations, rewards, unlocks, failure cases, persistence and migrations match the pinned GTN1 behavior.
3. Each subsystem has deterministic Dart tests derived from GTN1 test cases or verified source rules.
4. `dart format`, `flutter analyze --fatal-infos` and the complete `flutter test` suite pass.
5. Android debug APK and Windows debug builds both succeed.
6. The Android APK is inspected and installed/launched successfully; the artifact is retained for seven days.
7. Only after the above gate passes may the `debug-latest` release workflow be enabled.

## Rules for continuing work

- Re-read the pinned GTN1 implementation before changing a subsystem.
- Reuse GTN1 constants, catalog data, thresholds and edge-case behavior.
- Never replace real functionality with a label, mock, placeholder or catalog-only UI.
- Keep changes on `port/gtn1-parity-reset` until a coherent, tested unit is ready.
- Do not claim tests, APK creation, installation or feature completion unless the corresponding result is visible in CI or an actual device test.
