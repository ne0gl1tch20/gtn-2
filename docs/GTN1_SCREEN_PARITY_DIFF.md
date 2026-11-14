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
- **GTN1 structure observed:** Scaffold/app bar titled “Settings & Save Management”; scrollable page; Game Preferences section with dropdown; Theme Appearance dropdown; Theme Colors card with preset/custom controls and color pickers; Number Notation dropdown; reminder frequency and notification category switches; audio/haptics controls; Reduce Flashes and Reduced Motion; volume sliders.
- **GTN2 finding:** a native settings page exists, but its presence and settings-field coverage do not prove matching grouping, order, copy, layout or states. Full line-by-line structure diff and paired screenshots remain open.

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
- **GTN2 finding before Batch 1:** `_openMusic()` opened an expanded `ExpansionTile` inside a generic systems page. **Batch 1 change:** the music view now branches to its own app-bar/body shell and renders player content directly, with a 220px artwork-placeholder surface, current-track title, playback controls, seek/progress, library, queue and playlist controls. This restores the dedicated page structure but is not full parity: the artwork is still a generic icon, track artist/album/duration metadata is not extracted, and Android background media-service/notification lifecycle is not implemented. The reported blank screen still needs runtime reproduction and widget/device verification.

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
- **Not yet verified:** paired runtime screenshots, all remaining route-by-route source diffs, actual reproduction of the blank music screen on device, and Android/Windows visual parity.
- **No screen is declared fully restored by this audit.**
