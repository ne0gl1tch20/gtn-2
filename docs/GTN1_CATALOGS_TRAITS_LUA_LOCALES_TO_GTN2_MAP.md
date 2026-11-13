# GTN1 catalogs, traits, Lua and locales → GTN2 runtime map

**Authority:** GTN1 `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**GTN2 snapshot inspected:** `main` at `29298112e7d27ef34ba488378ba61b78a1b805c8`  
**Inventory authority:** `docs/GTN1_SOURCE_INVENTORY.json`  
**Trait ID map:** `docs/GTN1_TRAIT_ID_MAP.json`

## 1. Seventeen game JSON catalogs

The source inventory has 17 JSON catalogs. GTN2 currently tracks 8 catalog files byte-for-byte identical to GTN1 (same Git blob SHA). The other 9 are not committed as individual files, but `scripts/sync_gtn1_assets.sh` copies the complete pinned GTN1 `assets/game/` directory before build/test and `scripts/verify_gtn1_assets.py` now checks the exact 17-name set and parses every JSON file.

| GTN1 catalog | GTN2 asset/build availability | Runtime destination / status |
|---|---|---|
| `achievements.json` | CI-synced from pinned GTN1; not tracked in the repo's `assets/game/` tree. | `lib/core/progression/achievement_catalog.dart` contains a static Dart catalog instead of loading the JSON. Partial — compare all rows/rewards and switch to canonical asset loading or document why static generation is intentional. |
| `challenges.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/legacy/legacy_systems_page.dart`; transactions in `lib/core/legacy/legacy_systems_engine.dart`. Partial — challenge catalog is loaded, but all claim/reward/eligibility behavior needs source comparison. |
| `feature_flags.json` | CI-synced; not tracked individually. | No Dart feature-flag repository or runtime consumer identified. Gap — source flags are not mapped to runtime decisions. |
| `game_config.json` | CI-synced; not tracked individually. | Game defaults/rules are embedded in Dart game/economy code; no data-driven config loader identified. Partial — compare every source setting/default and decide whether canonical asset loading is required. |
| `guess_feedback_messages.json` | CI-synced; not tracked individually. | `lib/i18n/app_localizations.dart` loads locale key/value overlays, but no randomized low/high message pool consumer was identified. Gap/partial — source's 30 low and 30 high feedback messages are not proven to be used. |
| `liveops_manifest.json` | CI-synced; not tracked individually. | No LiveOps manifest repository/claim consumer found. Gap — schedule, eligibility, claim caps and settlement remain unimplemented. |
| `minigames.json` | Tracked; byte-identical to GTN1. | `lib/arcade/arcade_catalog.dart` loads and validates the catalog; `lib/arcade/arcade_page.dart` renders games. Partial — catalog is wired, but every minigame's actual play/reward behavior must be verified. |
| `mutators.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/legacy/legacy_systems_page.dart`; rules in `LegacySystemsEngine`. Partial — four mutator rule multipliers are tested; full source options and challenge-builder behavior remain open. |
| `prestige_shop.json` | CI-synced; not tracked individually. | No Dart consumer for this shop catalog identified. Gap — source Prestige shop inventory is not proven to be represented by `prestige_upgrades.json`. |
| `prestige_upgrades.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/shop/upgrade_catalog.dart`; progression/effects in `lib/core/progression/`. Partial — only verified gameplay effects appear in the shop; every source upgrade/effect needs mapping. |
| `relics.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/legacy/legacy_systems_page.dart`; ownership/equip/effects in `LegacySystemsEngine`. Partial — catalog is wired; set bonuses, rarity and proc effects need complete source verification. |
| `shop_items.json` | CI-synced; not tracked individually. | No direct Dart asset consumer identified for the canonical item catalog. Gap/partial — compare the full Nebula shop catalog to current `lib/shop/nebula_shop_page.dart` and engine transactions. |
| `talents.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/legacy/legacy_systems_page.dart`; purchase rules in `LegacySystemsEngine`. Partial — catalog and prerequisites load; complete six-node graph and actual effect parity remain open. |
| `ultra_shop.json` | CI-synced; not tracked individually. | No direct Dart asset consumer identified. Gap — source Ultra shop catalog is not proven to be represented by `ultra_upgrades.json`. |
| `ultra_upgrades.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/shop/upgrade_catalog.dart`; progression/effects in `lib/core/progression/`. Partial — compare every source upgrade, cost and effect; current shop exposes only verified effects. |
| `upgrades.json` | Tracked; byte-identical to GTN1. | Loaded by `lib/shop/upgrade_catalog.dart`; `GuessEconomyRules` and `ProgressionEngine`. Partial — only a subset is currently marked gameplay-implemented; other source catalog entries are not exposed as working upgrades. |
| `worlds.json` | CI-synced; not tracked individually. | `lib/worlds/world_boss_catalog.dart` contains a static Dart world/boss catalog rather than loading this JSON. Partial — compare all fields, unlock paths and rewards; the canonical JSON is not the runtime source of truth yet. |

**Observed tracked-asset split:** 8/17 exact files are committed; 9/17 are materialized by the pinned-source sync step. This is compatible with CI builds because both Build and Validate run `sync_gtn1_assets.sh` before `flutter pub get`/tests. A local developer must run the sync script before testing/building; the source JSONs are not all present in a fresh checkout.

## 2. All 320 stable trait IDs

- GTN1 `app/src/main/java/com/jarrlyyy/guessthenumber/traits/BuiltInTraits.kt` contains 320 unique stable IDs.
- GTN2 `lib/core/legacy/builtin_trait_catalog.dart` contains 320 unique IDs.
- A direct set comparison found **320/320 exact matches**, with no missing or extra IDs.
- Every pair is recorded in `docs/GTN1_TRAIT_ID_MAP.json` as `sourceId → dartId`.
- The 320 package definitions are separate from the stable-ID catalog. `scripts/sync_gtn1_assets.sh` copies the complete pinned `traits/` tree (expected 320 `trait.json`, 320 `rules.json`, 320 `icon.svg`, 320 `locales/en.json` plus support files), then runs `scripts/generate_trait_manifest.py`.
- `scripts/verify_gtn1_assets.py` checks the 320 package counts, manifest uniqueness, required package paths and source commit. It now also compares the generated package manifest IDs against both the 320-entry source/Dart ID map and the Dart built-in catalog before builds/tests proceed.
- `TraitCatalogRepository` validates the generated manifest and reads each package's definition, rules and English localization in bounded batches. `LegacySystemsPage` loads the repository for the trait catalog UI.

**Behavioral status: partial, not complete.** `LegacySystemsEngine.evaluateTraits` still reads `builtInTraitCatalog` directly and derives a bounded effect summary with a small set of hardcoded gameplay trait IDs. It does not consume every loaded `TraitCatalogEntry`/package effect at gameplay time. Exact stable IDs and package availability do not prove all 320 trait activation/effect definitions are implemented. This remains a Stage 2 gameplay parity item.

## 3. Four core Lua scripts

All four source scripts are present in GTN2, declared as Flutter assets and registered exactly once in `assets/scripts/manifest.json`. Direct source/target inspection found their executable Lua bodies unchanged; only host-language comments were adjusted from Kotlin to Dart. GTN2's manifest intentionally registers all four scripts, while the pinned GTN1 script manifest only featured Number Rush.

| GTN1 Lua script | GTN2 destination | Current runtime status |
|---|---|---|
| `events/random_event.lua` | `assets/scripts/events/random_event.lua`; `LuaSandbox`; `RandomEventEngine`; `_runRandomEventTick` in `lib/main.dart` | Integrated — Lua selects an approved event ID; Dart validates it and owns rewards/state. |
| `events/seasonal_events.lua` | `assets/scripts/events/seasonal_events.lua`; `LuaSandbox` | Partial — manifest is loaded/compiled in tests, but no production seasonal-event repository/claim transaction consumes it. |
| `minigames/number_rush.lua` | `assets/scripts/minigames/number_rush.lua`; `LuaSandbox`; Arcade catalog/page | Partial — script output is validated in sandbox tests; the live Arcade flow does not yet use this Lua presentation model as its activity renderer/round source. |
| `traits/invisible_traits.lua` | `assets/scripts/traits/invisible_traits.lua`; `LuaSandbox`; `InvisibleTraitEngine` | Partial — script is executed and its output validated in tests; the live adaptive trait engine currently computes its own Dart decisions rather than consuming the Lua selector output. |

The manifest and sandbox tests verify registration, unique script IDs, asset existence, bounded execution and valid result shapes. Registration/compilation is not counted as gameplay integration. See `docs/LUA_SANDBOX_HOST_API.md` for the remaining adapter sequence.

## 4. Twenty-three locale files

- GTN1 source inventory: 23 locale JSON files.
- GTN2 `assets/locales/`: 23 files.
- Git blob SHA comparison against the pinned source found **23/23 byte-identical locale files**.
- `AppLocalizations.supportedLocales` lists the same 23 locale codes and loads English plus the selected locale overlay.
- `pubspec.yaml` bundles the full `assets/locales/` directory.
- The updated asset verifier checks the exact locale filename set, parses each JSON file and verifies that the Dart supported-locale IDs match the bundled files.

**Behavioral status: partial.** File parity and locale availability are verified, but full user-visible string coverage, plural/format rules, text overflow, RTL layout and per-screen localization remain Stage 4 checks.

## 5. Automated verification changes

The asset verifier now checks:

1. Exact 17-catalog filenames from the pinned source inventory and valid JSON.
2. Exact 23 locale filenames, valid JSON and matching `AppLocalizations` locale IDs.
3. Exact four Lua script paths and exactly-once manifest registration.
4. Exact 320 trait package definitions, rules, icons and English localizations.
5. Trait package manifest IDs equal the committed GTN1→Dart stable-ID map and Dart built-in ID set.

This prevents a green build from silently omitting a catalog, locale, script or trait ID.

## 6. Mapping summary

- **Inventory reconciled:** 17 catalogs, 320 stable trait IDs, four core Lua scripts and 23 locale files.
- **Exact file/data matches:** eight tracked catalogs; all 23 locales; all four Lua script executable bodies (comments differ); all 320 BuiltInTraits stable IDs.
- **CI-materialized content:** the remaining nine catalogs and the 320 trait packages are copied from the pinned GTN1 checkout before validation/build.
- **Confirmed behavioral gaps:** feature flags, LiveOps manifest/claims, randomized feedback message pool, separate Prestige/Ultra/shop catalogs, data-driven worlds/achievements, complete trait package effect runtime, seasonal-event claim integration, Number Rush Lua activity integration and Lua invisible-trait selector integration.
- **Do not infer behavior parity from asset presence.** These gaps stay open in Stages 2–4; this document closes source-to-runtime mapping only.
