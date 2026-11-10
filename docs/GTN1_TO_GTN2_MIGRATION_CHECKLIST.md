# GTN1 → GTN2 Source-by-Source Migration Checklist

> **Authority:** `ne0gl1tch20/GuessTheNumber` at the pinned source revision recorded by `scripts/sync_gtn1_assets.sh`. GTN1 is the behavioral and content source of truth. GTN2 is the Flutter/Dart target.
>
> **Completion rule:** A screen, model, catalog, import, asset copy, or passing build is not proof of parity by itself. Mark an item complete only after its source behavior has been mapped, implemented, regression-tested against GTN1, and verified on every applicable platform. Keep GTN1 unchanged.

## Status vocabulary

- [ ] **Not audited / not implemented**
- [~] **Present or partially ported; parity not yet proven**
- [x] **Verified parity** — use only with a source reference and passing test evidence

Do not mark an entire section complete when only its UI or data model exists.

## 1. Repository and source inventory

| Source surface | GTN1 inventory | GTN2 target | Current assessment |
|---|---:|---|---|
| Kotlin application sources | 107 `.kt` files | Dart services, engines and platform adapters | [~] Partial replacement; audit every source class |
| Kotlin tests | 52 test files | Dart unit/widget/integration tests | [~] 24 Dart test files currently tracked; coverage parity not established |
| Web Play | 1 HTML, 5 JavaScript, 1 CSS | Flutter screens and equivalent interactions | [~] Flutter UI exists; web behavior needs a complete mapping |
| Jarrlyy UI SDK | 24 files | Flutter component/design system | [ ] SDK component and interaction parity |
| Lua scripts | 4 `.lua` files | Dart extension/runtime layer or explicitly documented replacement | [ ] Sandboxed execution and script behavior |
| Game catalogs | 17 JSON catalogs | `assets/game/` and typed repositories | [~] CI bundles all 17; runtime behavior must be checked per catalog |
| Trait packages | 320 trait IDs; 1,300+ files | `assets/gtn1/traits/` and Dart trait engines | [~] Assets/catalogs bundled; every rule and trigger needs parity evidence |
| Locales | 23 JSON files | `assets/locales/` | [x] 23 corresponding files hash-match GTN1; runtime string coverage still needs review |
| Fonts and artwork | GTN1 assets | Flutter asset bundle | [~] CI sync exists; check all usage, licensing and fallback behavior |
| Android platform layer | Manifest, services, workers, receivers, providers, widgets | Flutter plugins/platform channels/native host code | [ ] Per-component platform parity |
| Windows platform layer | Desktop services and updater | Flutter desktop services/installer | [ ] Installer and self-update parity |

## 2. Kotlin source migration

Audit **every** file under GTN1 `app/src/main/java/`. Record the source path, responsibility, Dart replacement, platform-specific behavior, and test proving equivalence.

### Core game and economy
- [~] Game engine, secret generation, guess validation, range boundaries and round lifecycle
- [~] Difficulty rules, Hardcore variants, range modifiers and persisted settings
- [~] Guess reward calculation, multipliers, penalties, streak rewards and caps
- [~] Big-number arithmetic, formatting, overflow and precision behavior
- [~] Normal upgrades: catalog, costs, prerequisites, purchase transaction and effects
- [~] Prestige and Ultra resets, carry-over rules, rewards and permanent upgrades
- [~] Nebula currency, shop inventory, purchase limits and unlock conditions
- [ ] Compare every source formula and boundary case against Kotlin tests

### Traits, talents, mutators and relics
- [~] Visible trait discovery, requirements, dependencies and hidden-trait gates
- [~] Trait effects, stacking, activation, cooldowns and save persistence
- [~] Adaptive/invisible trait profile, observation, helper thresholds and one-time bonuses
- [~] Talent catalog, prerequisite graph, costs, refunds and transaction effects
- [~] Mutator catalog, activation constraints, stacking and actual gameplay effects
- [~] Relic catalog, acquisition, equipment, removal and actual gameplay effects
- [ ] Verify every one of the 320 trait definitions and rule files against runtime behavior
- [ ] Verify every talent, mutator and relic effect in the gameplay transaction (not UI-only)

### Progression and secondary systems
- [~] Home Base / Sanctuary levels, upgrades, costs, bonuses and unlocks
- [~] Lucky Stake eligibility, randomization, payout, limits and save behavior
- [~] World map, world unlocks, bosses, battle phases, damage and rewards
- [~] World mastery, secrets, codex, endgame goals and claim-once rewards
- [~] Daily login, reward streak, daily quests, weekly challenges and claims
- [~] Loot chests, tiers, odds, inventory and reward transactions
- [~] Auto Clicker, bot team, memory modes, timing, pause/resume and clock rollback protection
- [~] Offline earnings, elapsed-time caps, duplicate-award prevention and lifecycle recovery
- [ ] Verify all reward/claim operations are atomic, idempotent and persisted

### Audio, scripting and content runtime
- [~] Background music catalog, playlists, queue, shuffle, repeat and track metadata
- [~] Playback lifecycle, background playback, notification/media controls and interruptions
- [ ] Jarrlyy DSP engine / audio processing behavior
- [ ] Lua sandbox, API surface, permissions, limits, errors and script lifecycle
- [ ] All four Lua scripts and their effects
- [ ] LiveOps / event script scheduling and rollback behavior
- [ ] Missing audio assets must fail safely without crashing gameplay

### Persistence, security and lifecycle
- [~] Save schema, serialization, validation, corruption handling and recovery
- [~] Save-slot count, slot selection, active-slot persistence, import/export and reset
- [ ] Explicit migration tests for every historical GTN1 save schema
- [ ] Verify no currency, progression, settings or metadata is lost on migration
- [~] Clock rollback detection, penalties and safe timestamp handling
- [ ] App lifecycle: pause, resume, process death, background tasks and shutdown
- [ ] Native notifications, widgets, receivers, providers and workers
- [ ] Android permissions, package installation flow and platform-channel error handling

### Updater and About
- [~] Version discovery, channel selection, manifest parsing and version ordering
- [~] SHA-256 verification before Android package installation
- [ ] Android device-level install/update/cancel/error verification
- [ ] Windows update download, verification, replacement, rollback and restart
- [ ] About content, changelog, licenses, source attribution and release metadata
- [ ] Offline, stale manifest, invalid hash, interrupted download and network failure tests

## 3. HTML, CSS, JavaScript and Jarrlyy UI SDK

Sources: GTN1 `app/src/main/assets/web-play/` and `app/src/main/assets/libraries/jarrlyyuisdk/`.

- [~] Map every Web Play route, screen and navigation destination to Flutter
- [~] Match game input, keyboard behavior, validation messages and result states
- [ ] Match all menus, dialogs, settings, shops, progression and developer controls
- [ ] Match animations, transitions, responsive layouts and accessibility semantics
- [ ] Map all five JavaScript modules and exported functions to Dart equivalents
- [ ] Map every SDK component, theme token, helper and event contract
- [ ] Preserve HTML-facing labels and user-visible terminology exactly where required
- [ ] Verify deep links, browser-specific behavior and offline asset loading where applicable
- [ ] Document intentional platform differences; do not silently omit behavior

## 4. Content catalogs and asset parity

- [~] All 17 GTN1 game JSON catalogs are bundled and parse as valid JSON in CI
- [~] All 320 trait IDs, definitions, rules, icons and English locale files are bundled
- [x] All 23 locale JSON files match the corresponding GTN1 files by SHA-256
- [~] Canonical GTN1 app logo and supported Web Play artwork are bundled
- [ ] Audit every catalog schema, stable ID, reference, prerequisite and cross-catalog link
- [ ] Ensure runtime uses canonical catalogs rather than fallback/mock/hard-coded substitutes
- [ ] Verify all image, SVG, audio, animation and font references resolve offline
- [ ] Preserve font and third-party license notices; audit all asset licenses
- [ ] Verify asset sync is deterministic and source commit is pinned in CI

## 5. Flutter / Dart implementation checklist

- [~] Dedicated Dart game, progression, economy and persistence layers
- [~] Typed repositories and validation for source catalogs
- [~] Save storage, migration and corruption recovery
- [ ] Complete transaction-level parity for every GTN1 gameplay system
- [ ] Remove any fallback, mock, placeholder or incomplete catalog behavior
- [ ] Ensure UI cannot award currency or progression outside validated engine transactions
- [ ] Ensure all gameplay state is save-backed and survives app restart
- [ ] Ensure Android and Windows behavior is intentionally supported or explicitly unavailable

## 6. Material 3 Expressive migration

Required package: `material_3_expressive: 1.2.0` (unverified uploader accepted by project owner for this migration).

- [~] Upgrade the Flutter/Dart SDK constraint to the package's documented minimum: Flutter 3.47 / Dart 3.13 (implemented; CI validation pending)
- [~] Add and pin `material_3_expressive: 1.2.0` and declare `material_ui` directly (dependency resolution succeeded in CI; lockfile generation/commit remains open)
- [~] Migrate app and widget-test Material imports from `package:flutter/material.dart` to `package:material_ui/material_ui.dart`
- [~] Establish one shared M3E theme with light/dark mode and GTN2 color tokens
- [ ] Apply expressive typography, shape, spacing, elevation and motion tokens consistently
- [~] Use M3E buttons, cards, chips, selection controls, text inputs and progress indicators
- [~] Use M3E app bars and adaptive navigation bar; rails/tabs/menus still need screen-specific review
- [~] Primary buttons, app bars, cards and input selectors are M3E-backed; dialog/sheet/snackbar surfaces still need screen-specific review
- [~] Shared M3E app bars, cards, buttons and controls applied across Home, Gameplay, shops, Progression, Worlds, Arcade, Creative Mode, More, save slots, Settings, Developer Settings and About/Updater
- [ ] Preserve keyboard, mouse, touch, focus, semantics and reduced-motion behavior
- [ ] Verify compact Android layouts and resizable Windows layouts
- [~] Add widget coverage for shared expressive components; full navigation-flow coverage pending
- [ ] Verify the app does not mix old default Material controls into primary user journeys

## 7. Automated verification and release gate

- [ ] `dart format --output=none .`
- [ ] `flutter analyze --fatal-infos`
- [ ] `flutter test` (all unit, widget and migration tests)
- [ ] Source-backed parity tests for economy, traits, talents, mutators, relics, Home Base and Lucky Stake
- [ ] Save compatibility and corruption/recovery tests
- [ ] Music and updater tests, including failure paths
- [ ] GTN1 asset/catalog verification
- [ ] Android debug build
- [ ] Windows debug build
- [ ] Android runtime verification on a real device/emulator
- [ ] Windows runtime verification on a real Windows environment
- [ ] Verify update installation, checksums, rollback and app restart
- [ ] Verify no network dependency for offline-first gameplay
- [ ] Review accessibility, reduced motion, localization overflow and platform input
- [ ] Publish no APK and do not enable `debug-latest` until the full parity gate above passes

## 8. Evidence required before checking an item

For each completed checklist item, record:
1. Exact GTN1 source file(s) and relevant behavior/formula.
2. Exact GTN2 implementation file(s).
3. Test name(s) proving matching behavior, including edge cases.
4. Platform(s) tested and result.
5. Any intentional difference and why it is safe.

**Final completion definition:** GTN2 is complete only when every applicable item is checked with evidence, the original GTN1 behavior is preserved, and Android + Windows validation passes. A green build alone is not completion.


## 9. Current implementation branch

Implementation is consolidated in the single draft pull request [#44](https://github.com/ne0gl1tch20/gtn-2/pull/44), branch `feature/gtn1-parity-m3-expressive`.

- M3 Expressive 1.2.0 is pinned exactly at the project owner's direction despite the publisher being unverified.
- The application shell uses `M3EMaterialApp`, a shared M3E theme and the existing Manrope font.
- Shared wrappers use actual M3E app bars, cards, text fields, switches, chips and dropdown menus; primary buttons, progress indicators, sliders and the bottom navigation use M3E widgets directly.
- All app-level Flutter Material imports in the migrated screens and affected widget tests now use `material_ui`.
- The implementation is not yet considered verified. Flutter analysis, tests, Android/Windows builds and runtime checks must pass before the relevant boxes are changed from `[~]` to `[x]`.
- This UI implementation does not close the outstanding gameplay, Lua, Web Play, native service, save-migration, audio or updater parity items above.
