# GTN2 UI parity plan: GTN1 HTML/CSS/JavaScript

## Authority and scope

- GTN1 `app/src/main/assets/web-play/index.html`, `styles.css`, and `app.js` are the behavioral and visual reference.
- GTN2 remains a native Flutter/Dart implementation. Reproduce the existing screen model and interactions in Dart; do not embed the old WebView as a shortcut.
- Preserve the existing Dart game engine, progression, save data, validation, and persistence.
- `jarrlyyui_engine` is explicitly postponed. Do not resume implementation or integration as part of this work.

## Main-screen architecture

GTN1 has one application shell with five persistent primary destinations:

1. Beyond the Numbers (`worlds`)
2. Arcade (`arcade`)
3. Play (`play`)
4. Upgrades (`upgrades`)
5. More (`more`)

The primary navigation selects a screen in the shared shell. It must not push a separate full-page route that removes the navigation bar. More is a hub screen within the shell. Its cards select additional screen panels such as Rewards, Journey, Shop, Home Base, Relics, Codex, Changelog, Music, Settings, Prestige, Ultra, Talents, Traits, Mutators, Stats, and Lucky Stake.

Use an explicit screen identifier and a screen history/parent relationship for nested destinations. A nested screen opened from More returns to More, not to an unrelated default tab. Selecting a primary destination changes the active primary tab. Keep each destination's state alive where practical (for example with an IndexedStack or nested navigator) so returning does not reset scroll position or transient state.

Route-only destinations such as Save Slots, Player Profile, color pickers, and Dev Settings may use nested detail routes, but the application shell and primary navigation remain present. Back/Escape should pop the nested detail route first, then return to its parent screen.

## More hub behavior

- More is a screen in the shared shell, not a standalone `MaterialPageRoute`.
- Cards for destinations already represented in the five primary tabs should activate the corresponding screen in the same shell.
- Other cards should activate their own sub-screen in the same shell.
- Preserve user-configured More ordering and per-item accent colors.
- Keep developer-only entries gated by debug mode.
- Every visible card must lead to its actual feature. Do not map unrelated entries to one generic hub merely to make them clickable.

## Settings organization

Match GTN1's settings groups and preserve all existing setting behavior:

1. Language & Numbers: locale and number notation.
2. Appearance: theme mode, theme preset, and primary/secondary/tertiary custom colors.
3. Audio & Haptics: background music, sound effects, vibration, master volume, and SFX volume.
4. Notifications: master enable, reminder frequency, reminder notifications, progression milestones, and game events.
5. Updates: automatic check interval, manual check, and update actions/status.
6. Accessibility: reduced motion and reduced flashes.
7. Help & Tutorial: Nimmy help/tutorial actions.
8. Destructive actions: keep reset actions visually separated and require clear confirmation.

A setting change must update the existing settings model, persist through the existing save path, and update the UI immediately. Detailed editors (for example custom color selection) may be nested detail screens with a clear Back action.

## GTN2 visual direction: GTN1 evolved with Material 3 Expressive

The product goal is an improved, recognizable GTN1, not a generic Material app and not a visual reinvention. GTN1 remains the source of truth for game identity, terminology, screen hierarchy, feature placement, and interaction meaning. Material 3 Expressive is the visual and interaction system used to modernize that identity.

### Non-negotiable design rules

- Preserve GTN1's recognizable color language, game vocabulary, progression identity, and screen hierarchy.
- Apply Material 3 Expressive consistently: expressive rounded shapes, tonal surfaces, stronger type hierarchy, adaptive navigation, expressive controls, meaningful motion, and clear selected/focus states.
- Keep game information dense enough to be useful, but give important actions and progression feedback clear visual priority.
- Use accent colors to communicate feature identity and state, not as decoration on every element.
- Support dark and light themes, compact phones, larger phones, tablets, and Windows desktop layouts.
- Respect reduced-motion settings and accessibility semantics.
- Avoid generic dashboard templates, random gradients, excessive glow, tiny uppercase-only labels, and one-off styling that does not belong to the shared design language.

### GTN1 reference audit cadence

The source of truth for visual and interaction comparisons is the live GTN1 Web Play implementation:

- `app/src/main/assets/web-play/index.html` for screen structure, navigation labels, content order, semantics, and control names.
- `app/src/main/assets/web-play/styles.css` for the visual tokens, typography, surfaces, spacing, breakpoints, hover/active states, and reduced-motion behavior.
- `app/src/main/assets/web-play/app.js` for screen routing, action semantics, state-driven rendering, feedback, and keyboard/accessibility behavior.

Re-check all three files at the start of each primary-destination pass and again before calling that destination visually complete. For secondary screens, inspect the relevant HTML section, CSS selectors, and JS renderer before styling or changing interactions. Revisit the source whenever a mismatch is found; do not rely on an old screenshot or a previous inspection.

The current responsive targets follow GTN1's compact single-column phone layout and its wider two-column dashboard/catalog layouts. Validate at compact phone width, standard phone width, tablet width, and resizable Windows desktop width. Reduced-motion and semantic labels remain part of the acceptance pass.

## Implementation sequence

1. **Design foundation and Play dashboard:** establish shared GTN1-derived tokens and expressive component patterns; polish the current-run hero, guess interaction, stats, wallet, and automation panel.
2. **Persistent navigation and primary destinations:** verify the five GTN1 destinations and apply the same design language to Beyond the Numbers, Arcade, Play, and Upgrades.
3. **More hub and secondary screens:** modernize More, then Rewards, Journey, Shop, Home Base, Relics, Codex, Changelog, Music, Settings, Prestige, Ultra, Talents, Traits, Mutators, Stats, and Lucky Stake.
4. **Consistency and responsive pass:** compare matching GTN1/GTN2 viewports, remove visual drift, and verify phone and Windows layouts.
5. **Interaction and accessibility pass:** test navigation, nested Back behavior, state retention, focus, semantics, reduced motion, and every visible action.

Do not treat a screenshot resemblance as sufficient: every GTN1 control and navigation interaction needs a corresponding Dart behavior and test. A screen is not complete merely because it has been restyled; its real feature behavior must remain connected.

## Validation gates

- Widget tests cover primary-tab selection, More-to-subscreen navigation, nested Back behavior, state retention, settings grouping, and key GTN1 interactions.
- Existing game/progression/save tests remain green.
- Run formatter, analyzer, all tests, Android debug build, and Windows desktop build.
- Do not merge until all required validation is green.

## Windows packaging and icon policy

- Pull-request CI builds and validates the Windows desktop app; it does not need to publish an installer for every PR.
- Main-branch debug output should include a portable Windows ZIP.
- Distributable Windows builds should produce an Inno Setup installer, with an optional portable ZIP alongside it.
- Use the existing `assets/gtn1/gtn-app-logo.png` as the canonical GTN artwork. Generate platform-specific Android launcher icon assets and Windows `.ico` from that source. Use the same Windows icon for the executable and Inno Setup installer. Do not substitute Flutter's default icon or unrelated generated artwork.
