# GTN 2 architecture

## Boundaries
- `lib/core/`: deterministic game rules and exact value types. No Flutter imports.
- `lib/data/`: serialization, persistence and save migrations.
- `lib/features/`: Flutter screens and user interaction.
- `test/`: unit and widget tests.

Systems from the original game will be reimplemented behind explicit interfaces rather than copied wholesale.

## Reliability rules
1. Gameplay decisions live in Dart domain code, not widgets.
2. Currency and progression values must never use binary floating point.
3. Save files are versioned and validated before being loaded.
4. Writes use a temporary file and a backup/rename replacement sequence.
5. Core rules must be deterministic and unit tested.
6. UI state is a projection of domain state; widgets do not own persistent game truth.
7. No network dependency is required to play.

## Current layout
```text
lib/
  core/
    game/
    numbers/
  data/
    saves/
  main.dart
test/
  core/
  data/
  widget_test.dart
```

## Current playable slice
The app has a separated guess engine, exact decimal arithmetic, versioned local save data and a basic Flutter screen. This is the foundation, not yet the full legacy game, economy, traits, localization or save-slot system.
