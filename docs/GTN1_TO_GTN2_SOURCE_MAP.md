# GTN1 → GTN2 Kotlin source map

**Authority:** GTN1 commit `fe9cf567169e19059e0330d08769fe454336ef94`  
**Target snapshot:** GTN2 `main` at `145da3982d32ec31bc412deac48c84ab1b17ab74`  
**Inventory:** `docs/GTN1_SOURCE_INVENTORY.json` (107 production Kotlin files)

This is a file-level migration map, not a parity-completion claim. A mapped row only identifies the current Dart replacement and relevant regression-test surface. Behavioral equivalence remains governed by `docs/FINITE_PARITY_PLAN.md` and `docs/GTN1_TO_GTN2_MIGRATION_CHECKLIST.md`.

## Mapped source files

| GTN1 source file | GTN2 implementation | Regression-test surface | Mapping status |
|---|---|---|---|
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/GuessingBot.kt` | `lib/core/automation/guessing_bot.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/AntiTimeTravelService.kt` | `lib/core/automation/clock_rollback_policy.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/OfflineEarningsCalculator.kt` | `lib/core/automation/offline_earnings_policy.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/model/RandomEvent.kt` | `lib/core/events/random_event_engine.dart` | `test/core/events/random_event_engine_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/scripting/LuaEngine.kt` | `lib/core/scripting/lua_sandbox.dart` | `test/core/scripting/lua_sandbox_test.dart` | Partial mapping; Android-specific archive/build integration still needs its own mapping |

## Remaining work

- [ ] Map the remaining 102 production Kotlin files.
- [ ] Identify grouped Dart replacements where one Dart module replaces multiple Kotlin classes.
- [ ] Identify Android-only components and verify whether each has a Flutter plugin, platform-channel implementation, or a justified not-applicable decision for Windows.
- [ ] Map every source file to the exact test or platform-verification evidence for its behavior.
- [ ] Reconcile this map with the source-by-source migration checklist before marking Stage 1 complete.

Do not infer parity from filename similarity. Update this map only after inspecting both the pinned GTN1 source and the current GTN2 implementation.
