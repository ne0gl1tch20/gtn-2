# GTN1 → GTN2 Full Screen Parity Diff

**Source of truth:** `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**Target:** GTN2 `main`; destination paths below are the current route/widget implementations inspected during this audit.  
**Purpose:** A finite, source-backed screen-by-screen diff. This is not a claim that these screens already match. Every row stays open until source, Dart structure, visible states and runtime presentation have been compared and verified.

## Comparison contract

Compare GTN1 and GTN2 side by side at matching phone and desktop viewport sizes. For each screen, record and resolve:
1. Screen shell: route entry, app bar/top bar, back behavior, navigation and scroll bounds.
2. Hierarchy: sections, order, nesting, grouping, card count and relative prominence.
3. Geometry: content width, margins, padding, gaps, alignment, sizing and responsive breakpoints.
4. Visual tokens: background, surface layers, gradients, borders, radius, elevation, glow and accent roles.
5. Typography: exact labels/copy, font family, size, weight, line height, letter spacing and truncation.
6. Components: icons, images/artwork, buttons, chips, dropdowns, sliders, switches, text fields and progress indicators.
7. States: initial, selected, disabled, locked, loading, empty, error, confirmation, success, expanded/collapsed and overflow.
8. Interaction: tap/click, keyboard, pointer, focus, drag/seek, navigation, persistence and feedback.
9. Accessibility/motion: semantics, contrast, touch targets, focus order, reduced motion and transition behavior.
10. Platform parity: Android and Windows differences must be intentional and recorded, not accidental omissions.

**Diff discipline:** inspect the pinned GTN1 source and current GTN2 code in parallel before editing. Keep source paths, destination paths, exact mismatch and evidence together. Do not infer parity from matching labels, route existence or a passing build. Do not mark screenshot comparisons complete without actual paired captures. Keep M3 Expressive as a coherent additive layer over GTN1's information architecture and visual identity.

## Web Play's 22 production screen roots

The single GTN1 HTML shell renders these 22 roots. Each is a separate player-facing screen contract even though the original implementation shares one HTML file.

| Root | GTN1 responsibility | Current GTN2 destination | Diff status |
|---|---|---|---|
| `play` | Main guess dashboard, hero/range/feedback/input/stats/wallet/quick actions/bot arena | `lib/home/game_dashboard_page.dart` | **Open** |
| `worlds` | Universe overview, world cards, guardian status and unlock progress | `lib/worlds/world_map_page.dart + lib/progression/progression_hub_page.dart` | **Open** |
| `arcade` | Minigame catalog, active game, score and reward state | `lib/arcade/arcade_page.dart` | **Open** |
| `upgrades` | Money upgrade catalog, levels, costs and purchase actions | `lib/shop/upgrade_shop_page.dart` | **Open** |
| `more` | Player profile entry and grouped secondary destinations | `lib/legacy/legacy_pages.dart + lib/main.dart` | **Open** |
| `rewards` | Daily Nebula reward, streak, schedule and claim feedback | `lib/legacy/legacy_pages.dart + lib/main.dart` | **Open** |
| `journey` | Run summary, history, progress and playtime | `lib/legacy/legacy_pages.dart` | **Open** |
| `shop` | Nebula shop catalog, owned/equipped state and purchases | `lib/shop/nebula_shop_page.dart` | **Open** |
| `homebase` | Home Base/Sanctuary level, bonus and restoration | `lib/progression/progression_hub_page.dart + lib/legacy/legacy_systems_page.dart` | **Open** |
| `relics` | Relic collection, rarity, equipment slots and equip state | `lib/legacy/legacy_systems_page.dart` | **Open** |
| `codex` | Discovery collection, completion progress and claim-once reward | `lib/legacy/legacy_pages.dart + lib/legacy/legacy_systems_page.dart` | **Open** |
| `changelog` | Release notes and rendered changelog content | `lib/legacy/legacy_pages.dart` | **Open** |
| `about` | App information, socials/source links, licenses and update status | `lib/legacy/legacy_pages.dart` | **Open** |
| `music` | Offline player, import/metadata, seek, queue, playlists, shuffle/repeat | `lib/legacy/legacy_systems_page.dart (music expansion section; no dedicated player widget)` | **Open** |
| `settings` | Gameplay, notation, appearance, colors, audio/haptics, notifications, accessibility and Menu Studio | `lib/settings/settings_page.dart + lib/settings/menu_studio_page.dart` | **Open** |
| `prestige` | Prestige reset, currency, upgrades and shop | `lib/progression/progression_hub_page.dart` | **Open** |
| `ultra` | Ultra progression, reset and upgrades | `lib/progression/progression_hub_page.dart` | **Open** |
| `talent` | Talent tree, prerequisites, purchase and active effects | `lib/legacy/legacy_systems_page.dart` | **Open** |
| `mutators` | Mutator catalog, selection, stacking and gameplay effects | `lib/legacy/legacy_systems_page.dart` | **Open** |
| `stats` | Accuracy, guesses, currencies, playtime, streaks, arcade and boss metrics | `lib/legacy/legacy_pages.dart` | **Open** |
| `stake` | Lucky Stake eligibility, wager, streak multiplier, result and payout | `lib/legacy/legacy_systems_page.dart` | **Open** |
| `traits` | Traits/loadout, unlock state, selected arms and gameplay traits | `lib/legacy/legacy_systems_page.dart` | **Open** |

## Deep source-level diffs already inspected

### Settings
- **GTN1 source:** `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SettingsScreen.kt`
- **GTN2 destination:** `lib/settings/settings_page.dart`
- **GTN1 structure observed:** Scaffold/app bar titled “Settings & Save Management”; scrollable page; Game Preferences/language; Theme Appearance; Theme Colors with live preview, preset and three custom color pickers; Number Notation; Push Notifications & Reminders with conditional frequency and category controls; Sound FX; Vibration; Visual comfort/accessibility toggles; master and SFX volume sliders.
- **GTN2 code sub-batch (commits `b9716b9`, `dd35f0f`, `837f8e2`):** restored the source page title and major section order, separated Theme Colors from Theme Appearance, reinstated source-specific section labels and descriptions, kept the M3 Expressive component layer, preserved conditional notification-category visibility and disabled SFX volume when sound effects are off. Added widget assertions for the hierarchy and disabled slider.
- **Remaining diff:** GTN1's localized copy is not yet fully ported; notification permission request/toast behavior is not yet reproduced; exact color preview composition, geometry and picker parity need paired captures; no runtime/device comparison has been recorded. GTN2-specific controls removed from this source screen (difficulty, update scheduling, diagnostics, tutorial and Menu Studio entry) remain in their owning flows/data where applicable, not mixed into GTN1's settings hierarchy.

### Developer Settings
- **GTN1 sources:** `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/DevSettingsScreen.kt`, `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedDeveloperSettingsScreen.kt`, plus dedicated inspector/tool screens listed below.
- **GTN2 destination:** `lib/dev/developer_settings_page.dart`
- **GTN1 structure observed:** “Developer Settings & Console” shell; trait registry inspector/search and trait metadata; HTML version diagnostics; Android WebView console; links to developer/testing playground, shared Web UI prototype and SDK lab; log-storage and verbose logging controls; Lua command console; developer commands; global preferences JSON editor; save-slot selector and raw save JSON editor; live console log viewer with filters/export/clear controls; updater and DSP test tools.
- **GTN2 finding:** current Dart developer page has trait registry/runtime inspectors, diagnostics, Lua tools, command execution and JSON/log surfaces, but it is not yet proven to reproduce GTN1's section ordering, control density, dedicated destinations or platform-specific tools. Full component-by-component diff remains open.

### About
- **GTN1 source:** `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/AboutScreen.kt`
- **GTN2 destination:** About section in `lib/legacy/legacy_pages.dart`
- **GTN1 structure observed:** dedicated About screen with update information and actionable update controls, update details/diagnostics, external links and source/license content.
- **GTN2 finding:** About is embedded as a generic legacy detail section rather than a dedicated screen; updater state and detailed layout parity remain open.

### Upgrades
- **GTN1 source:** `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/UpgradeScreen.kt`
- **GTN2 destination:** `lib/shop/upgrade_shop_page.dart`
- **GTN1 structure observed:** “Upgrades” app bar; available Money balance; “Buy Multiplier:” dropdown; scrollable source upgrade cards with level/max-level, cost and purchase controls.
- **GTN2 finding:** a native shop exists and purchase-batch logic is tested, but its balance/header and segmented multiplier presentation differ from GTN1's dropdown structure. Card-by-card ordering, content and state comparison remains open.

### Background Music
- **GTN1 source:** `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MusicPlayerScreen.kt` and `data/audio/BackgroundMusicManager.kt`
- **GTN2 destination:** `lib/legacy/legacy_systems_page.dart`, entered from `_openMusic()` in `lib/main.dart`
- **GTN1 structure observed:** dedicated player screen; 220dp album-art surface; current title and artist/album; elapsed/total duration; seek slider; previous/play-pause/next/shuffle/repeat controls; import action; library with metadata and play/queue/remove actions; queue with ordering/removal; playlist creation, playback, expansion and deletion.
- **GTN2 finding before Batch 1:** `_openMusic()` opened an expanded `ExpansionTile` inside a generic systems page. **Batch 1 change (commits `392b74f`, `5cfe029`, `936e658`):** the music view now branches to its own app-bar/body shell and renders player content directly, with a 220px artwork-placeholder surface, current-track title, playback controls (previous/play/next/shuffle/repeat), seek/progress, explicit Library and Playlists headings, and the source order of library → queue → playlist creation → playlists. This restores the dedicated page structure but is not full parity: the artwork is still a generic icon, track artist/album/duration metadata is not extracted, and Android background media-service/notification lifecycle is not implemented. The reported blank screen still needs runtime reproduction and widget/device verification.

## Complete Kotlin UI source inventory

The following source surfaces are in GTN1's frozen production inventory. Some are reusable components, adapters or platform-specific support rather than standalone routes; each must still be mapped to a GTN2 equivalent or explicitly marked not applicable with a source-backed reason. A destination filename alone does not close its behavior or appearance.

- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/AboutScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/AchievementsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ArcadeScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/CrashRecoveryScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/DevConsoleScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/DevSettingsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/DeveloperPlaygroundScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/GuidedTutorialOverlay.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/JarrlyyUiSdkScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/LiveOpsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/LuaActivityHubScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/LuaTestingHubScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MarkdownViewerScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MoreScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MusicPlayerScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/MutatorsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/PlayScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/PlayerProfileScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/PrestigeScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ProcessInspectorScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ProductionGuessPresentationAdapter.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ProductionWebAppScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ProductionWebPlayScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ProgressionScreens.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/RuntimeInspectorScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SaveSlotsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SettingsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SharedWebUiPrototypeScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/ShopScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/StakingScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/StatsScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/TalentScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/UltraScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/UpgradeScreen.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/WebUiBridgeProtocol.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/WorldMapScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopActivityHubScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopArcadeScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopChangelogScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopDeveloperCenterScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopDeveloperConsoleScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopDeveloperSettingsScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopLiveOpsScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopParityScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopProcessInspectorScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopSettingsScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/ProductionGuessGameScreen.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/update/WindowsBuildVersion.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/update/WindowsDebugArchiveValidator.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/update/WindowsDebugArtifactValidator.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/update/WindowsDebugInstaller.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/update/WindowsDebugUpdateClient.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/JarrlyyUiComponents.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedDeveloperSettingsScreen.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGameContracts.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGuessEntryPanel.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGuessFeedbackCard.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGuessGameContent.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGuessGameScreen.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedGuessInputField.kt`
- `shared/src/commonMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SharedSaveSlotCard.kt`
- `shared/src/jvmAndAndroidMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/ArcadeCanvasGame.kt`
- `shared/src/jvmAndAndroidMain/kotlin/com/jarrlyyy/guessthenumber/shared/ui/SeasonalThemeSimulatorCard.kt`

## Verification pass — Batch A settings and More navigation (2026-11-14)

**Pinned source:** GTN1 `fe9cf567169e19059e0330d08769fe454336ef94`. **Target:** GTN2 `main`.

### More navigation cross-diff

- Compared the GTN1 `#screen-more` HTML root and its ordered `data-screen-target`/`data-route` list against GTN2 `_MoreMenuPage`, the legacy `LegacyHubPage`, `GameSettings.moreScreenOrder` and the main navigation callbacks.
- GTN1 order: player profile, Rewards, Journey, Shop, Home Base, Relics, Codex, Changelog, About, Save Slots, Background Music, Settings, Prestige, Ultra, Talents, Traits, Mutators, Stats, debug-only Dev Settings, Lucky Stake.
- Found and corrected two functional mismatches in the actual dashboard More menu: the Shop item was incorrectly routed to the Money Upgrade Shop instead of the Nebula Shop; Dev Settings was rendered twice in debug mode because it existed both in the ordered destinations and as a separate trailing card.
- Removed an extra Flutter-only More page header that was not present in the GTN1 Web Play root and restored the two-column desktop / one-column narrow layout behavior. Kept the GTN1 item order and profile-first entry.
- Added a widget test for one Dev Settings entry and the Shop-to-Nebula-Shop route. The first complete test run exposed stale test assumptions about the More title and pinned bottom-navigation labels; those assertions were corrected. A later run reached 342 passing / 5 failing tests, with remaining failures in viewport scrolling and duplicated More title assertions. Those test fixes are committed and formatted; a post-format full validation run is still pending.
- **Still open:** verify each More item destination and persisted Menu Studio order/color customization; compare card icons, colors, widths, gaps and interaction states at mobile/desktop runtime sizes. The old `LegacyHubPage` remains a second route and must not be mistaken for the dashboard's actual bottom-navigation More page.

### Settings screen cross-diff

- Compared GTN1 `SettingsScreen.kt` against GTN2 `settings_page.dart` and `game_settings.dart`, including notification permission launcher, color picker, all toggles and volume controls.
- The major section order and source-facing labels are restored, with M3 Expressive cards and controls retained as the presentation layer.
- Restored GTN1's live Theme Colors preview card in GTN2 (commit `849b5a9`) and added assertions for its preview title, success copy and Guess action. The shared Flutter color picker now reproduces the source saturation/value plane, hue slider, live preview, hex input and optional Use theme reset. Remaining: Android notification permission request/result toasts and notification delivery/scheduling are missing; notification category descriptions and several control descriptions are omitted; volume control descriptions, localized copy and exact source labels still need a final diff.
- No paired runtime screenshots or persistence/device evidence exist for these screens.

### CI evidence and gate

- Validation run `43579731488` on commit `ef55720b9b1c86a532a5774b6a89176701e87b25` stopped at **Dart formatting**. The preceding run `43579680591` identified four unformatted files: `lib/legacy/legacy_pages.dart`, `lib/legacy/legacy_systems_page.dart`, `lib/settings/game_settings.dart` and `lib/settings/settings_page.dart`. Analysis and the test suite were skipped as dependent jobs.
- Android/Windows debug build run `43579731519` was still in progress at the time of this audit. No build or runtime pass is claimed.
- **Batch A remains open.** No screen in this pass is declared visually or behaviorally complete.

## Verification pass — Menu Studio, Profile and Save Slots (2026-11-14)

**Pinned source:** GTN1 `fe9cf567169e19059e0330d08769fe454336ef94`. **Target:** current GTN2 `main`.

### Menu Studio cross-diff

- Compared GTN1 `app/src/main/assets/web-play/menu-studio.js` and its dedicated CSS with GTN2 `lib/settings/menu_studio_page.dart`, `lib/settings/game_settings.dart` and the actual dashboard navigation in `lib/home/game_dashboard_page.dart`.
- GTN1 edits two areas: the top navigation (`worlds`, `arcade`, `upgrades`) and More. Play and More remain pinned. The editor supports reordering within each area, moving entries between areas, per-button colors through the shared native color picker, a live preview, reset and save.
- GTN2 now has the matching source inventory: navigation IDs `worlds`, `arcade`, `upgrades`, plus the exact 18 `.more-links` IDs read from pinned `index.html`. It implements two-area move/reorder, per-button HSV/hex color selection through the shared GTN color picker, reset and save.
- The serialized payload now includes `areas`, `orders.nav`, `orders.more` and `colors`, matching GTN1 `validLayout()`. `GameDashboardPage` consumes the stored layout for navigation order and button colors. Widget tests assert the source-pinned order, both required order arrays, moving a navigation entry into More and restoring the payload.
- Flutter now sends the in-progress layout to the dashboard settings notifier. The actual bottom navigation and More route consume that live settings value, so order and per-button colors update while the editor remains open. Cancel restores the original settings; Save persists the edited layout. The widget test now asserts the preview callback and moved destination state.
- **Still open:** add a route-level regression test proving that the rendered dashboard navigation and More cards change and revert, then verify live reorder/color/cancel/save/reload behavior at runtime on Android and Windows.

### Player Profile cross-diff

- Compared GTN1 `PlayerProfileScreen.kt` with GTN2 `lib/profile/player_profile_page.dart` and `lib/main.dart`.
- GTN1 has distinct first-launch/edit and read-only profile modes. The read-only view shows avatar, username and bio, then offers an Edit profile action. Its persisted model includes `profileId` and `setupComplete`; custom images are copied into app-private files.
- GTN2 now opens a read-only profile view with a separate Edit profile action. Its model persists `profileId` and `setupComplete`; older GTN2 profile JSON receives a generated identity and infers completion from a non-empty username. The app now gates first launch on profile setup. Model/widget tests cover identity round-trip and the view-to-edit transition.
- Flutter now stores custom avatars as app-private image files and migrates older GTN2 base64 data-URI avatars into that file store. The model still retains the original GTN1 `profileId` and `setupComplete` fields. Runtime save/reload and save-slot metadata synchronization are not yet verified.
- **Open:** verify first-launch completion and edit persistence on Android/Windows, and verify save-slot metadata synchronization.

### Save Slots cross-diff

- Compared GTN1 `SaveSlotsScreen.kt`, `SaveManager.kt` and `PortableSaveBackup.kt` against GTN2 `lib/saves/save_slots_page.dart` and `lib/data/saves/save_storage.dart`.
- Both implementations support 10 slots. GTN2 already has create, edit slot profile, duplicate, reset one slot, restore local backup and Creative Mode actions.
- Flutter now has a guarded Reset Everything action that clears all ten save files and backups, resets the active slot to 1 and restores a fresh in-memory game. Its dialog mirrors the source 45-second wait, acknowledgement checkbox and arithmetic challenge; a widget test verifies that confirmation remains blocked before the gate.
- GTN1's encrypted whole-save export/import, passphrase-protected portable backup (minimum 12-character passphrase), legacy encrypted import and legacy single-save migration into Slot 1 are still absent from Flutter. The pinned source bundle contains app preferences, active slot, ten primary slots, ten backups and Creative Mode slot data; the portable wrapper uses PBKDF2-HMAC-SHA256 + AES-256-GCM with a fixed AAD and a 12-byte nonce.
- **Open:** port the source transfer envelope and compatible import/export semantics plus legacy migration; add tests for wrong passphrases, malformed payloads, empty/occupied slots, backup retention and successful reset completion.

### Latest validation state

- Dart analysis passed on commit `62e96e0`; the test suite then reported 340 passed / 7 failed. The failures included outdated viewport assumptions in Settings and stale More-title assertions.
- Test assertions were updated; the next run reported 342 passed / 5 failed. The remaining failures were traced to one Settings test scrolling down before checking the top preview, an assertion that incorrectly expected the pinned Arcade navigation label to be absent, and More title finders that matched both the app bar and bottom navigation.
- Those test fixes were committed. The official Dart formatter ran through a temporary one-time workflow and committed the formatter output as `6560a22`; the temporary workflow was removed in `bc1cdd2`. The latest post-format validation is pending. Do not treat the earlier test counts as a pass.
- Last confirmed Android and Windows debug builds passed together in run `43579955796` on commit `a850061`; subsequent code changes still require a fresh successful build. No paired runtime screenshots or real-device/Windows smoke evidence exist.

**Batch A remains open.** Dashboard/More routing corrections and the Settings live preview are code changes, not closure evidence. Menu Studio, Profile and Save Slots have source-backed functional gaps listed above.

## Finite implementation batches

- **Batch A — Core shell and settings:** Play/dashboard, More navigation, Settings, Menu Studio, profile and save-slot screens. Verify route shell, layout, responsive behavior, settings controls and persistence.
- **Batch B — Economy and progression:** Upgrades, Nebula shop, Prestige, Ultra, talents, mutators, traits, relics and Home Base. Verify catalog ordering, locked/owned/maxed states, transaction feedback and reset dialogs.
- **Batch C — Secondary player screens:** Music, daily/weekly rewards, journey, stats, codex, Lucky Stake, achievements, arcade and worlds/boss screens. Verify full screen hierarchy and all source-defined states.
- **Batch D — About, LiveOps and content:** About/updater, changelog/Markdown viewer, LiveOps, Lua/activity surfaces and content-driven screens.
- **Batch E — Developer and diagnostics:** Developer Settings, developer console, playground, process/runtime inspectors, SDK lab, crash recovery and test tools. Keep debug-only visibility and Android/Windows differences.
- **Batch F — Cross-platform visual closure:** paired screenshots at agreed mobile and desktop viewports; fix only demonstrated differences; run route/interaction regression tests; record final evidence for every route.

Each batch must inspect both repositories before changes, implement the full source structure for that batch (not just visual fragments), run targeted tests plus formatting/analyzer, and update this diff with exact evidence. No batch may mark a route visually complete without paired runtime captures.

## Current verified findings vs. pending evidence

- **Verified from source code:** the five deep-diff structures above. Batch 1 removes the music route's generic expansion shell and restores a dedicated player-page layout; metadata/artwork and platform media-service gaps remain open.
- **Not yet verified:** paired runtime screenshots, all remaining route-by-route source diffs, actual reproduction of the blank music screen on device, and Android/Windows visual parity. The latest test-fix commit has not yet completed a fresh full validation and Android/Windows build. No screen is closed by code inspection alone.
- **No screen is declared fully restored by this audit.**


### Dashboard / More responsive parity pass — 2026-11-14

**Pinned GTN1 source:** `app/src/main/assets/web-play/index.html` and `styles.css` at `fe9cf567169e19059e0330d08769fe454336ef94`.

**GTN2 target:** `lib/home/game_dashboard_page.dart` and `test/widget_test.dart`.

- GTN1 desktop content width is 1120px from 720px viewport width and 1280px from 1100px; GTN2's dashboard content cap was 1120px. Raised the Flutter dashboard and More content caps to 1280px so the wide desktop layout can use the source width.
- GTN1's Play screen uses a two-column grid at 720px, but the Bot Arena is the one half-column card while the hero, guess, stats, economy and quick actions span the full row. GTN2 had made the Bot Arena full width; it now uses half the available width at 720px+ and full width below that breakpoint. Added a keyed widget assertion for the desktop width.
- GTN1 More has a full-width Player Profile card above the link grid; GTN2 had placed it as the first item inside the two-column grid. It is now full width and separate from the reorderable 18-link list, matching the source's separation of profile from `.more-links`.
- GTN1 More links use two columns above 520px and one column at 520px or below. Flutter's breakpoint was 640px; it now uses the source 520px breakpoint. Added a 600px widget test checking profile width and side-by-side Rewards/Journey cards.
- The More link card dimensions, minimum heights, padding and 42px/40px icon sizes were compared with source CSS and already align; no unnecessary redesign was made.
- The More route now keeps the same global game-brand/offline header as the Play screen instead of introducing a separate More app bar. Its Player Profile card remains full width and is not part of the Menu Studio reorderable link set.
- GTN1 stacks the two quick actions on mobile and splits them into two columns from 720px. Flutter previously used a side-by-side row at every width; it now follows the source breakpoint. Hero height/padding/type scale, stats spacing/type, wallet typography, guess-button width and quick-action icon/card metrics were also adjusted to the source desktop/mobile tokens. Tests assert mobile stacking and desktop columns.

**Still open:** GTN1 includes a conditional Update Available notice at the top of Play; an equivalent conditional dashboard notice has not been verified in GTN2. Compare its update-state source with the Flutter updater before adding UI. Also verify the debug-build card and Creative Save tools placement against the native GTN1 routes. No paired Android/Windows runtime screenshots have been captured, so Batch A remains open.
