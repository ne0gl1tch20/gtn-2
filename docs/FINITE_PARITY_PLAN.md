# GTN2 Finite Parity Plan and Completion Checklist

**Purpose:** Finish the Flutter port of GTN1 without turning parity into an expanding, indefinite project.

## MOST IMPORTANT NOTE — THE GTN2 PRODUCT STANDARD

**GTN2 must be a fully functioning game and a 100% faithful port of the pinned GTN1 experience, with one deliberate twist: our original GTN1 identity is blended coherently with Material 3 Expressive.** This means matching GTN1's actual gameplay, systems, progression, content, screens, interactions, visual language and platform behavior—not merely creating routes, placeholder screens or partial lookalikes. Material 3 Expressive enhances the presentation and interaction design; it must never replace, simplify, omit or distort GTN1 behavior or recognizable identity. The finished result must feel like our game, faithfully carried into Flutter and thoughtfully integrated with Material 3. A feature counts as complete only when it works end-to-end in the running app and is verified against its GTN1 source. A successful build alone is not proof that the game is finished.

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

**User-reported screen-parity failures now confirmed by source inspection (all remain open):**
- [ ] **Developer Settings:** Compare and reproduce the pinned GTN1 developer console hierarchy, sections, controls and diagnostics in Flutter. Sources: GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/DevSettingsScreen.kt`; destination: GTN2 `lib/dev/developer_settings_page.dart`. Existing functionality is not proof of visual parity.
- [ ] **Background Music:** Restore the dedicated GTN1 music-player screen structure and interactions (artwork/player card, seek/progress, transport controls, shuffle/repeat, library, queue and playlists). Source: GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MusicPlayerScreen.kt`; GTN2 now renders a dedicated player-page shell from `LegacySystemsPage(view: LegacySystemsView.music)` (Batch 1, commits `392b74f`, `5cfe029`, `936e658`); artwork/metadata fidelity, media-service lifecycle, full control-state parity and reported blank-route runtime verification remain open.
- [ ] **Settings:** Compare GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SettingsScreen.kt` with GTN2 `lib/settings/settings_page.dart`. The current Flutter implementation now includes the source-facing section order, Theme Colors live preview, shared saturation/value + hue + hex color picker, conditional notification categories and category descriptions, disabled SFX volume when sound is off, and an Android `POST_NOTIFICATIONS` permission request/result bridge generated by `scripts/configure_android_updater.py`. The bridge is not a native source file in the repository because the Android project is generated during CI; the script rewrites the generated `MainActivity.kt`. Widget tests cover the source hierarchy, preview/color controls, permission grant/denial and category descriptions. Still open: exact localized copy/labels, Android runtime permission prompt behavior, actual notification scheduling/delivery, settings persistence/reload and paired Android/Windows screenshots. Do not repeat the older claim that the preview, color picker or permission bridge is absent.
- [ ] **About:** Reproduce the dedicated GTN1 About screen, including version/update channel, update checking and installation states, diagnostics, description, online links and source/license list. Source: GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/AboutScreen.kt`; destination: GTN2 About section in `lib/legacy/legacy_pages.dart`.
- [ ] **Upgrades:** Match GTN1's balance header, buy-multiplier dropdown and upgrade-card hierarchy, including labels, affordability/maxed states and purchase feedback. Source: GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/UpgradeScreen.kt`; destination: GTN2 `lib/shop/upgrade_shop_page.dart`.
- [ ] For each of these five screens, capture GTN1 and GTN2 at the same viewport, document the concrete differences, then verify the corrected screen and its interactions. Keep the existing Material 3 Expressive blend, but do not substitute generic GTN2-only layouts for GTN1's structure.

**Full-screen diff authority:** `docs/GTN1_SCREEN_PARITY_DIFF.md` is the active source-to-Dart screen comparison ledger. It covers all 22 Web Play roots and the complete Kotlin UI source-surface inventory (including Android, shared KMP and Windows desktop UI files). Work through its finite batches; every row must end as verified or explicitly not applicable with a source-backed reason. A destination route or widget is not proof of restored screen structure.

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

## Batch A verification status — authoritative refresh, 2026-11-15

**This section supersedes the older Batch A status snapshots below it in Git history.** Keep this section current whenever Batch A code, CI evidence, source comparisons or runtime verification changes. Do not copy PR-branch implementation claims into the merged-main status.

### Repository and source checkpoints

- **Repository:** `ne0gl1tch20/gtn-2`; default branch: `main`.
- **GTN1 parity source:** `ne0gl1tch20/GuessTheNumber@fe9cf567169e19059e0330d08769fe454336ef94`. This remains the pinned feature boundary.
- **Current inspected GTN2 main checkpoint:** `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1`. This is the actual base of the active Batch A continuation PR, not the PR's latest code.
- **Active continuation:** [PR #74 — Batch A: implement GTN1 active-save Creative Save](https://github.com/ne0gl1tch20/gtn-2/pull/74), base `main`, head branch `batch-a/creative-save-active-slot`, latest inspected head `29ff75120cf4acde0bfcbca560c3772b3ae97410`. PR #74 is open and draft. Its implementation is **not merged into main**.
- **Branch reconciliation:** current `main` contains seven commits not ancestral to the PR branch. GitHub compare reports PR branch divergence (322 commits ahead, 7 behind; merge base `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1`). The current main plan and ledger contents were synchronized into the PR branch in commits `ba98c2e81565eab9d046c616db2b97120abe1661` and `29ff75120cf4acde0bfcbca560c3772b3ae97410`; this is content reconciliation, not ancestry rebasing.
- **Latest PR-head validation:** [Validate run 43701106083](https://github.com/ne0gl1tch20/gtn-2/actions/runs/43701106083), on exact PR head `29ff75120cf4acde0bfcbca560c3772b3ae97410`. Formatting and static analysis passed, all **432 Flutter tests passed**, Android debug APK built and Windows portable debug build succeeded. The Windows release-installer job was skipped for this PR validation. This is PR-branch evidence, not evidence that the same code is already on main. Run 43701106083 supersedes the older PR-head validation.
- **Android artifact from that run:** [android-debug-apk](https://api.github.com/repos/ne0gl1tch20/gtn-2/actions/artifacts/14156856276/zip), artifact ID `14156856276` (expires 2026-11-22).
- **Windows artifact from that run:** [windows-debug-portable](https://api.github.com/repos/ne0gl1tch20/gtn-2/actions/artifacts/14156521810/zip), artifact ID `14156521810` (expires 2026-11-22).
- **Earlier merged baseline PRs:** #71 (Dashboard/More baseline) and #72 (Play/More/Profile baseline) are merged. PR #73 (random-event implementation) is merged but is not a Batch A surface closure. PR #67 remains a separate draft explicitly postponed until parity work is complete.
- **Audit ledger location:** `docs/BATCH_A_COMMIT_LOG.md` is now present on `main` (added in commit `1287b1237632528a74482d2e1a9f7d6ee91d2cda`, timestamp correction in `bf82a00ed56998c6547fb8aac7b4965f84f09e79`). It contains the append-only continuation ledger mirrored from PR #74 plus main/continuation reconciliation and the 2026-11-15 run 43701106083 result. Continue appending each Batch A commit and validation result; do not overwrite newer main plan evidence with an older PR-branch copy.

### Status rules

- **Implemented** means code exists on the explicitly named branch. It does not mean merged, runtime-verified or parity-complete.
- **CI passed** means the exact named commit passed the named automated jobs. It does not prove runtime behavior, platform persistence or visual parity.
- **Runtime verified** requires direct Android and Windows execution evidence for the stated behavior.
- **Visually verified** requires paired GTN1/GTN2 screenshots at the agreed mobile and desktop viewports, reviewed against the pinned source.
- **Verified / closed** requires the GTN1 source reference plus appropriate GTN2 automated and platform evidence. Keep a feature open if any required evidence is missing.
- Do not advance to Batch B until all six Batch A surfaces pass their complete exit checks.

### Batch A surface status

#### A1 — Dashboard

**Status: In progress; not closed.**

- The merged baseline includes the GTN1-facing Play hierarchy, responsive dashboard behavior, primary navigation and More routing work from PRs #71/#72.
- The pinned Web Play source is `app/src/main/assets/web-play/index.html`, `styles.css` and `app.js`; the Android source includes the corresponding Play screen and ViewModel behavior.
- PR #74 adds the source-equivalent active-save Creative Save panel to the dashboard on its branch. The panel is guarded by the active save's permanent eligibility flag and uses validated host-side transactions. This code is not yet on main.
- Remaining: execute the dashboard on Android and Windows; verify normal and eligible-save states, active-slot switching, restart persistence, updater notice actions and every primary dashboard action; compare responsive layout and controls against paired GTN1 screenshots. Verify Creative Save controls, source labels, edge inputs and transaction results on both platforms.
- Do not close Dashboard based on widget tests or PR CI alone.

#### A2 — More

**Status: In progress; not closed.**

- Merged work establishes the More destination inventory, source-facing labels/order, profile card separation, responsive grid and distinct Prestige/Ultra navigation destinations.
- Source references include the pinned Web Play `#screen-more` / `.more-links` markup and CSS, plus the Android More/navigation source.
- Remaining: exercise every More destination action in the running app on Android and Windows; verify each destination and return path; compare the complete card order, labels, icons, dimensions and responsive behavior with GTN1 at phone and desktop widths. Prestige/Ultra route separation is implemented, but their detailed catalog panels, requirement/reward summaries and source shop content remain separate parity work and must not be counted as complete merely because the destinations open.

#### A3 — Settings

**Status: In progress; not closed.**

- Source-facing settings hierarchy, theme color preview/picker, category descriptions and Android notification permission request/result bridge are implemented in the inspected baseline/continuation history. Update-check interval choices and updater scheduling are documented on the PR continuation; verify exact branch ownership before treating those changes as merged.
- Source references include GTN1 settings screen/model and Web Play settings controls; GTN2 targets include `lib/settings/` and the Android permission bridge.
- Remaining: verify every visible setting's source label, default, persistence and effect; test notification permission grant/denial on a real Android runtime, actual notification scheduling/delivery where applicable, updater interval behavior and app restart; verify Windows settings behavior and localization. Capture paired source/runtime screenshots.
- Widget tests for permission outcomes do not establish that the operating-system prompt or notification delivery works on-device.

#### A4 — Menu Studio

**Status: In progress; not closed.**

- The implementation on the continuation supports the two source areas (top navigation and More), source IDs (3 navigation entries and 18 More links), cross-area move/reorder, per-button HSV/hex color, reset, live preview, cancel and save using the GTN1-compatible `areas`, `orders.nav`, `orders.more` and `colors` payload.
- Source references: GTN1 `app/src/main/assets/web-play/menu-studio.js`, its stylesheet and the pinned HTML DOM inventory. GTN2 targets: `lib/settings/menu_studio_layout.dart`, `lib/settings/menu_studio_page.dart`, dashboard settings integration and corresponding tests.
- Remaining: verify actual drag/move/reorder, color changes, reset, cancel, save and reload in Android and Windows running builds. Confirm the live dashboard and More destinations update immediately and that cancel restores the prior layout. Capture paired screenshots.
- Do not close based on payload/model tests alone.

#### A5 — Player Profile

**Status: In progress; not closed.**

- The baseline implements a read-only profile view with a separate Edit profile action, profile identity/setup fields, first-launch setup gating, backward-compatible profile migration and app-private custom avatar storage/migration.
- Source reference: GTN1 `PlayerProfileScreen.kt` and profile persistence implementation. GTN2 targets include `lib/profile/player_profile_page.dart`, profile model/storage and `lib/main.dart`.
- Remaining: verify fresh-install/first-launch setup, edit/cancel/save behavior, avatar selection and file persistence, restart/reload, and save-slot metadata synchronization on Android and Windows. Confirm profile data remains independent of save-slot import/export as specified. Capture paired screenshots.
- Model/widget tests do not close real filesystem and lifecycle behavior.

#### A6 — Save Slots

**Status: In progress; not closed.**

- The baseline supports ten slots and the slot-management actions. PR #74 implements substantial additional work on its branch: permanent schema-v7 `creativeModeEnabled` distinct from the isolated sandbox payload; GTN1-shaped v2/v3 bundle conversion; field-preserving adapter mappings; full bundle import/export for ten slots, backups, active slot, Creative Mode slot payloads and global preferences; legacy single-save import; staged writes, rollback/recovery and regression fixtures.
- Source references inspected for the continuation include GTN1 `GameState.kt`, `GameViewModel.kt`, `DesktopWebPlayActions.kt`, `SaveSlotsScreen.kt`, `SaveManager.kt`, `PortableSaveBackup.kt` and Web Play `index.html` / `app.js`. GTN2 targets include `lib/data/saves/save_data.dart`, `lib/data/saves/save_storage.dart`, `lib/saves/` and the legacy adapter/backup implementation.
- PR-head evidence: Validate run 43673480248 passed all 432 tests plus Android and Windows debug builds. This includes the current PR-head code, not main. Earlier failed CI attempts and their fixes are retained in the PR-head append-only ledger; they are historical failures, not failures of the latest validated head.
- Remaining: run Android and Windows runtime import/export and slot-management checks; verify all ten primary slots and backups, active-slot switching, standalone Creative slot behavior, profile/avatar preservation, wrong passphrase, malformed/unsupported data, interrupted transaction recovery, restart persistence and no partial writes. Verify source-only GTN1 fields survive round-trip and that unsupported data is never silently discarded. Capture paired screenshots and record an actual artifact checksum for the final merged-main build.
- Do not close Save Slots or Batch A on code/CI alone.

### Cross-surface Batch A exit gate

The following evidence is still required across the six surfaces:

- [ ] Install and run the current validated Android build; exercise all six surfaces and record device/runtime evidence.
- [ ] Run the corresponding Windows desktop build; exercise all six surfaces and record runtime evidence.
- [ ] Capture paired GTN1/GTN2 screenshots at agreed phone and desktop viewports for Dashboard, More, Settings, Menu Studio, Profile and Save Slots.
- [ ] Verify every source-defined primary action, navigation destination, dialog, state transition, disabled/locked/empty/error state and return path for the six surfaces.
- [ ] Verify settings/profile/menu/save persistence across process restart and active save-slot changes.
- [ ] Verify Android notification permission and delivery behavior, updater behavior and platform-specific flows.
- [ ] Verify Save Slots import/export, migration, validation and recovery with known-good, malformed and wrong-passphrase fixtures on both platforms.
- [ ] Review all six surface diffs against the pinned GTN1 source and resolve every reproducible mismatch.
- [ ] Update the append-only Batch A commit ledger with every implementation, documentation, test, formatting and CI-fix commit. Ensure the ledger is present on main after merge.
- [ ] Merge PR #74 only after its review and required checks; then verify the merge commit and rerun/confirm required validation on the merged main state.
- [ ] Build the final Batch A Android/Windows artifacts from the verified merged main commit and record their exact run IDs, artifact IDs and SHA-256 values.
- [ ] Re-fetch this checklist from main after every material parity update so status never silently drifts from repository reality.

**Batch A exit:** All six surfaces have source-backed behavior, regression coverage, persistence checks, paired Android/Windows runtime evidence and visual comparison. The validated implementation must be merged to main. Until every item above is satisfied, Batch A remains active and Batch B remains blocked.

## Progress tracking

Keep one status per checklist item: **Not started**, **In progress**, **Verified**, or **Not applicable**. A verified item records the GTN1 source reference and the GTN2 test or platform evidence. Do not create a new checklist section for each newly noticed idea.


## Screenshot-driven regression fixes — 2026-11-16

**Evidence:** seven GTN2-only screenshots attached to [PR #74 comment 6895492186](https://github.com/ne0gl1tch20/gtn-2/pull/74#issuecomment-6895492186). The screenshots were retrieved and inspected directly; no GTN1 screenshots were requested from the user.

| Finding | Source comparison / target | Implementation state | Verification state |
|---|---|---|---|
| Nimmy first-run guide never starts automatically | GTN1 Web Play app.js onboarding state (nimmyTutorialCompleted) and complete_nimmy_tutorial; GTN2 GameSettings.tutorialCompleted and lib/main.dart | Added a first-run scheduling path after an existing save is restored or a save slot is selected. Completion is persisted through the existing global settings path. | Implementation present; Validate #1952 passes the first-run regression suite. Android/Windows first-run runtime timing and persistence check remain open |
| Portable backup export dialog did not match GTN1 confirmation flow | Pinned GTN1 SaveSlotsScreen.kt | Added passphrase confirmation, requires at least 12 characters and exact match, disables export until valid, keeps Cancel as a non-exporting dismissal, and makes the dialog content scroll when the mobile keyboard is open. | Implementation present; Validate #1952 passes the blank-passphrase cancellation and confirmation tests. Android/Windows export/import runtime check remains open |
| Bottom navigation labels wrap and increase bar height | Pinned GTN1 Web Play index.html and styles.css: five-column mobile navigation, 17px icons and compact 8px single-line labels | Replaced the mobile expressive navigation widget with the standard Material navigation bar using the source-sized icon/label metrics and a 56px bar. Added a mobile geometry/overflow assertion. | Implementation present; Validate #1952 passes the navigation geometry/overflow test. Android/Windows screenshot recheck remains open |
| Dashboard guess placeholder is clipped | GTN2 GtnExpressiveTextField applied an 18px extra-bold input style to a narrow mobile field | Added an opt-in font-size parameter and reduced the dashboard guess field and hint to 14px without changing other text fields. | Implementation present; Validate #1952 passes the dashboard widget suite. Android/Windows screenshot recheck remains open |

**Not closed by this patch:** the screenshot also shows a 51px horizontal overflow in Upgrade Shop and a narrow World Map hero heading. These are recorded as follow-up defects for their own parity batches; do not count them as fixed or use them to close Batch A. Settings typography and the remaining six-surface Android/Windows runtime checks still need review. A successful CI run alone is not visual evidence.

The implementation commits on batch-a/creative-save-active-slot are 4d085133f661edb02ed830b659f44bba72edc5d5, 222c9a02cc8223cba900bd4f8e4c10434864c9f6, 0e0ca4662ad98c476decbf1871b6fa8aa6871866, 5cbb891f1d7444a27f5a9f2f573044d77ace3edb, abf8137cba64f37cc82f3b3ae17176ccbe72a2b1, 2596b1bfc2534153eebbe962955497a258140ff1, and 19a1f46ce1e668b9a11b4658a4b35caa098de16c. All validation and runtime evidence remains pending.


## Latest validation checkpoint — 2026-11-16

Current implementation head: 3bb5667569510c46897e11ae7b0bbac4b2d345bf. Validate run #1933 (https://github.com/ne0gl1tch20/gtn-2/actions/runs/43767953058) has passed Dart formatting and analysis. Flutter tests, Android debug APK and Windows debug build were still in progress at this checkpoint. The temporary formatter workflow has been removed from the branch; Validate is restored to the standard read-only workflow. All screenshot-driven fixes remain in progress until tests, platform builds and runtime evidence pass. PR #74 remains draft; Batch A and Batch B gates remain unchanged.


## Correction to Validate run #1933 — 2026-11-16

Run #1933 did not pass the test suite: 431 tests passed and 4 Save Slots widget tests failed. The primary exception was confirmed as a TextEditingController being disposed while the export dialog's reverse transition was still mounted. The export dialog now owns its controllers in a dedicated StatefulWidget and disposes them with its own lifecycle (commit b7650a2112ee2294ab328bd29af89d167357e067). New Validate run #1936 is pending at https://github.com/ne0gl1tch20/gtn-2/actions/runs/43768293582. The screenshot-driven fixes remain in progress until the new run and Android/Windows runtime evidence pass.


## Save Slots lifecycle follow-up — 2026-11-16

Run #1933 failed with 431 passing and 4 failing tests. The primary failure was the export dialog's TextEditingControllers being disposed by the parent while the dialog route was still animating out. This is corrected by commit b7650a2112ee2294ab328bd29af89d167357e067: the dialog owns both controllers in its own StatefulWidget and disposes them when its subtree is removed. Dart formatting and analysis passed on the follow-up head. Validate run #1941 is currently running tests and Android/Windows builds: https://github.com/ne0gl1tch20/gtn-2/actions/runs/43768471017. No test or runtime pass is claimed yet.


## Validate #1941 partial result — 2026-11-16

At head c9557b4b69ae73ba176d1407927bbd618a0c34ff, formatting and analysis passed, all 435 Flutter tests passed, and the Android debug APK built successfully (artifact 14183730859). The Windows desktop debug build was still running; the Windows installer job was skipped. Full CI and runtime/visual parity remain open. Run: https://github.com/ne0gl1tch20/gtn-2/actions/runs/43768471017.


## Validate #1941 final result — 2026-11-16

Run #1941 completed successfully at head c9557b4b69ae73ba176d1407927bbd618a0c34ff. Format and analysis passed, all 435 Flutter tests passed, Android debug APK built, and Windows desktop debug build succeeded. The Windows installer job was skipped, not failed. Android artifact 14183730859 and Windows artifact 14183332045 are available until 2026-11-22. This does not close Batch A: Android/Windows runtime visual checks across Dashboard, More, Settings, Menu Studio, Profile and Save Slots remain required. The screenshot's Upgrade Shop horizontal overflow and World Map heading wrap remain separate follow-up defects. Run: https://github.com/ne0gl1tch20/gtn-2/actions/runs/43768471017.


## Validate #1952 final result — 2026-11-16

Validate run [#1952](https://github.com/ne0gl1tch20/gtn-2/actions/runs/43769040774) completed successfully against PR #74 head `217df064c85f34e821ad5aa6718a5d7a7ddd3016`. Formatting and analysis passed; all 435 Flutter tests passed; Android debug APK and Windows desktop debug builds succeeded. The Windows release installer was skipped by this debug validation workflow. Android artifact 14183164620 (SHA-256 `d94070c2a52653f22dffd2fb367609ea9174f4368d6a7499658be5671151a667`) and Windows artifact 14184055785 (SHA-256 `431b054364e5bbff647a4b141fa036105ce4c50685e2fd146d0921d384b7d5ce`) are available until 2026-11-22. This supersedes the earlier pending #1952 checkpoint and confirms the screenshot-driven regression tests pass. It does not replace Android/Windows runtime checks, paired screenshots, or the six-surface Batch A exit gate. PR #74 remains draft; Batch A remains active and Batch B remains blocked.



## PR #74 runtime comment follow-up — 2026-11-16

The latest Android test comment exposed a first-run ordering gap and several Save Slots/layout issues. GTN1 source comparison remains pinned to `fe9cf567169e19059e0330d08769fe454336ef94`: `NavGraph.kt` gates the game on profile setup and save-slot availability; the Web Play `renderRewardPopups` sequence presents offline earnings before the daily reward and only then starts Nimmy's tutorial.

The GTN2 follow-up on `batch-a/creative-save-active-slot` now:
- Opens Save Slots after first-launch profile completion when there is no active save, with a navigable Back route; existing saves do not get forced through a new-slot selection.
- Allows tapping the active empty slot to create a save, not only using its overflow menu.
- Moves Create Save dialog controllers into the dialog's own StatefulWidget so they remain alive until the reverse transition removes the fields.
- Defers Nimmy until profile setup and an active save are ready.
- Presents positive offline earnings, then the claimable daily Nebula reward with the exact engine-calculated streak amount, then Nimmy.
- Uses the full available mobile navigation width and constrains the Settings app-bar title to one ellipsized line.

A regression test now taps the active empty slot directly and verifies clean dialog dismissal. Upgrade Shop's 51px overflow and World Map hero-heading wrap remain separate defects.

Current code head: `322ec8551def094f867d98f55b02a438a773e2c3`. Validate run #1975 is at [run #1975](https://github.com/ne0gl1tch20/gtn-2/actions/runs/43777288634). Format and analysis passed; Flutter tests, Android APK build and Windows desktop debug build are running. Do not claim full validation, do not close Batch A, and do not unblock Batch B until all jobs pass and Android/Windows runtime screenshots verify the affected flows. PR #74 remains draft.



### Validate #1975 correction — 2026-11-16

Run #1975 passed format and analysis but the Flutter suite reported 434 passed / 1 failed. The failure was the existing GTN1 navigation-width assertion: the 390px viewport expects a 366px mobile bar, while the initial right-gap adjustment expanded it to 390px. The implementation has been corrected to preserve the source 366px width and center the bar (12px margins on each side); the geometry test now asserts both width and centered position. Corrective commits: `58472f1e4695ccf17d6ab9538bad71138b808e73` and `c533651a2ac0dfac932de4cb8a7e5f4df98f6a91`. The Android and Windows build jobs from #1975 were still running at this checkpoint. New validation is required; Batch A remains open and Batch B blocked.



### Validate #1982 correction — mobile navigation shrink-wrap — 2026-11-16

Run #1982 passed format and analysis but the Flutter widget suite exposed that a plain `Center` in the compact bottom-navigation slot expanded vertically and consumed the dashboard body in several 390px viewport tests. The centered 366px navigation now uses `Center(heightFactor: 1)` so it preserves the source 12px side margins while shrink-wrapping to the 56px navigation height. Corrective commit: `cb8fc830b30dace2f7e1c36d4a35ea518bb6c54e`. Run #1982 is superseded; its Android/Windows jobs were cancelled by the new head. Full validation remains pending.



### Validate #1986 partial result — 2026-11-16

At PR head `c8642b7df8f83d4d666b1ed293a3793eb53c8544`, Validate run #1986 has passed format, analysis and all 435 Flutter tests. Android debug APK and Windows desktop debug builds are still running; the Windows installer is skipped by this debug workflow. Do not call the full validation passed until both platform build jobs complete. Run: https://github.com/ne0gl1tch20/gtn-2/actions/runs/43778076654.
