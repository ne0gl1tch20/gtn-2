# GTN2 Finite Parity Plan and Completion Checklist

**Purpose:** Finish the Flutter port of GTN1 without turning parity into an expanding, indefinite project.

## Fixed scope

- **Source of truth:** `ne0gl1tch20/GuessTheNumber`, pinned to the exact commit recorded by GTN2's asset-sync configuration. That commit is the feature boundary.
- **Target:** GTN2's existing Android and Windows targets.
- **Included:** Features, screens, game rules, content, settings, save behavior and platform behavior that exist in the pinned GTN1 source and apply to the target platform.
- **Not included:** New features, redesigns beyond reproducing GTN1, speculative improvements, unrelated refactors, extra platforms, or features added to GTN1 after the pinned commit.
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
  - [x] Port and verify GTN1's bounded adaptive next-target algorithm: 64-bit mixing, difficulty salt, streak/attempt pressure and range clamping. Its 128-case reference checksum matches GTN1 in `test/core/adaptive_target_generator_test.dart`; Android supplies pre-guess streak and attempt counts, while Windows retains its platform fallback.
  - [ ] Compare the complete guess-state transition, invalid-range handling, source context and round lifecycle against GTN1.
- [ ] Economy: Money, Nebula, rewards, multipliers, penalties, caps and big-number arithmetic.
- [ ] Upgrades, prestige, Ultra progression and their reset/carry-over rules.
- [ ] Traits, talents, mutators and relics, including actual gameplay effects.
- [ ] Worlds, bosses, battles, mastery, secrets, codex and claim-once rewards.
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

- [ ] Every screen/route rendered by the single Web Play HTML shell has a corresponding native Flutter destination (the pinned tree does not contain 22 separate HTML screen roots).
- [ ] Each screen's primary controls, dialogs, navigation and state transitions work.
- [ ] The fixed screen set is compared against GTN1 at agreed mobile and desktop viewport sizes.
- [ ] All 17 catalogs load from canonical bundled data with valid references.
- [ ] All 320 trait IDs and their definitions/rules are available to the runtime.
- [ ] All 23 locale files load; key flows have no missing-string or layout failures.
- [ ] Required fonts, images, icons and audio assets resolve offline.
- [ ] Labels and user-visible terminology match GTN1 where the original exposes them.

**Exit:** No screen, catalog, locale or asset in the frozen inventory is missing or represented by a placeholder. Visual work is limited to matching the fixed GTN1 screen set, not endless pixel polishing.

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
