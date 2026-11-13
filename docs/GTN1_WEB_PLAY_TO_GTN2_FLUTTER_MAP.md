# GTN1 Web Play shell → GTN2 native Flutter route and module map

**Authority:** GTN1 `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**GTN2 snapshot inspected:** `main` at `26a0ee94fb30eedba4754715a9b7a40af9e3540d`  
**Source files:** one `web-play/index.html` shell, one `styles.css`, five JavaScript modules and supporting SVG icons/seasonal artwork.

This map records the actual Web Play shell structure and the Dart destinations that replace its UI/runtime. GTN2 intentionally uses native Flutter widgets and Dart domain actions; it must not embed this HTML, a WebView or a second JavaScript gameplay runtime.

## 1. HTML shell and route inventory

The pinned `index.html` is a single 104,250-character application shell. It contains **22** `data-screen` roots, not 22 independent HTML pages. The root IDs below were extracted from the pinned HTML and checked against the current Dart tree.

| GTN1 root ID | Responsibility | GTN2 native destination | Mapping |
|---|---|---|---|
| `play` | Main guess dashboard, input, feedback, stats, wallet, quick actions and bot arena | `lib/home/game_dashboard_page.dart`; orchestration in `lib/main.dart` | Partial — playable dashboard exists; full desktop/mobile screenshot and interaction comparison remains open. |
| `worlds` | World map, guardians, unlock progression and boss entry | `lib/worlds/world_map_page.dart`; `lib/worlds/world_boss_battle_engine.dart` | Partial — map and engine exist; exact card/map composition and all source interactions need comparison. |
| `arcade` | Minigame catalog, active game, score and reward settlement | `lib/arcade/arcade_page.dart`; `lib/arcade/arcade_catalog.dart`; `lib/arcade/arcade_reward_rules.dart` | Partial — native page/catalog exist; every individual game and reward outcome must be checked. |
| `upgrades` | Money upgrade catalog and purchase controls | `lib/shop/upgrade_shop_page.dart`; `lib/shop/upgrade_catalog.dart` | Partial — catalog and purchase UI exist; complete source catalog and visual comparison remain open. |
| `more` | Profile entry and grouped secondary destinations | More/navigation state in `lib/main.dart`; profile/save surfaces in `lib/saves/save_slots_page.dart` | Partial — route/navigation exists; full More landing layout and profile destination are not merged on current main (PR #72 is open). |
| `rewards` | Daily Nebula rewards, streak, schedule and claim feedback | `lib/legacy/legacy_pages.dart`; claim transactions in `lib/core/legacy/legacy_systems_engine.dart` | Partial — claim path exists; exact reward schedule, streak and claim-limit cases need source verification. |
| `journey` | Run history, progress and playtime summary | `lib/legacy/legacy_pages.dart` | Partial — native section exists; metric definitions, ordering and empty states need comparison. |
| `shop` | Nebula item catalog, owned/equipped state and purchases | `lib/shop/nebula_shop_page.dart` | Partial — shop page exists; full item catalog, source descriptions and interactions remain open. |
| `homebase` | Home Base/Sanctuary level and restoration bonuses | `lib/progression/progression_hub_page.dart`; `lib/legacy/legacy_systems_page.dart` | Partial — upgrade engine exists; dedicated source layout and every reward/discount effect need comparison. |
| `relics` | Relic collection, rarity, equipment slots and set effects | `lib/legacy/legacy_systems_page.dart`; `LegacySystemsEngine.equipRelic` | Partial — inventory/equip logic exists; catalog metadata, visual slots and every set/proc case need verification. |
| `codex` | Discovery collection, completion and claim-once rewards | `lib/legacy/legacy_pages.dart`; world/secret state | Partial — native codex destination exists; search/filter, completion and claim-once behavior need comparison. |
| `changelog` | Changelog content and Markdown rendering | `lib/legacy/legacy_pages.dart`; `assets/changelogs.md` | Partial — canonical content is bundled; parser fidelity, headings, links and empty/error states need comparison. |
| `about` | App details, source/social links, licenses and updater | `lib/legacy/legacy_pages.dart`; `lib/data/updates/update_checker.dart` | Partial — About and updater surfaces exist; dependency license inventory and complete source metadata remain open. |
| `music` | Library/import, metadata, playback, seek, queue, playlists, shuffle and repeat | `lib/legacy/legacy_systems_page.dart`; `lib/core/music/music_playback_policy.dart`; `lib/settings/music_settings_sync.dart` | Partial — foreground playback/queue exists; metadata, app lifecycle, media controls and background service remain open. |
| `settings` | Gameplay, notation, appearance, colors, audio, haptics, notifications, accessibility and Menu Studio | `lib/settings/settings_page.dart`; `lib/settings/game_settings.dart`; `lib/settings/menu_studio_page.dart` | Partial — settings persist/render; notification delivery, scheduled update checks, tutorial replay and Menu Studio cross-area movement remain open. |
| `prestige` | Prestige reset, currency, upgrades and shop | `lib/progression/progression_hub_page.dart`; progression engine | Partial — transaction destination exists; exact UI, reset carry-over and all effects need comparison. |
| `ultra` | Ultra progression/reset/upgrades | `lib/progression/progression_hub_page.dart`; progression engine | Partial — transaction destination exists; exact UI, reset carry-over and all effects need comparison. |
| `talent` | Talent tree, prerequisites, purchase and effects | `lib/legacy/legacy_systems_page.dart`; `assets/game/talents.json` | Partial — canonical catalog and purchase engine exist; six-node graph layout and complete effect parity remain open. |
| `traits` | Traits/loadout, discovery, activation and selectable arms | `lib/legacy/legacy_systems_page.dart`; `lib/core/legacy/trait_catalog_repository.dart`; `lib/core/legacy/legacy_systems_engine.dart` | Partial — all 320 packaged IDs and a native section exist; runtime package/effect and extension UI parity remain open. |
| `mutators` | Mutator selection, stacked rules and challenge configuration | `lib/legacy/legacy_systems_page.dart`; `LegacySystemsEngine` | Partial — four mutator rules exist; full challenge-builder controls and source interaction parity remain open. |
| `stats` | Accuracy, guesses, currencies, playtime, streak, Arcade and boss metrics | `lib/legacy/legacy_pages.dart`; `ProgressionState` | Partial — statistics destination exists; every source metric/formula and layout needs comparison. |
| `stake` | Lucky Stake eligibility, wager, 50/50 outcome and payout | `lib/legacy/legacy_systems_page.dart`; `LegacySystemsEngine.settleLuckyStake` | Partial — source payout formula is represented and tested; random settlement, validation and visual feedback need full verification. |

### Additional route/action IDs

The pinned HTML also uses the following `data-route` values. They are action destinations/overlays, not additional `data-screen` roots.

| GTN1 route ID | GTN2 destination | Mapping |
|---|---|---|
| `player_profile` | Save-backed profile metadata in `lib/data/saves/save_data.dart`; editor surface in `lib/saves/save_slots_page.dart` | Partial — current main only has five icon IDs/name metadata; expanded profile editor is in open PR #72 and is not merged. |
| `save_slots` | `lib/saves/save_slots_page.dart`; `lib/data/saves/save_storage.dart` | Partial — native slots exist; compare all source slot actions and global-vs-slot preferences. |
| `world_map` | `lib/worlds/world_map_page.dart` | Mapped destination; full visual behavior remains in Stage 4. |
| `home_base` | `lib/progression/progression_hub_page.dart`; `lib/legacy/legacy_systems_page.dart` | Partial |
| `prestige` | `lib/progression/progression_hub_page.dart` | Partial |
| `ultra` | `lib/progression/progression_hub_page.dart` | Partial |
| `relics` | `lib/legacy/legacy_systems_page.dart` | Partial |
| `codex` | `lib/legacy/legacy_pages.dart` | Partial |
| `color_picker_primary`, `color_picker_secondary`, `color_picker_tertiary` | Custom color controls in `lib/settings/settings_page.dart`; dialogs/adapters in `lib/design/expressive_widgets.dart` | Partial — color selection exists; exact source picker gestures, presets and accessibility need comparison. |

The HTML also declares a `dev_settings` navigation target, which has no separate HTML screen root in the 22-root list. Its Flutter destination is `lib/dev/developer_settings_page.dart`.

## 2. Five JavaScript modules

| GTN1 module | Source responsibilities inspected | GTN2 destination | Mapping |
|---|---|---|---|
| `app.js` | Screen activation; state/bridge request flow; catalog and currency rendering; worlds/rewards; tutorials; music; stats; stake; changelog; settings; feedback; creative upgrade display; seasonal presentation; bot arena state; progression screens; trait loadout; arcade lifecycle/rewards; reset dialogs; queued native popup/screen-state responses. | Native Dart UI in `lib/main.dart`, `lib/home/game_dashboard_page.dart`, `lib/progression/progression_hub_page.dart`, `lib/legacy/legacy_pages.dart`, `lib/legacy/legacy_systems_page.dart`, `lib/arcade/`, `lib/settings/`, `lib/shop/`, `lib/worlds/`; state/rules in the corresponding `lib/core/` services. | Partial — the major destination and domain services exist; no line-by-line action/function map or complete user-action parity proof exists yet. |
| `menu-studio.js` | Reorders top-bar/More destinations; per-button colors; drag/drop and pointer reorder; live preview; reset; save/cancel; host state request and preference persistence. | `lib/settings/menu_studio_page.dart`; `lib/settings/game_settings.dart`; navigation in `lib/main.dart`. | Partial — reorder/color/reset/persist exist; GTN2 pins core navigation entries and does not yet reproduce all source cross-area movement and preview behavior. |
| `trait-extension-host.js` | Runs a trait-provided JavaScript UI module inside a sandboxed iframe with `render_ui`/`show_local_message` capabilities, constrained DOM text updates, bounded messages and disposal. | `lib/core/legacy/trait_extension_runtime.dart`; `lib/core/scripting/lua_sandbox.dart`. | Gap/partial — GTN2 validates module declarations and treats JavaScript as presentation data but does not execute/render the source JavaScript UI module. This is a real source capability gap, not a WebView bridge N/A. |
| `vue-bot-arena.js` | Vue canvas arena; bot avatars/ranges; active bot state; typed guess reveal; feedback; resize handling; animation-frame lifecycle; hidden-tab/reduced-motion handling. | Bot arena widget in `lib/home/game_dashboard_page.dart`; `lib/core/automation/bot_team.dart`; `lib/core/automation/guessing_bot.dart`. | Partial — a native bot arena widget and real bot state exist; compare visuals, typing cadence, reduced-motion and visibility lifecycle. |
| `vue-jarrlyy-adapter.js` | Vue/Jarrlyy button component; safe variant selection; create/mount helpers; toast/dialog wrappers; validated custom event subscription and emission. | `lib/design/expressive_widgets.dart`; Flutter callbacks, dialogs and native state in destination pages. | N/A for Vue component runtime — native Flutter replaces Vue; component props, event names, toast/dialog outcomes and accessibility contracts still need explicit mapping in the SDK audit. |

## 3. Shell-level behavior and security boundary

- The HTML shell declares a restrictive Content Security Policy, disables network connections and hosts local SVG/CSS/JS assets. GTN2 bundles required assets locally and keeps Dart as the sole UI/gameplay runtime.
- The source shell uses data attributes for screen/route activation and host bridge requests. GTN2 uses native Flutter routes and typed callbacks; no WebView or HTML renderer is carried forward.
- Any source action that previously crossed the WebView bridge must still resolve to a validated Dart engine/repository action. A missing action is a parity gap even though the bridge transport itself is N/A.
- The source uses sandboxed iframe JavaScript for trait UI extensions. That capability is distinct from the WebView bridge and is not currently reproduced by merely validating/retaining JavaScript module text.

## 4. Mapping summary

- **Inventory reconciled:** one HTML shell, 22 screen roots, the enumerated special route/action IDs and all five JavaScript modules.
- **Destinations identified:** all 22 roots and special route IDs have a Dart destination or an explicit gap/partial status.
- **Confirmed module gap:** trait extension JavaScript UI modules are not executed/rendered in GTN2.
- **Partial behavior groups:** app.js actions, Menu Studio cross-area layout, bot arena animation/lifecycle, Vue/Jarrlyy event contracts, player profile route, and all screen-level visual/interaction comparisons.
- **Do not infer parity from a destination existing.** The screen-by-screen Stage 4 checklist and the feature-specific Stage 2/3/5 checklists remain authoritative.

**Next Stage 1 item:** map the 24 Jarrlyy UI SDK files to the Flutter components/events actually used by the 22 screens.
