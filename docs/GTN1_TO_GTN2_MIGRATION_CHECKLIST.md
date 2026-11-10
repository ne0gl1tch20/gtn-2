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

## 6. GTN1 Web Play visual recreation + selective Material 3 Expressive

**Architecture rule:** Rebuild the GTN1 HTML/CSS interface as native Flutter widgets written entirely in Dart. The HTML, CSS, JavaScript and Jarrlyy UI SDK are reference material for appearance, layout, labels, motion and behavior only. GTN2 must not embed the HTML, use a WebView, or ship a second JavaScript gameplay/UI runtime.

### Visual identity to preserve
- [~] Dark cosmic foundation: `#080B16` background, `#11172A` panels, `#171F36` raised surfaces
- [~] GTN1 accent palette: purple `#9B7CFF`, cyan `#62E8FF`, gold `#FFD66B`, green `#63F5A4`, danger `#FF7195`
- [~] Manrope / Inter / Space Grotesk / JetBrains Mono typography roles
- [~] Rounded 26px panels, subtle borders, gradients, glows and compact information density
- [~] Responsive centered content (720px reference width), compact mobile layouts and scroll behavior
- [ ] Match each GTN1 screen's hierarchy, spacing, typography, gradients, card treatments and responsive breakpoints
- [ ] Match all labels, iconography, button hierarchy, selected/disabled/hover/focus states and empty/loading/error states
- [ ] Match screen transitions, micro-interactions, feedback, animation timing and reduced-motion behavior
- [ ] Verify accessibility semantics, contrast, touch targets, keyboard and mouse behavior

### Native Flutter implementation
- [~] Recreate all UI in Dart widgets; Dart remains the only UI and gameplay runtime
- [~] Centralize GTN1 palette and reusable surface primitives in `lib/design/`
- [~] Keep the existing Dart game engine, save system and validated transactions as the single source of truth
- [~] Use `material_3_expressive: 1.2.0` selectively for expressive buttons, switches, chips, sliders, progress, navigation and motion
- [ ] Avoid generic M3E surfaces replacing GTN1's distinctive gradient/glow/card styling
- [ ] Map every HTML/CSS component and SDK component to a native Flutter equivalent with source references
- [ ] Map all five Web Play JavaScript modules to Dart UI behavior and existing Dart domain services
- [ ] Complete screen-by-screen visual and interaction comparison against GTN1 screenshots/source
- [ ] Verify Android and Windows layouts, navigation, focus, pointer input and reduced motion

### M3 Expressive integration constraints
- [~] Pin `material_3_expressive: 1.2.0` and declare `material_ui` directly
- [~] Meet the package's documented Flutter 3.47 / Dart 3.13 minimum
- [~] Preserve Manrope and the app's dark-mode / reduced-motion settings
- [~] Add shared expressive adapters and widget coverage
- [ ] Apply expressive motion and shape selectively without changing GTN1's brand identity
- [ ] Verify no M3E dependency forces an HTML/WebView bridge or duplicate state layer

### Validation
- [ ] Compare Android screenshots against GTN1 reference screens at matching viewport sizes
- [ ] Test all primary navigation and gameplay journeys on Android and Windows
- [ ] Verify all controls call real Dart actions and persist through the existing save engine
- [ ] Run format, analyzer, full tests and Android/Windows debug builds
- [ ] Do not publish APKs or enable `debug-latest` until parity and runtime gates pass

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
