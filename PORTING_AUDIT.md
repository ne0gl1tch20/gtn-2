# GTN 1 → GTN 2 parity audit

**Source repository:** [ne0gl1tch20/GuessTheNumber](https://github.com/ne0gl1tch20/GuessTheNumber)  
**Source ref inspected:** `master`  
**Target repository:** [ne0gl1tch20/gtn-2](https://github.com/ne0gl1tch20/gtn-2)  
**Target branch:** `feature/full-gtn1-system-parity`  
**Status:** Draft implementation. This audit is not a merge-readiness claim.

## GTN 1 source inventory

The source audit confirmed these canonical implementation areas:

| System | GTN 1 source of truth | Notes |
|---|---|---|
| Traits | `BuiltInTraits.kt`, `TraitDefinition.kt`, `TraitActivationEngine.kt`, `TraitGameplayCatalog.kt`, `TraitGameplayRuntime.kt`, `TraitRewardPolicy.kt`, trait catalog assets | 320 built-in stable IDs plus activation/dependency/conflict, hidden/seasonal discovery and gameplay effects |
| Talents | `TalentScreen.kt`, `talents.json`, `GameViewModel.buyTalent` | Six-node tree with fixed costs and parent prerequisites |
| Mutators | `MutatorsScreen.kt`, `MutatorRules.kt`, `mutators.json` | Four supported mutators; stacked reward multiplier is 300× and Hardcore doubles range |
| Relics | `relics.json`, `ProgressionScreens.kt`, `GameViewModel`, shared economy tests | Four boss relics, owned inventory, equip cap and individual/full-set reward effects |
| Home Base | Web Play Home Base UI and `DesktopEconomyTransactions.upgradeHomeBase` | 20 levels, linear 50,000 × next-level cost, reward and mastery-discount effects |
| Lucky Stake | `StakingScreen.kt` | 50/50 settlement; winning payout is stake × (2.0 + 0.1 × current streak) |
| Daily rewards / quests / chests | `GameViewModel`, daily reward policy, challenge and loot data | Claim-once rules, streak progression, daily objectives and tiered chest rewards |
| Worlds / mastery / secrets / rift / codex | `WorldMapScreen.kt`, `ProgressionScreens.kt`, shared economy transactions | Unlocks, boss battles, mastery upgrades, secrets and one-time completion rewards |
| Music | `BackgroundMusicManager.kt`, `MusicPlaybackService.kt`, `MusicPlayerScreen.kt` | Offline library, imported tracks, playback lifecycle, queue, playlists, shuffle and repeat |
| About / Android updater | `AboutScreen.kt`, `UpdateChannelChecker.kt`, `ApkUpdateInstaller.kt`, `UpdateInstallReceiver.kt` | Channel-aware update discovery and validated APK install flow |
| Windows updater | `WindowsDebugUpdateClient.kt` and related validators/installers | Separate Windows package validation and installation path |

## GTN 2 implementation status

| System | Current branch status | Remaining work before merge |
|---|---|---|
| Trait catalog | 320 stable IDs are imported | Port full source-backed activation semantics and all supported gameplay effects; hidden discovery must respect dependencies and season rules; connect effects to guess/reward transactions |
| Talents | Six current IDs, costs and prerequisites exist in the Dart engine | Load the canonical catalog instead of duplicating constants; connect purchases to actual gameplay effects and screen |
| Mutators | Known-ID validation, toggles, stacked 300× reward multiplier and range multiplier exist | Apply modifiers to the real guess/reward path; add weekly and custom challenge state/progress/claim UI |
| Relics | Four relic IDs, inventory/equip validation and reward bonus calculation exist | Port canonical catalog/drop/claim rules and connect effects to boss/guess rewards and UI |
| Home Base | Level cap, linear cost transaction and bounded reward bonus exist | Verify the full Android reward and mastery-discount behavior; add the player screen and connect it to save-backed actions |
| Lucky Stake | Atomic stake settlement and statistics exist | Add screen, inject deterministic randomness at the host boundary and test win/loss/edge cases |
| Daily rewards / quests / chests | Claim and settlement rules exist | Connect progress recording to all gameplay actions; port canonical objective/catalog data and screens |
| Worlds / mastery / secrets / rift / codex | Persisted fields exist | Port actual unlock, battle, mastery, secret and reward transactions before exposing these fields |
| Music | Save fields for library, queue, playlists and playback options exist | Implement file import/permissions, player backend, queue operations, playback lifecycle and screen |
| About / Android updater | About and license notices are present; Stable Debug discovery, SHA-256 verification and Android package-installer handoff are implemented | Publish signed builds through `debug-latest` after adding `GTN2_DEBUG_KEYSTORE_BASE64`; Windows update installation remains separate work |
| Save migration | Legacy state is nested in progression JSON and defaults when absent | Add explicit migration/version strategy and tests for old saves, malformed nested data and per-slot isolation |
| UI integration | No complete player-facing legacy-system route set yet | Add accessible Flutter screens and navigation backed exclusively by engine transactions |

## Validation status

- Source tree and relevant Kotlin/Dart files were inspected.
- The imported built-in trait catalog contains exactly 320 IDs.
- Transaction tests now cover core mutator, talent, Home Base, relic, Lucky Stake, daily reward, challenge and save-integrity cases.
- Existing legacy-system tests cover additional claim and catalog behavior.
- Flutter analysis, Flutter unit tests, Android build and Windows build have **not** been verified in this audit.
- Android updater version-ordering tests cover stale and newer builds. APK download is SHA-256 verified before handing it to Android Package Installer; device-level prompts still require runtime verification.
- Windows self-update installation is not yet ported; Windows builds remain downloadable CI artifacts.

## Merge gate

Do not mark this port complete or merge the PR until the remaining work above is implemented, the relevant Flutter tests and static analysis pass, and Android/Windows builds succeed. UI presence alone is not proof that an economy, progression or updater feature works. Keep GTN 1 unchanged while using its current source as the behavioral reference.

## Verified parity-pass update (2026-11-08)

- The Flutter dashboard now uses GTN1's canonical `GTN_APP_LOGO.png` instead of a placeholder icon.
- Android and Windows CI check out the same pinned GTN1 source commit and bundle the original Manrope, Inter, Space Grotesk and JetBrains Mono font files. They also copy supported image files from GTN1 Web Play assets into Flutter's asset bundle. This keeps the APK offline-capable and makes the source revision reproducible.
- The Flutter app theme now uses the bundled Manrope family.
- Hidden-trait discovery now checks the trait's `minLevel` gate in addition to prestige, correct guesses, best streak, season and discovered dependencies. A regression test covers the level gate.
- These changes do not close the remaining behavioral parity items in the table above. In particular, the separate adaptive/invisible trait profile and its helper cooldown/one-time bonus behavior, complete minigame/music playback parity, and device-level updater/install verification remain unclaimed.


## Source-content bundle pass (2026-11-08)

The active branch `port/gtn1-content-assets` expands CI's pinned-source sync beyond fonts and Web Play raster art:
- Copies all 17 canonical GTN1 `game/*.json` catalogs into Flutter's `assets/game/` bundle.
- Copies the complete GTN1 `traits/` tree, including 320 trait definitions, 320 rule files, 320 SVG icons, English localization files and the invisible-trait profile.
- Preserves the source changelog and third-party license notices for native Flutter About/license screens.
- Adds a pre-build verifier that parses every bundled game and trait JSON file and checks the expected catalog and trait asset counts.
- Runs that verifier in PR validation and both Android and Windows build jobs.

The source content is now available to Flutter offline after CI sync, but copying it is not the same as implementing every source-backed screen or behavior. Catalog-driven Flutter screens and remaining gameplay transactions still need to consume these assets. This branch must pass CI before merge.
