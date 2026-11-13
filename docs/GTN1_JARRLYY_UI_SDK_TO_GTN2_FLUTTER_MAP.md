# GTN1 Jarrlyy UI SDK → GTN2 Flutter component/event map

**Authority:** GTN1 `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**GTN2 snapshot inspected:** `main` at `a5968bc9b23d037b687bbdf4968c51572c0e14e4`  
**Inventory:** all 24 files below `app/src/main/assets/libraries/jarrlyyuisdk/`. The count includes runtime assets, demo-only assets, TypeScript source and TypeScript build configuration.

GTN2 intentionally replaces the browser/WebView SDK with native Flutter widgets and Dart callbacks. The SDK's actual user-facing interactions still need equivalents; the JavaScript/CSS/TypeScript implementation itself is not a required runtime dependency in Flutter.

## 1. Runtime files loaded by GTN1 Web Play

The pinned `web-play/index.html` loads the SDK core, advanced runtime, host adapter, particle renderer and DOM utilities. It loads core/advanced stylesheets in the document head. The SDK icon sprite is referenced by the SDK component lab; the game shell also contains its own inline SVG sprite.

| GTN1 SDK file | Runtime responsibility | GTN2 native destination | Mapping |
|---|---|---|---|
| `components/jarrlyy-ui.js` | Core declarative enhancement; toast/status region; accessible dialogs; guided tours; context menus; carousels; pagination; sortable tables; charts; timers; dropzones; action buttons; reveal helpers; numeric count/progress/float-text motion; keyboard shortcut buttons. | `lib/design/expressive_widgets.dart`; `lib/settings/`; `lib/home/`; `lib/progression/`; `lib/legacy/`; `lib/arcade/` and page-specific Flutter callbacks. | Partial — native buttons, dialogs, progress and motion exist; no complete one-to-one inventory for tours, context menus, pagination, tables/charts, dropzones, float-text and keyboard shortcuts. |
| `components/jarrlyy-ui-advanced.js` | Accessible tabs, segmented controls, dual-thumb range groups, overlay/drawer lifecycle, dismissible banners, loading buttons and progress updates; keyboard navigation and bubbling `jui:*` events. | `lib/design/expressive_widgets.dart`; Flutter `TabBar`, segmented controls, sliders, dialogs/sheets, banners, progress indicators and callbacks in relevant pages. | Partial — native equivalents exist; compare every event detail, keyboard behavior, focus restoration and disabled/loading state. |
| `components/jarrlyy-ui-dom-utils.js` | Host-neutral `humanize`, safe/idempotent text update, reduced-motion preference detection and accessible SVG icon-button labeling. | `lib/i18n/app_localizations.dart`; Flutter text widgets, `Semantics`, `IconButton` tooltips and `MediaQuery.disableAnimations`/settings motion preference. | Partial — Dart has localization, semantic labels and reduced-motion settings; exact helper behavior and all call sites need comparison. |
| `components/jarrlyy-ui-host.js` | Mounts SDK layers; sets light/dark/system theme; validates and subscribes/emits bubbling `jui:*` events; returns unsubscribe callbacks. | `lib/settings/game_settings.dart`; theme setup in `lib/main.dart`; typed callbacks/actions in page widgets and domain engines. | N/A for JavaScript host adapter — no WebView is used. Theme/event contracts still need to be represented by typed Dart state/callbacks, not a replacement JS bridge. |
| `components/jarrlyy-particle-effects.js` | Vue/Pixi renderer with canvas fallback; particle bursts; resize/visibility lifecycle; reduced-motion preference; renderer disposal. | Dashboard visual effects in `lib/home/game_dashboard_page.dart` (including `_HeroSparkle`) and Flutter animation primitives in `lib/design/expressive_widgets.dart`. | Partial/gap — a small native sparkle treatment exists, but the source particle-burst API, Pixi/canvas fallback, event-driven burst effects and lifecycle are not equivalent. |
| `styles/jarrlyy-ui.css` | Core design tokens, typography, root touch/focus behavior, cards, rows/stacks, buttons, forms, switches, tooltips, badges, overlays, toast/dialog, progress and motion utility styles. | `lib/design/expressive_widgets.dart`; app theme and GTN1 tokens in `lib/settings/game_settings.dart`; page-level native Flutter styles. | Partial — cosmic palette and reusable surfaces are represented; CSS class-by-class visual/interaction coverage is still part of Stage 4. |
| `styles/jarrlyy-ui-advanced.css` | Advanced control/overlay styling for tabs, segmented controls, toolbars, accordions, sliders, banners, sheets, loading states and progress. | `lib/design/expressive_widgets.dart`; Flutter controls and native page widgets. | Partial — native controls exist; all source states, focus, responsive and reduced-motion variants need comparison. |
| `icons/jarrlyy-icons.svg` | Small reusable SVG symbol sprite for the SDK's demo/component lab. | Native Flutter `Icon`/custom asset rendering; GTN1 Web Play also has its own inline icon sprite. | Partial/N/A for direct sprite loading — the HTML sprite transport is not used in Flutter; compare any icon that is actually used by a production screen rather than porting unused demo symbols. |

## 2. TypeScript source and build configuration (9)

These files author or export the generated JavaScript SDK. They are build/development sources, not runtime assets GTN2 must ship.

| GTN1 SDK file | Source responsibility | GTN2 equivalent | Mapping |
|---|---|---|---|
| `typescript/runtime/jarrlyy-ui.ts` | Typed source for generated `components/jarrlyy-ui.js`; core enhancement, overlay, toast/dialog/tour, carousel/table/chart/timer/dropzone/action and motion APIs. | Native Flutter widgets/callbacks in `lib/design/expressive_widgets.dart` and the corresponding page/domain files. | Partial — behavior map is in row above; no TS runtime is required in Flutter. |
| `typescript/runtime/jarrlyy-ui-advanced.ts` | Typed source for generated advanced controls and `JarrlyyUIAdvanced` API. | Flutter tabs, segmented controls, sliders, overlays, banners and progress controls. | Partial — native controls exist; exact event/focus behavior remains open. |
| `typescript/src/advanced-utils.ts` | Typed `setLoading` and `setProgress` helpers, including ARIA values and label/disabled restoration. | Flutter button loading/disabled state and semantic progress indicators in `lib/design/expressive_widgets.dart`. | Partial — native state equivalents exist; verify original label/disabled restoration and progress semantics where used. |
| `typescript/src/dom-utils.ts` | Typed DOM text, humanization, reduced-motion and SVG icon-button helpers. | `lib/i18n/app_localizations.dart`; Flutter widgets/semantics and motion preferences. | Partial — behavior maps to native framework features, not a DOM helper library. |
| `typescript/src/host-adapter.ts` | Typed host root/theme/event lifecycle API. | Theme state in `lib/main.dart`/settings and Dart callbacks. | N/A for DOM host lifecycle; map the theme and event contracts to native Flutter. |
| `typescript/src/index.ts` | Public TypeScript module exports/types for DOM helpers, host adapter and advanced utilities. | No package export barrel needed; equivalent public surface is the app's Dart widget/domain APIs. | N/A — implementation-language/package export structure is not a Flutter runtime feature. |
| `typescript/package.json` | Pins TypeScript compiler and scripts for typecheck/build of SDK bundles. | Flutter/Dart toolchain in `pubspec.yaml`, `.github/workflows/validate.yml` and `.github/workflows/build.yml`. | N/A — no TypeScript SDK build is needed once the browser runtime is removed. Flutter format/analyze/tests are the native verification surface. |
| `typescript/tsconfig.json` | Compiles reusable typed helper modules to ES modules/declarations. | Dart analyzer/compiler configuration in `analysis_options.yaml` and `pubspec.yaml`. | N/A — TypeScript module output is not used by GTN2. |
| `typescript/tsconfig.core.json` | Emits classic-script core runtime from `runtime/jarrlyy-ui.ts`. | No JS runtime build; Flutter compiles Dart directly. | N/A — generated classic script is intentionally not shipped. |
| `typescript/tsconfig.runtime.json` | Emits classic-script advanced runtime from `runtime/jarrlyy-ui-advanced.ts`. | No JS runtime build; Flutter compiles Dart directly. | N/A — generated classic script is intentionally not shipped. |

## 3. Demo-only and documentation files (7)

| GTN1 SDK file | Purpose | GTN2 mapping |
|---|---|---|
| `README.md` | SDK installation, curated components and public API documentation. | Reference only; no runtime feature. |
| `components/demo.js` | Component-lab event wiring for volume and motion/font previews. | N/A — demo-only. |
| `demo.html` | Standalone component gallery with local sample data. | N/A — GTN2 does not ship a separate SDK gallery. |
| `motion-demo.js` | Demo wiring for count/progress/float-text motion examples. | N/A — demo-only; the production motion behavior is mapped to Flutter animation primitives above. |
| `styles/demo.css` | Component-gallery layout and demo-only styling. | N/A — not a production GTN1 game screen stylesheet. |
| `typescript/README.md` | TypeScript build instructions and API source-of-truth notes. | Reference only; no runtime feature. |

## 4. Inventory reconciliation and open behavior

- **24/24 files reviewed:** 8 runtime/presentation assets, 9 TypeScript source/build files, and 6? demo/documentation files. The pinned tree's exact 24-file list is the authority; the grouped rows above should be read as a file inventory, not a claim that every demo artifact ships in the production Web Play shell.
- **Production runtime usage confirmed from the pinned `index.html`:** core CSS, advanced CSS, core JS, advanced JS, host adapter, trait extension host, Vue/Jarrlyy adapter, Vue runtime, Pixi runtime, particle effects, bot arena, DOM utilities, `app.js` and Menu Studio.
- **Confirmed partial behavior:** dialogs/toasts/tours, controls/events, focus and keyboard semantics, progress/motion, particle bursts, icon semantics, reduced motion and all CSS visual treatments.
- **Intentional N/A:** DOM/HTML/Vue host transport, TypeScript compilation and standalone SDK demo gallery. This does not mark the equivalent player-facing behavior complete.
- **No JS runtime should be added to GTN2** to close these gaps. Implement the missing behavior with Dart/Flutter widgets and typed callbacks.

**Next Stage 1 item:** map all 17 GTN1 catalogs, 320 trait IDs, four Lua scripts and 23 locales from the source manifest to their GTN2 runtime destinations.
