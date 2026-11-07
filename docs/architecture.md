# GTN 2 architecture

## Initial boundaries
- `lib/core/`: deterministic game rules and value types. No Flutter imports.
- `lib/data/`: persistence, serialization and save migrations.
- `lib/features/`: Flutter screens and user interaction.
- `test/`: unit and widget tests.

The first commit intentionally starts with a small playable vertical slice. Systems from the original game will be reimplemented behind explicit interfaces rather than copied wholesale.

## Reliability rules
1. Gameplay decisions live in Dart domain code, not widgets.
2. Currency and progression values must never use binary floating point.
3. Save files are versioned and validated before being loaded.
4. Writes use a temporary file and atomic rename where supported.
5. Core rules must be deterministic and unit tested.
6. UI state is a projection of domain state; widgets do not own persistent game truth.
7. No network dependency is required to play.

## Planned layout
```text
lib/
  core/
    game/
    numbers/
    progression/
  data/
    saves/
  features/
    game/
  main.dart
test/
  core/
  data/
  features/
```

## First playable slice
The starter screen proves the Flutter app boots and provides a basic guess loop. It is not yet the full legacy game, save system, economy, traits or localization.
