# GTN2 Finite Parity Plan and Completion Checklist

**Purpose:** Finish the Flutter port of GTN1 without turning parity into an expanding, indefinite project.

## Fixed scope

- **Source of truth:** `ne0gl1tch20/GuessTheNumber`, pinned to the exact commit recorded by GTN2's asset-sync configuration. That commit is the feature boundary.
- **Target:** GTN2's existing Android and Windows targets.
- **Included:** Features, screens, game rules, content, settings, save behavior and platform behavior that exist in the pinned GTN1 source and apply to the target platform.
- **Not included:** New features, redesigns beyond reproducing GTN1, speculative improvements, unrelated refactors, extra platforms, or features added to GTN1 after the pinned commit.
- **Code completion criterion:** Every applicable production source file in the pinned GTN1 inventory must have its behavior implemented in GTN2 or be explicitly marked not applicable with a source-backed reason. Flutter/Dart is the native implementation; this does not mean copying Kotlin syntax into Dart. A destination filename or matching data asset alone is not proof of parity. No unexplained production-source gap may remain at closure.
- **UI completion criterion:** GTN2 must reproduce the player-facing UI and interactions from both GTN1's production Kotlin screens and its HTML/CSS/JS Web Play shell. Web Play is a visual/behavioral source, not a requirement to ship a WebView. Reimplement its screens, layout, typography, colors, spacing, controls, overlays, motion and responsive behavior natively in Flutter.
- **Design integration criterion:** Blend the reproduced GTN1 visual identity and screen behavior with Material 3 Expressive components, motion and adaptive behavior. Material 3 Expressive is the native design-system layer, not a reason to replace or simplify GTN1-specific UI. The result must read as one coherent GTN2 app rather than a generic Material template or disconnected copied screens.
- **Finite-work rule:** Work only from the frozen inventory and recorded gaps. Verify each item once against its GTN1 source and GTN2 evidence; reopen a verified item only for a reproducible mismatch. Do not create repeated fix/recheck loops or add newly imagined parity requirements after the inventory is frozen.
- **Inventory boundary:** The pinned GTN1 repository contains 214 production Kotlin files and 111 Kotlin test files across all modules: app 107 production + 49 JVM tests + 3 Android instrumentation tests; shared KMP 50 production + 30 tests; Windows desktop 55 production + 29 tests; build logic 2 production files. The earlier 107/49 figures covered only the Android app module. The inventory also records one Web Play HTML shell, 5 JavaScript modules, 1 stylesheet, 24 Jarrlyy UI SDK files, 4 shipped core Lua scripts, 17 game JSON catalogs, 320 trait definitions and 23 locale files. The 24-file SDK count includes demo and TypeScript support files; only runtime-used files need behavioral mapping. See `docs/GTN1_SOURCE_INVENTORY.json` for exact paths and counting rules.

## Rules that prevent scope creep

1. Every task must point to a file, screen, behavior, catalog entry or platform component in the pinned GTN1 source inventory.
2. A task is complete when its GTN1 behavior is implemented in GTN2 and has an appropriate test or documented platform verification. Do not require identical internal architecture.
3. Do not reopen a checked item unless a reproducible regression or newly found mismatch in that same GTN1 behavior is demonstrated.
4. Do not add polish, optional enhancements or speculative edge cases to the parity queue.
5. If GTN1 has behavior that cannot apply to Android or Windows, record it as **not applicable** with a short reason. Do not leave it open forever.
6. If a source behavior is intentionally unsupported in GTN2, it is not parity. Either implement it or record a concrete, owner-approved exclusion before release.
7. Once the fixed inventory passes the exit gate, parity work is closed. Later work is normal maintenance, not another parity phase.

## Six-stage delivery checklist

### Stage 1 — Freeze and map the source (one-time)

- [x] Record the exact GTN1 source commit used by the port (`fe9cf567169e19059e0330d08769fe454336ef94`; verified against `scripts/sync_gtn1_assets.sh`, `docs/GTN1_SOURCE_INVENTORY.json`, and both CI workflows).
- [x] Verify the complete pinned repository inventory: 214 production Kotlin files and 111 Kotlin tests across app, shared KMP, desktopApp and buildSrc.
- [x] Map the Android app module's 107/107 production Kotlin files. `docs/GTN1_TO_GTN2_SOURCE_MAP.md` records 66 mapped/partial, five N/A and 36 explicit gaps, and was refreshed against current `main`; gaps remain behavioral parity work, not unmapped inventory.
- [x] Map the 50 shared KMP production files and 30 shared tests to Dart destinations/regression surfaces. `docs/GTN1_SHARED_KMP_TO_GTN2_SOURCE_MAP.md` maps every source/test and explicitly records partial ports and gaps; mapping completion does not close behavioral parity items.
- [x] Map the 55 Windows desktop production files and 29 desktop tests to the Flutter Windows implementation. `docs/GTN1_WINDOWS_DESKTOP_TO_GTN2_SOURCE_MAP.md` maps every source/test and records desktop-only gaps, N/A WebView transport, generated Windows runner behavior and updater coverage; mapping completion does not close behavioral parity items.
- [x] Review the two buildSrc Kotlin files and record build-only applicability/CI parity. `docs/GTN1_BUILDSRC_TO_GTN2_CI_MAP.md` maps logo generation to the Windows/Android icon script and identifies the remaining embedded APK `assets/info.txt` build-metadata gap.
- [x] Map the single Web Play HTML shell, its actual route/screen renderers and the five JavaScript modules to native Flutter destinations/behaviors. `docs/GTN1_WEB_PLAY_TO_GTN2_FLUTTER_MAP.md` inventories all 22 roots, special route IDs and all five modules, with partial ports and the trait JavaScript UI runtime gap explicitly recorded; mapping completion does not close screen/module parity.
- [x] Map all 24 Jarrlyy UI SDK files to Flutter components/events or explicit demo/build-only N/A. `docs/GTN1_JARRLYY_UI_SDK_TO_GTN2_FLUTTER_MAP.md` maps the runtime APIs, CSS, host/event contracts, TypeScript sources and demo files; remaining player-facing interaction/visual gaps are retained in Stages 3–4.
- [x] Map all 17 catalogs, 320 trait IDs, four Lua scripts and 23 locales from the source manifest to GTN2 runtime destinations. `docs/GTN1_CATALOGS_TRAITS_LUA_LOCALES_TO_GTN2_MAP.md` records every catalog/runtime gap, exact 320-ID mapping, Lua integration state and locale match. `docs/GTN1_TRAIT_ID_MAP.json` contains all 320 ID pairs. `scripts/verify_gtn1_assets.py` now enforces the complete catalog, locale, Lua and trait-ID inventories in CI.
- [x] Freeze this inventory. The fixed source inventory is now mapped across app, shared KMP, desktop, build logic, Web Play, SDK, catalogs, traits, Lua and locales. No new feature categories may be added after this stage.

**Exit:** Every item in the fixed source inventory has a destination and an owner/status. No unexplained source item remains.

### Stage 2 — Core gameplay and progression

- [ ] Guess flow, number generation, validation, round lifecycle and difficulty rules.
  - [x] Port GTN1's monotonic 50 ms manual-submission rate limit; automated bot submissions bypass it. Covered by `test/core/guess_rate_limit_policy_test.dart`.
  - [x] Port and verify GTN1's bounded adaptive next-target algorithm: 64-bit mixing, difficulty salt, streak/attempt pressure and range clamping. Its 128-case reference checksum matches GTN1 in `test/core/adaptive_target_generator_test.dart`; Android uses the adaptive Dart proposal, while Windows retains GTN1's uniform-random fallback. The JNI layer is a platform optimization, not a separate gameplay behavior.
  - [ ] Compare the complete guess-state transition, invalid-range handling, source context and round lifecycle against GTN1.
- [ ] Economy: Money, Nebula, rewards, multipliers, penalties, caps and big-number arithmetic.
  - [x] Verify GTN1 reward constants and formulas: 100 Money per range unit, 10 minimum, +10% per prior streak, five-guess frenzy tiers capped at 5×, 5× critical, +25% per reward upgrade level and 1.5× Prestige talent reward. Evidence: `lib/core/game/guess_economy_rules.dart`, `test/core/guess_economy_rules_test.dart`, GTN1 `GuessRewardRules.kt` and `FrenzyRules.kt`.
  - [x] Verify difficulty reward and miss-penalty rates (Classic 1×/0%, Hard 1.5×/2%, Extreme 2.5×/5%) and valid configured range behavior. Evidence: `lib/core/game/difficulty_rules.dart`, `test/core/difficulty_rules_test.dart`, GTN1 `DifficultyRules.kt`.
  - [x] Verify mutator identifiers, invalid-ID filtering, reward stacking (2×/3×/5×/10×), Hardcore range doubling and Tax 5% penalty. Evidence: `lib/core/legacy/legacy_systems_engine.dart`, `test/core/legacy/legacy_systems_engine_test.dart`, GTN1 `MutatorRules.kt` and `GuessPenaltyRules.kt`.
  - [x] Verify permanent Prestige/Ultra Money boost compounding and BigNumber reward minimum/order. Evidence: `GuessEconomyRules.moneyEarningMultiplier`, `correctGuessReward` and `test/core/guess_economy_rules_test.dart`.
  - [x] Port GTN1 offline earnings settlement into one shared path used by save restoration and app resume: 500 Money/second, eight-hour cap, inactive/zero-timestamp handling, clock rollback pause and timestamp advancement. `lib/core/automation/offline_earnings_settlement.dart` and `test/core/automation/offline_earnings_settlement_test.dart` cover payout into Money and lifetime earnings, cap behavior, rollback and repeat-settlement prevention after the updated timestamp is persisted.
  - [x] Verify offline payout persistence through `SaveStorage` restart: Money, lifetime Money earned and the advanced timestamp survive reload, and the same elapsed interval cannot pay twice. Evidence: `test/data/offline_earnings_persistence_test.dart`.
  - [ ] Finish the remaining Money/Nebula transaction, rounding, cap and save-persistence comparison against GTN1.
  - [x] Mirror GTN1's Prestige near-square precision regression: ratios immediately below and above four, plus a large integer ratio, preserve exact integer-division and floor-square-root behavior. Evidence: GTN1 `BigNumberProgressionRewardRulesTest.kt`; GTN2 `test/core/progression/progression_calculator_test.dart`.
  - [x] Match GTN1's high-precision Ultra reward logarithm and floor boundaries without binary floating-point rounding. Evidence: GTN1 `BigNumberProgressionRewardRules.kt` and `BigNumberProgressionRewardRulesTest.kt`; GTN2 `lib/core/progression/progression_calculator.dart` and `test/core/progression/progression_calculator_test.dart` cover 10^10−1 → 999, 10^20−1 → 1999 and 10^20 → 2000. CI: Validate run `43541945539`.
  - [x] Verify huge Money, Prestige, Ultra, Nebula, lifetime currency totals and permanent upgrade levels round-trip through GTN2 SaveData JSON as plain-decimal strings, matching GTN1's `BigNumberSerializer.toPlainString()`. Evidence: `test/data/save_data_test.dart`. CI: Validate run `43541945539`.
  - [x] Port GTN1's bounded LiveOps claim transaction: validates event definitions and progression gates, enforces per-event claim caps, rejects corrupted/overflowing lifetime Nebula statistics, grants Nebula and lifetime earnings atomically, and caps permanent event boosts at 25. Covered by `test/core/legacy/live_ops_claim_policy_test.dart` and SaveData JSON round-trip coverage.
  - [x] Port the offline LiveOps catalog and player-facing event flow: schema/ID/content/date/reward validation, feature-flag defaults and gating, event status derived from UTC start/end windows, bundled fallback, claim eligibility/progress and native claim UI. Evidence: `lib/core/liveops/live_ops_repository.dart`, `lib/liveops/live_ops_page.dart`, `test/core/liveops/live_ops_repository_test.dart`, `test/liveops/live_ops_page_test.dart`.
  - [ ] Port the signed remote LiveOps/Lua bundle lifecycle: HTTPS-only fetch, RSA signature verification, script SHA-256 verification, version/app/API compatibility, staging and atomic activation, anti-rollback high-water mark, cached integrity verification and rollback. Keep the bundled offline manifest and scripts usable when remote configuration is absent. GTN1 sources: `app/src/main/java/com/jarrlyyy/guessthenumber/scripting/LuaLiveOpsRepository.kt`, `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopLuaLiveOpsRepository.kt`; GTN1 bundle contract: `docs/LIVEOPS_BUNDLE_FORMAT.md`.
- [ ] Upgrades, prestige, Ultra progression and their reset/carry-over rules.
  - [x] Match GTN1's 1/10/100/MAX Money-upgrade batch policy: calculate each exact BigNumber level cost, buy the largest affordable prefix, clamp to remaining max level and return zero when no level is affordable. The shop preview and atomic purchase callback share this count. Evidence: `lib/shop/upgrade_batch_policy.dart`, `lib/shop/upgrade_shop_page.dart`, `test/shop/upgrade_shop_test.dart`, `test/shop/upgrade_shop_page_test.dart`; GTN1 `DesktopEconomyTransactions.upgradeBatch` and `bulkMoneyUpgradeChargesExactCombinedCost`, `maxUpgradeBuysOnlyLargestAffordablePrefix`, `fixedBulkPurchaseBuysLargestAffordablePrefix`.
- [ ] Traits, talents, mutators and relics, including actual gameplay effects.
- [ ] Worlds, bosses, battles, mastery, secrets, codex and claim-once rewards.
  - [ ] World unlock requirements and migration behavior.
  - [ ] Boss battle eligibility, lifecycle, phases, hit/miss rules and defeat.
  - [ ] Boss rewards, multipliers, relic/Codex unlocks and mastery.
  - [ ] Endless Rift scaling, rewards, rotation and best-tier persistence.
  - [ ] World selection, secret discovery and restoration after save/load.
- [ ] Home Base/Sanctuary, daily and weekly rewards, quests, chests and minigames.
- [ ] Lucky Stake and achievements, including unlock conditions and reward settlement.
- [ ] Automation, bot behavior, offline earnings and clock handling.

**Exit:** Every gameplay system present in the pinned GTN1 source has a working Dart implementation and source-backed tests for its rules and transactions.

### Stage 3 — Secondary systems and platform services

- [ ] Music library, playback, queue, playlists, seek, shuffle and repeat.
- [ ] GTN1 background audio and media-control behavior where supported by Android/Windows.
- [ ] Jarrlyy DSP behavior used by GTN1.
- [ ] Lua sandbox, exposed APIs, permissions, limits and all four shipped scripts.
- [ ] Notifications, scheduled work, update checks and lifecycle recovery.
- [ ] Android updater/install behavior and Windows updater/replacement/rollback behavior.
- [ ] About, changelog, licenses and source attribution.

**Exit:** Every applicable GTN1 secondary system has its real behavior implemented. Platform-only behavior is verified on its target platform or marked not applicable with a reason.

### Stage 4 — Screens, content and visual behavior

**Required visual acceptance for every production screen/route (Kotlin and Web Play):**
- [ ] Capture/inspect the pinned GTN1 source screen and compare GTN2 at the same agreed phone and desktop viewport sizes.
- [ ] Match the source information hierarchy, layout proportions, typography, color roles, spacing, iconography, component density and visible labels. Preserve source-specific content rather than substituting generic cards or placeholder copy.
- [ ] Reproduce every source control and state: default, selected, disabled, locked, loading, error, empty, confirmation/dialog, success/feedback and navigation outcomes where the source defines them.
- [ ] Port Web Play CSS/JS interaction behavior to native Flutter widgets and Dart state. No WebView is required, but no player-facing Web Play behavior may be dropped merely because its original implementation used HTML/JS.
- [ ] Apply Material 3 Expressive through the app theme, adaptive components and motion while retaining GTN1's recognizable visual language. Verify typography, shape, color, elevation, transitions, focus/semantics and reduced-motion behavior as a unified system.
- [ ] Record one source reference and one GTN2 test or visual/platform evidence reference per completed screen group. A screen is not complete just because its route exists.

- [ ] Every screen/route rendered by the single Web Play HTML shell has a corresponding native Flutter destination (the pinned tree does not contain 22 separate HTML screen roots).
- [ ] Each screen's primary controls, dialogs, navigation and state transitions work.
- [ ] The fixed screen set is compared against GTN1 at agreed mobile and desktop viewport sizes.
- [x] Port the preview-only seasonal calendar and Developer Settings simulator: recurring/cross-year windows, Philippines-only events, configured back-to-school, Lunar New Year windows, Gregorian Easter, opt-in winter, exact start-inclusive/end-exclusive behavior, quick presets and invalid-date feedback. The simulator never changes saves, rewards or trait eligibility. Evidence: GTN1 `SeasonalThemeCalendar.kt`, `SeasonalThemeCalendarTest.kt`, `SeasonalThemeSimulatorCard.kt`; GTN2 `lib/core/seasonal/seasonal_theme_calendar.dart`, `lib/dev/seasonal_theme_simulator_card.dart`, `test/core/seasonal_theme_calendar_test.dart`, `test/dev/developer_settings_page_test.dart`.
- [x] Step 1 interactive world map acceptance: four GTN1 nodes, exact source coordinates and route graph, locked/unlocked/defeated/selected/active-battle states, secret thresholds and discovered state, pan/zoom/fit/reset, Endless Rift selection lock and external active-world synchronization. Evidence: GTN1 `WorldMapScreen.kt` and `DesktopWorldMapContent.kt`; GTN2 `lib/worlds/world_map_page.dart`, `lib/worlds/world_boss_catalog.dart`, `test/world_boss_test.dart` and `test/world_map_page_test.dart`. Actions route through `_worldBossAction` to `WorldBossBattleEngine`/`LegacySystemsEngine` and persist accepted changes. Validation: test suite passed in run `43443383175`; Android and Windows debug builds passed in run `43441814113`. Real-device play-test remains in Stage 6.
- [ ] All 17 catalogs load from canonical bundled data with valid references.
- [ ] All 320 trait IDs and their definitions/rules are available to the runtime.
- [ ] All 23 locale files load; key flows have no missing-string or layout failures.
- [ ] Required fonts, images, icons and audio assets resolve offline.
- [ ] Labels and user-visible terminology match GTN1 where the original exposes them.

**Exit:** Every Kotlin and Web Play production screen/route in the frozen inventory is present, functional and visually compared at the fixed viewports; source-defined interactions and states are represented; the GTN1 visual identity is coherently integrated with Material 3 Expressive. No screen, catalog, locale or asset is missing or represented by a placeholder. No open-ended pixel polishing is allowed after these acceptance checks pass.

### Stage 5 — Saves, compatibility and reliability

- [ ] Save slots, active-slot selection, serialization and restart persistence work.
- [ ] Import/export, reset, validation, corruption recovery and safe failure paths work.
- [ ] Historical GTN1 save formats identified in the source are migrated without losing supported player data.
- [ ] Currency/progression changes are validated, atomic and persisted.
- [ ] Pause, resume, process death, app restart and supported background tasks are handled.
- [ ] Offline-first gameplay works without a network connection.
- [ ] No mock, placeholder or fake implementation remains in the frozen feature set.

**Exit:** Existing GTN1 player data and new GTN2 progress survive the supported save and lifecycle scenarios without silent loss or duplicate rewards.

### Stage 6 — Final verification and delivery

- [ ] Dart formatting passes.
- [ ] Flutter analysis passes.
- [ ] Full automated test suite passes.
- [ ] Source-backed parity tests pass for all migrated game systems.
- [ ] Android debug build succeeds from merged `main`.
- [ ] Windows debug build succeeds from merged `main`.
- [ ] Android runtime smoke test passes on a real device or emulator.
- [ ] Windows runtime smoke test passes on a real Windows environment.
- [ ] Primary journeys pass on both platforms: fresh start, play, earn/spend, progression, save, restart, settings and secondary systems.
- [ ] Platform-specific updater, audio, notification and permission flows are tested where applicable.
- [ ] Final source inventory has no unchecked applicable item and every not-applicable item has a reason.
- [ ] Build the final APK from the verified merged `main` commit, download the actual artifact and record its SHA-256.

**Exit:** All six stages are complete. The final APK and Windows build correspond to the verified merged source. Publish the final parity report and close parity.

## What happens after completion

Parity is finished when Stage 6 passes. Only reproducible defects in the delivered GTN2 build are maintenance bugs. New features, optional improvements and later GTN1 additions require a separate project/version decision; they do not reopen this checklist.

## Progress tracking

Keep one status per checklist item: **Not started**, **In progress**, **Verified**, or **Not applicable**. A verified item records the GTN1 source reference and the GTN2 test or platform evidence. Do not create a new checklist section for each newly noticed idea.
