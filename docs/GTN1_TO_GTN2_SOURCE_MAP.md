# GTN1 → GTN2 Kotlin source map

**Authority:** GTN1 commit `fe9cf567169e19059e0330d08769fe454336ef94`  
**Target snapshot:** GTN2 `main` at `64a8ecfeb9a27d40262a786507693ac6a58660aa`  
**Inventory:** `docs/GTN1_SOURCE_INVENTORY.json` (107 production Kotlin files)

This is a file-level migration map, not a parity-completion claim. A mapped row only identifies the current Dart replacement and relevant regression-test surface. Behavioral equivalence remains governed by `docs/FINITE_PARITY_PLAN.md` and `docs/GTN1_TO_GTN2_MIGRATION_CHECKLIST.md`.

## Inspected source files

| GTN1 source file | GTN2 implementation | Regression-test surface | Mapping status |
|---|---|---|---|
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/GuessingBot.kt` | `lib/core/automation/guessing_bot.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/AntiTimeTravelService.kt` | `lib/core/automation/clock_rollback_policy.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/engine/OfflineEarningsCalculator.kt` | `lib/core/automation/offline_earnings_policy.dart` | `test/core/automation/automation_policy_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/domain/model/RandomEvent.kt` | `lib/core/events/random_event_engine.dart` | `test/core/events/random_event_engine_test.dart` | Mapped; behavior still requires source-case verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/scripting/LuaEngine.kt` | `lib/core/scripting/lua_sandbox.dart` | `test/core/scripting/lua_sandbox_test.dart` | Partial mapping; Android-specific archive/build integration still needs its own mapping |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/BuiltInTraits.kt` | `lib/core/legacy/builtin_trait_catalog.dart` | `test/legacy_systems_test.dart` | Mapped; all 320 stable IDs are represented, effect parity remains open |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitActivationEngine.kt` | `lib/core/legacy/legacy_systems_engine.dart` (`evaluateTraits`, `discoverEligibleTraits`) | `test/legacy_systems_test.dart`, `test/core/legacy/legacy_systems_engine_test.dart` | Partial; activation and discovery are represented, source-case parity remains open |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitDefinition.kt` | `lib/core/legacy/trait_catalog_repository.dart` and the engine's `_Trait` model | `test/core/legacy/trait_catalog_repository_test.dart` | Partial; typed definitions and package validation exist, full schema parity remains open |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitExtensionRuntime.kt` | No equivalent trait-module host identified; `lib/core/scripting/lua_sandbox.dart` is only a general Lua sandbox | `test/core/scripting/lua_sandbox_test.dart` | Gap; trait manifest/module lifecycle and capability integration are not mapped |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitGameplayCatalog.kt` | `lib/core/legacy/legacy_systems_engine.dart` (`gameplayArms`) and `lib/legacy/legacy_systems_page.dart` | `test/core/legacy/legacy_systems_engine_test.dart` | Partial; selectable gameplay arms are represented, all catalog behavior needs verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitGameplayRuntime.kt` | `lib/main.dart` (`_submitGuess`), `lib/core/legacy/legacy_systems_engine.dart`, `lib/core/legacy/invisible_trait_engine.dart` | `test/core/guess_economy_rules_test.dart`, `test/core/legacy/invisible_trait_engine_test.dart` | Partial; modifiers are wired into guessing, full source-case parity remains open |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitLiveOpsRepository.kt` | No equivalent signed remote trait-package repository identified | None identified | Gap; signed LiveOps package fetch, validation and lifecycle are not mapped |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitLocaleCatalog.kt` | `lib/core/legacy/trait_catalog_repository.dart` and `lib/i18n/app_localizations.dart` | `test/core/legacy/trait_catalog_repository_test.dart` | Partial; bundled package localization is loaded, locale fallback parity is unverified |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitRewardPolicy.kt` | `lib/core/legacy/legacy_systems_engine.dart` (`discoverEligibleTraits`, daily reward settlement) and `lib/legacy/legacy_systems_page.dart` | `test/core/legacy/legacy_systems_engine_test.dart`, `test/legacy_systems_test.dart` | Partial; discovery and daily-claim bonus are connected, remaining policy cases need verification |
| `app/src/main/java/com/jarrlyyy/guessthenumber/traits/TraitSeasonPolicy.kt` | `lib/main.dart` (`_currentSeasonId`) and `lib/legacy/legacy_systems_page.dart` (`_seasonId`) | `test/legacy_systems_test.dart` | Partial; season mapping exists, calendar-boundary parity needs dedicated verification |

## Remaining work

- [ ] Inspect and map the remaining 92 production Kotlin files. Fifteen of 107 files have been inspected so far: 13 have a Dart/platform mapping (some partial) and two concrete gaps are identified.
- [ ] Identify grouped Dart replacements where one Dart module replaces multiple Kotlin classes.
- [ ] Identify Android-only components and verify whether each has a Flutter plugin, platform-channel implementation, or a justified not-applicable decision for Windows.
- [ ] Map every source file to the exact test or platform-verification evidence for its behavior.
- [ ] Reconcile this map with the source-by-source migration checklist before marking Stage 1 complete.

Do not infer parity from filename similarity. Update this map only after inspecting both the pinned GTN1 source and the current GTN2 implementation.
