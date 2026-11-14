# GTN1 Shared KMP → GTN2 Dart source map

**Authority:** `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**GTN2 snapshot inspected:** `main` at `e314459698e9b691a89b496be3a87b57ae1bd147`  
**Inventory:** `docs/GTN1_SOURCE_INVENTORY.json` — exactly 50 shared production Kotlin files and 30 shared Kotlin tests.

This is a file-level destination map, not a parity-completion claim. A mapped target means a relevant implementation exists; it does not prove the source behavior, edge cases or platform behavior are equivalent. Gaps below remain parity work. UI sources are mapped to native Flutter destinations because GTN2 does not embed GTN1 Compose UI.

## Status definitions

- **Mapped:** a corresponding Dart implementation and relevant test surface are present; source-case parity still belongs to the applicable stage checklist.
- **Partial:** a Dart destination exists, but the source contract is broader, a behavior/test is missing, or the target is only an adaptation.
- **Gap:** no source-compatible Dart implementation or regression coverage was found in the inspected GTN2 snapshot.
- **N/A:** the original implementation is tied to a platform or UI technology that GTN2 intentionally replaces; the user-facing behavior is mapped separately where applicable.

## 1. Common KMP production sources (27)

| GTN1 source | GTN2 destination | Regression surface | Mapping |
|---|---|---|---|
| `shared/domain/ChallengeRewardRules.kt` | `lib/arcade/arcade_reward_rules.dart`; challenge settlement in `lib/core/legacy/legacy_systems_engine.dart` | `test/arcade/arcade_reward_rules_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial — Arcade reward policy exists; full challenge reward eligibility/settlement comparison remains open. |
| `shared/domain/CriticalChanceRules.kt` | `lib/core/game/guess_economy_rules.dart` | `test/core/guess_economy_rules_test.dart` | Mapped — critical chance formula and levels have focused coverage. |
| `shared/domain/DifficultyRules.kt` | `lib/core/game/difficulty_rules.dart` | `test/core/difficulty_rules_test.dart` | Mapped — dedicated difficulty policy and tests exist. |
| `shared/domain/FrenzyRules.kt` | `lib/core/game/guess_economy_rules.dart` | `test/core/guess_economy_rules_test.dart` | Mapped — streak/frenzy reward tiers have focused coverage. |
| `shared/domain/GuessEconomyDecisionRules.kt` | `lib/core/game/guess_economy_rules.dart`; guess orchestration in `lib/main.dart` | `test/core/guess_economy_rules_test.dart`; `test/core/game_engine_test.dart` | Partial — reward calculation is centralized; full decision ordering/source context still needs case-by-case comparison. |
| `shared/domain/GuessGameReducer.kt` | `lib/core/game/game_engine.dart` | `test/core/game_engine_test.dart` | Mapped — deterministic guess state transitions have a dedicated engine/test surface. |
| `shared/domain/GuessPenaltyRules.kt` | `lib/core/game/guess_economy_rules.dart`; miss settlement in `lib/main.dart` | `test/core/guess_economy_rules_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial — penalties and trait refunds are wired; compare all source penalty ordering and bounds. |
| `shared/domain/GuessRewardRules.kt` | `lib/core/game/guess_economy_rules.dart` | `test/core/guess_economy_rules_test.dart` | Mapped — base reward, streak, frenzy, critical, difficulty and multipliers are covered. |
| `shared/domain/MutatorRules.kt` | `lib/core/legacy/legacy_systems_engine.dart` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/legacy_systems_test.dart` | Mapped — four mutator multipliers stack to 300× and Hardcore doubles the range in tests. |
| `shared/domain/ProgressionRequirementRules.kt` | `lib/core/progression/progression_engine.dart`; `lib/worlds/world_boss_battle_engine.dart` | `test/core/progression_engine_test.dart`; `test/world_boss_battle_engine_test.dart` | Partial — progression/world requirements exist; every shared requirement and rejection boundary needs source comparison. |
| `shared/domain/ProgressionRewardRules.kt` | `lib/core/progression/progression_calculator.dart`; `lib/core/progression/progression_engine.dart` | `test/core/progression_calculator_test.dart`; `test/core/progression_engine_test.dart` | Partial — calculation and transactions exist; full source formula/overflow parity remains to verify. |
| `shared/domain/SaveProfileRules.kt` | `lib/data/saves/save_data.dart` (`profileIconIds`); `lib/data/saves/save_storage.dart`; `lib/saves/save_slots_page.dart` | `test/data/save_data_test.dart` | Mapped — the five canonical icon IDs are persisted and validated. Profile editor work in PR #72 is not merged into this snapshot and must not be counted as current-main behavior. |
| `shared/rules/GuessCoreState.kt` | `lib/core/game/game_engine.dart`; `lib/core/progression/progression_state.dart` | `test/core/game_engine_test.dart` | Partial — equivalent state is split across round and progression models; compare every field/invariant. |
| `shared/rules/GuessRateLimitRules.kt` | `lib/core/game/guess_rate_limit_policy.dart`; manual submission guard in `lib/main.dart` | `test/core/guess_rate_limit_policy_test.dart` | Mapped — monotonic 50 ms boundary, zero and negative clock origins, backward-clock rejection and accepted-timestamp behavior are covered; bot submissions bypass the manual limiter. |
| `shared/rules/GuessRules.kt` | `lib/core/game/game_engine.dart` | `test/core/game_engine_test.dart` | Mapped — range validation and low/high/correct outcomes are represented. |
| `shared/rules/GuessSourceContext.kt` | Bot identity passed through `_submitGuess(botId: ...)` in `lib/main.dart`; automation in `lib/core/automation/` | `test/core/automation/automation_policy_test.dart`; `test/core/game_engine_test.dart` | Partial — bot guesses are identified explicitly rather than through the source's pending thread-local marker; verify all stats/attempt paths. |
| `shared/rules/GuessStateRules.kt` | `lib/core/game/game_engine.dart`; `lib/data/saves/save_data.dart` | `test/core/game_engine_test.dart`; `test/data/save_data_test.dart` | Mapped — game state and persisted-state validation are represented; complete invariant parity remains a Stage 5 gate. |
| `shared/rules/GuessTransitionRules.kt` | `lib/core/game/game_engine.dart`; transition orchestration in `lib/main.dart` | `test/core/game_engine_test.dart` | Partial — round transition exists; compare source lifecycle ordering and bot/manual distinctions. |
| `shared/ui/JarrlyyUiComponents.kt` | `lib/design/expressive_widgets.dart` | `test/design/expressive_widgets_test.dart` | Partial — native Flutter design adapters replace shared Compose components; individual SDK/component behavior is tracked in the UI/SDK audit. |
| `shared/ui/SharedDeveloperSettingsScreen.kt` | `lib/dev/developer_settings_page.dart` | `test/widget_test.dart` | Partial — native developer settings destination exists; command and control parity remains open. |
| `shared/ui/SharedGameContracts.kt` | `lib/core/game/game_engine.dart`; `lib/core/progression/progression_state.dart`; `lib/main.dart` | `test/core/game_engine_test.dart`; `test/widget_test.dart` | Partial — contracts are represented by Dart state/actions, not a one-to-one shared interface. |
| `shared/ui/SharedGuessEntryPanel.kt` | `lib/home/game_dashboard_page.dart` | `test/widget_test.dart` | Partial — native guess-entry panel exists; visual/input parity remains in Stage 4. |
| `shared/ui/SharedGuessFeedbackCard.kt` | `lib/home/game_dashboard_page.dart` | `test/widget_test.dart` | Partial — feedback surface exists; all source states, semantics and animation need comparison. |
| `shared/ui/SharedGuessGameContent.kt` | `lib/home/game_dashboard_page.dart` | `test/widget_test.dart` | Partial — dashboard content is native Flutter; source layout and interaction audit remains open. |
| `shared/ui/SharedGuessGameScreen.kt` | `lib/home/game_dashboard_page.dart`; shell/navigation in `lib/main.dart` | `test/widget_test.dart` | Partial — native screen route exists; screen-level parity remains open. |
| `shared/ui/SharedGuessInputField.kt` | `lib/home/game_dashboard_page.dart`; `lib/design/expressive_widgets.dart` | `test/widget_test.dart`; `test/design/expressive_widgets_test.dart` | Partial — native input exists; keyboard, focus and feedback details require source comparison. |
| `shared/ui/SharedSaveSlotCard.kt` | `lib/saves/save_slots_page.dart` | `test/widget_test.dart` | Partial — native save-slot UI exists; source card states/actions and visual parity remain open. |

## 2. JVM + Android shared production sources (21)

| GTN1 source | GTN2 destination | Regression surface | Mapping |
|---|---|---|---|
| `domain/command/CommandAutocomplete.kt` | `lib/dev/developer_settings_page.dart`; command handling in `lib/main.dart` | `test/widget_test.dart` | Partial — command surface exists; source autocomplete ranking, tokenization and suggestions need explicit verification. |
| `domain/engine/ArcadeRewardRules.kt` | `lib/arcade/arcade_reward_rules.dart` | `test/arcade/arcade_reward_rules_test.dart` | Mapped — score/time caps and reward eligibility have dedicated tests. |
| `domain/engine/BigNumberProgressionRewardRules.kt` | `lib/core/progression/progression_calculator.dart`; `lib/core/numbers/big_number.dart` | `test/core/progression/progression_calculator_test.dart`; `test/core/big_number_test.dart` | Verified for the frozen source cases: Prestige uses exact integer-ratio floor plus integer square root (including values immediately below/above 4 and a large ratio); Ultra uses fixed-point high-precision logarithm and exact floor boundaries around 10^20. Save serialization is covered separately in `test/data/save_data_test.dart`. |
| `domain/engine/GameEngine.kt` | `lib/core/game/game_engine.dart`; adaptive next-target integration in `lib/main.dart` | `test/core/game_engine_test.dart`; `test/core/adaptive_target_generator_test.dart`; `test/widget_test.dart` | Partial — Android's adaptive proposal and Windows' uniform-random fallback match GTN1; full transition contract and source context remain under comparison. |
| `domain/engine/OfflineEarningsPolicy.kt` | `lib/core/automation/offline_earnings_policy.dart`; settlement orchestration in `lib/core/automation/offline_earnings_settlement.dart`, called by save restoration and resume in `lib/main.dart` | `test/core/automation/automation_policy_test.dart`; `test/core/automation/offline_earnings_settlement_test.dart`; `test/data/offline_earnings_persistence_test.dart` | Mapped — 500 Money/second, eight-hour cap, inactive/zero-timestamp handling, clock rollback, Money/lifetime-earnings persistence and repeat-settlement prevention across a SaveStorage reload are covered. |
| `domain/model/BigNumber.kt` | `lib/core/numbers/big_number.dart` | `test/core/big_number_test.dart` | Mapped — arbitrary precision Dart currency type exists with tests. |
| `domain/model/DailyRewardPolicy.kt` | Daily claim logic in `lib/core/legacy/legacy_systems_engine.dart`; UI in `lib/legacy/legacy_systems_page.dart` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/legacy_systems_test.dart` | Partial — daily reward state/claim path exists; full source streak/calendar/cap parity needs verification. |
| `domain/model/Difficulty.kt` | `lib/core/game/difficulty_rules.dart` | `test/core/difficulty_rules_test.dart` | Mapped — supported difficulty IDs and rule mapping exist. |
| `domain/model/GameState.kt` | `lib/core/progression/progression_state.dart`; `lib/core/legacy/legacy_systems_state.dart`; `lib/data/saves/save_data.dart` | `test/data/save_data_test.dart`; `test/core/progression_engine_test.dart` | Partial — save/progression state is split into typed Dart models; compare every source field and migration behavior. |
| `domain/model/LiveOpsClaimPolicy.kt` | `lib/core/legacy/live_ops_claim_policy.dart`; `LegacySystemsEngine.claimLiveOpsReward` | `test/core/legacy/live_ops_claim_policy_test.dart`; `test/data/save_data_test.dart` | Verified — bounded definition/progression validation, per-event claim cap, Nebula/lifetime-earnings settlement, overflow rejection and permanent boost cap are ported. The player-facing page calls this trusted transaction and persists accepted claims. |
| `domain/model/TraitProfile.kt` | `lib/core/legacy/adaptive_trait_profile.dart`; `lib/core/legacy/invisible_trait_engine.dart` | `test/core/legacy/invisible_trait_engine_test.dart` | Partial — adaptive profile exists; compare serialized fields, observation updates and source migration. |
| `shared/domain/AntiTimeTravelRules.kt` | `lib/core/automation/clock_rollback_policy.dart` | `test/core/automation/automation_policy_test.dart` | Mapped — clock rollback decision and pause policy have focused tests. |
| `shared/domain/CreativeModeRuntime.kt` | `lib/core/creative/creative_mode.dart` | `test/core/creative/creative_mode_test.dart` | Mapped — isolated run lifecycle, guess outcomes, validation and persistence hooks exist. |
| `shared/domain/CreativeModeSave.kt` | `lib/core/creative/creative_mode.dart`; `lib/data/saves/save_data.dart` | `test/core/creative/creative_mode_test.dart`; `test/data/save_data_test.dart` | Mapped — schema migration, validation and per-save-slot storage are represented. |
| `shared/domain/InvisibleTraitEngine.kt` | `lib/core/legacy/invisible_trait_engine.dart`; `lib/core/legacy/adaptive_trait_profile.dart` | `test/core/legacy/invisible_trait_engine_test.dart` | Partial — adaptive helper logic exists; compare every source threshold, cooldown, ordering and persistence effect. |
| `shared/domain/SaveStateRules.kt` | `lib/data/saves/save_data.dart`; `lib/data/saves/save_storage.dart`; progression validation | `test/data/save_data_test.dart` | Partial — save validation exists, but source state has additional counters/maps that require field-by-field validation review. |
| `shared/domain/TraitGameplayRules.kt` | `lib/core/legacy/legacy_systems_engine.dart`; trait/reward integration in `lib/main.dart` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/core/guess_economy_rules_test.dart` | Partial — trait modifiers are wired into manual guesses; compare complete source effect allowlist, adaptive decisions and non-manual guess paths. |
| `shared/engine/NativeGameplayOptimizer.kt` | `lib/core/game/adaptive_target_generator.dart`; Android integration in `lib/main.dart`; Windows keeps the uniform random fallback | `test/core/adaptive_target_generator_test.dart`; `test/core/game_engine_test.dart` | Behavior mapped — the 64-bit C++ mix/salt/pressure algorithm is reimplemented in Dart with exact reference vectors and a 128-case checksum; Android uses it and Windows preserves GTN1's non-native random fallback. A JNI bridge is unnecessary for equivalent behavior. |
| `shared/seasonal/SeasonalThemeCalendar.kt` | `lib/core/seasonal/seasonal_theme_calendar.dart`; preview integration in `lib/dev/seasonal_theme_simulator_card.dart` | `test/core/seasonal_theme_calendar_test.dart`; `test/dev/developer_settings_page_test.dart` | Verified — recurring and cross-year windows, region restrictions, back-to-school, Lunar New Year calendar/custom windows, Gregorian Easter, opt-in winter, priority and exclusive end boundaries are ported and tested. This calendar is preview/presentation-only and is deliberately separate from four-season trait eligibility. |
| `shared/ui/ArcadeCanvasGame.kt` | `lib/arcade/arcade_page.dart` | `test/arcade/arcade_page_test.dart` | Partial — native minigame page exists; canvas/game-by-game behavior is not yet proven equivalent. |
| `shared/ui/SeasonalThemeSimulatorCard.kt` | `lib/dev/seasonal_theme_simulator_card.dart`, embedded in `lib/dev/developer_settings_page.dart` | `test/dev/developer_settings_page_test.dart`; `test/core/seasonal_theme_calendar_test.dart` | Verified — preview date input, Today, all ten source quick presets, active-theme list and primary label are implemented. No save, reward or trait state is mutated. |

## 3. JVM-only production sources (2)

| GTN1 source | GTN2 destination | Regression surface | Mapping |
|---|---|---|---|
| `desktop/economy/DesktopEconomyTransactions.kt` | `lib/core/legacy/legacy_systems_engine.dart`; `lib/shop/upgrade_batch_policy.dart`; transaction orchestration in `lib/main.dart` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/core/guess_economy_rules_test.dart`; `test/shop/upgrade_shop_test.dart`; `test/shop/upgrade_shop_page_test.dart`; `test/world_boss_battle_engine_test.dart` | Partial — fixed/maximum Money upgrade purchases now match GTN1's largest-affordable-prefix transaction and UI estimate. Remaining desktop transaction invariants and relic/world settlement still require comparison. |
| `desktop/persistence/DesktopSaveStore.kt` | `lib/data/saves/save_storage.dart`; `lib/data/saves/save_data.dart` | `test/data/save_data_test.dart` | Partial — slot persistence and recovery exist; source file locking/atomic replacement and failure semantics need platform verification. |

## 4. Shared KMP regression tests (30)

The source test inventory is mapped below. These rows identify the closest GTN2 regression surface; a missing or partial destination is not treated as proof of parity.

| GTN1 test | GTN2 regression surface | Mapping |
|---|---|---|
| `commonTest/.../ChallengeRewardRulesTest.kt` | `test/arcade/arcade_reward_rules_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial — arcade policy is tested; challenge-specific claim cases need coverage. |
| `commonTest/.../CriticalChanceRulesTest.kt` | `test/core/guess_economy_rules_test.dart` | Mapped |
| `commonTest/.../DifficultyRulesTest.kt` | `test/core/difficulty_rules_test.dart` | Mapped |
| `commonTest/.../DomainRulesTest.kt` | `test/core/game_engine_test.dart`; `test/core/progression_engine_test.dart` | Partial — source's combined domain invariants need a dedicated coverage review. |
| `commonTest/.../FrenzyRulesTest.kt` | `test/core/guess_economy_rules_test.dart` | Mapped |
| `commonTest/.../GuessEconomyDecisionRulesTest.kt` | `test/core/guess_economy_rules_test.dart`; `test/core/game_engine_test.dart` | Partial |
| `commonTest/.../GuessGameReducerTest.kt` | `test/core/game_engine_test.dart` | Mapped |
| `commonTest/.../GuessPenaltyRulesTest.kt` | `test/core/guess_economy_rules_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial |
| `commonTest/.../GuessRewardRulesTest.kt` | `test/core/guess_economy_rules_test.dart` | Mapped |
| `commonTest/.../MutatorRulesTest.kt` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/legacy_systems_test.dart` | Mapped |
| `commonTest/.../ProgressionRequirementRulesTest.kt` | `test/core/progression_engine_test.dart`; `test/world_boss_battle_engine_test.dart` | Partial |
| `commonTest/.../ProgressionRewardRulesTest.kt` | `test/core/progression_calculator_test.dart`; `test/core/progression_engine_test.dart` | Partial |
| `commonTest/.../GuessCoreStateTest.kt` | `test/core/game_engine_test.dart` | Partial |
| `commonTest/.../GuessRateLimitRulesTest.kt` | `test/core/guess_rate_limit_policy_test.dart` | Mapped — first submission, zero/negative monotonic origins, 49,999/50,000 µs boundary, backwards time and non-positive interval cases are covered. |
| `commonTest/.../GuessRulesTest.kt` | `test/core/game_engine_test.dart` | Mapped |
| `commonTest/.../GuessStateRulesTest.kt` | `test/core/game_engine_test.dart`; `test/data/save_data_test.dart` | Partial |
| `commonTest/.../GuessTransitionRulesTest.kt` | `test/core/game_engine_test.dart` | Partial |
| `commonTest/.../SharedGameContractsTest.kt` | `test/core/game_engine_test.dart`; `test/widget_test.dart` | Partial |
| `jvmTest/.../DesktopEconomyTransactionsTest.kt` | `test/shop/upgrade_shop_test.dart`; `test/shop/upgrade_shop_page_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial — source bulk Money upgrade cost, largest-affordable-prefix and multiplier cases are mirrored; remaining transaction cases are still open. |
| `jvmTest/.../RelicSetBonusGameplayTest.kt` | `test/core/guess_economy_rules_test.dart`; `test/core/legacy/legacy_systems_engine_test.dart` | Partial — inspect whether every set composition and proc case is covered before marking verified. |
| `jvmTest/.../DesktopSaveStoreTest.kt` | `test/data/save_data_test.dart` | Partial — persistence exists; desktop atomic-write/locking failure cases are not proven. |
| `jvmTest/.../ArcadeRewardRulesTest.kt` | `test/arcade/arcade_reward_rules_test.dart` | Mapped |
| `jvmTest/.../AutoClickerTimingTest.kt` | `test/core/automation/automation_policy_test.dart` | Partial — policy tests exist; timing/clock scheduling parity needs source-case review. |
| `jvmTest/.../BigNumberProgressionRewardRulesTest.kt` | `test/core/progression_calculator_test.dart`; `test/core/big_number_test.dart` | Verified — source-backed Prestige near-square and Ultra logarithm floor-boundary cases are mirrored in the Dart regression suite. |
| `jvmTest/.../OfflineEarningsPolicyTest.kt` | `test/core/automation/automation_policy_test.dart` | Mapped |
| `jvmTest/.../PermanentUpgradeEffectsTest.kt` | `test/core/guess_economy_rules_test.dart`; `test/core/progression_engine_test.dart` | Partial — some compound effects covered; every upgrade effect and reset boundary needs verification. |
| `jvmTest/.../DailyRewardPolicyTest.kt` | `test/core/legacy/legacy_systems_engine_test.dart`; `test/legacy_systems_test.dart` | Partial — daily claim flow exists; exact streak/calendar/claim-cap cases need comparison. |
| `jvmTest/.../AntiTimeTravelRulesTest.kt` | `test/core/automation/automation_policy_test.dart` | Mapped |
| `jvmTest/.../SaveStateRulesTest.kt` | `test/data/save_data_test.dart` | Partial — Dart validation exists; compare all source fields and invalid-state cases. |
| `jvmTest/.../SeasonalThemeCalendarTest.kt` | `test/core/seasonal_theme_calendar_test.dart` | Verified — the source boundary, regional, Lunar New Year, Easter and winter cases are mirrored in focused Dart tests. |

## 5. Mapping summary and follow-up

- **Inventory reconciled:** 50/50 shared production Kotlin files and 30/30 shared Kotlin tests at the pinned source commit.
- **Mapped destinations:** all 50 production files have an identified Dart destination or an explicit gap; all 30 tests have an identified regression surface or explicit missing coverage.
- **Confirmed gaps requiring parity work:** signed remote Lua LiveOps bundle refresh/cache/anti-rollback; source-specific challenge claim settlement/coverage; remaining end-to-end Money/Nebula settlement and rounding cases. `NativeGameplayOptimizer` gameplay behavior, the seasonal calendar/simulator and the shared monotonic guess-rate policy are now mapped to their Dart implementations and regression tests.
- **Partial areas requiring behavioral comparison:** progression requirements/rewards, trait activation/gameplay, game state invariants, source bot context, daily rewards, remaining Money/Nebula transaction and rounding semantics, desktop save semantics, UI component interactions.
- **Do not infer completion from this map.** The Stage 2/3/4/5 checklists remain authoritative for implementing and verifying those behaviors. The source map only closes the inventory-to-destination discovery task.

**Next Stage 1 item:** map the 55 Windows desktop production Kotlin files and 29 desktop tests to the existing Flutter Windows implementation, including explicit desktop-only behavior.


| GTN1 source | GTN2 implementation | Evidence | Status |
|---|---|---|---|
| `app/src/main/java/com/jarrlyyy/guessthenumber/data/repository/FeatureFlagRepository.kt`; `app/src/main/assets/game/feature_flags.json` | `lib/core/liveops/live_ops_repository.dart`; `assets/game/feature_flags.json` | `test/core/liveops/live_ops_repository_test.dart` | Verified — known flags use explicit defaults, schema 1 is validated and invalid feature configuration fails closed. |
| `app/src/main/java/com/jarrlyyy/guessthenumber/data/repository/LiveOpsRepository.kt`; `app/src/main/assets/game/liveops_manifest.json` | `lib/core/liveops/live_ops_repository.dart`; `assets/game/liveops_manifest.json` | `test/core/liveops/live_ops_repository_test.dart` | Partial — offline JSON manifest validation, date-derived status and bundled fallback are ported; verified cached Lua manifest priority is not yet implemented. |
| `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/LiveOpsScreen.kt`; `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopLiveOpsScreen.kt` | `lib/liveops/live_ops_page.dart`; More menu destination in `lib/home/game_dashboard_page.dart` | `test/liveops/live_ops_page_test.dart` | Partial — event cards, status, requirements, claim counts, permanent bonus level and claim callback are implemented; remote refresh and complete localization/visual comparison remain open. |
| `app/src/main/java/com/jarrlyyy/guessthenumber/scripting/LuaLiveOpsRepository.kt`; `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopLuaLiveOpsRepository.kt` | No equivalent verified remote signed-bundle cache/refresh yet. | GTN1 `LuaLiveOpsRepositoryTest.kt`; GTN2 `test/core/liveops/live_ops_repository_test.dart` covers offline JSON fallback only. | Gap — HTTPS signed bundle verification, hash checks, atomic activation, anti-rollback and cached Lua event-manifest priority remain to be ported. |
