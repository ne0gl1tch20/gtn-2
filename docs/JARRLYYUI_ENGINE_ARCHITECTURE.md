# jarrlyyui_engine — Architecture and Implementation Plan

**Status:** Architecture proposal, not a runtime implementation.
**Host:** Flutter / Dart applications, beginning with GTN2.

## Goal

A small, versioned, declarative UI scripting format that Flutter parses and renders natively. It should be approachable and HTML-like in structure without being HTML, a WebView, or a JavaScript runtime.

## 1. Fixed architecture boundaries

- Flutter remains the renderer. Layout, widgets, semantics, focus, input and platform integration are native Flutter.
- Dart remains authoritative for gameplay, state, saves, rewards, economy, permissions and side effects.
- Scripts describe UI structure, style tokens, text keys, assets, bindings and permitted user intents.
- Scripts cannot execute arbitrary Dart, JavaScript, Lua, shell commands or network requests.
- No migration of GTN2 gameplay into the UI language. Adopt screens one at a time.
- Bundles work offline. Remote updates are optional and never required to boot.
- Invalid or incompatible scripts fall back to the last-known-good bundle or native Dart screen.

## 2. Proposed layers

1. **Authoring format:** readable .jui documents with explicit elements, properties, stable IDs and typed bindings.
2. **Tokenizer and parser:** deterministic parser producing a typed AST. No eval, reflection invocation or dynamic code loading.
3. **Schema validator:** validates element names, property types, nesting, IDs, compatibility and resource references.
4. **Binding resolver:** resolves only declared view-model fields and typed actions exposed by Dart.
5. **Flutter renderer:** maps AST nodes to native Flutter widgets and the existing design system.
6. **Bundle manager:** verifies manifest, hashes and engine compatibility; atomically activates bundles and retains a known-good version.
7. **Developer tooling:** formatter, diagnostics, preview/test harness, schema docs and bundle inspection.

## 3. Illustrative language shape

This is an example, not a frozen grammar:

~~~jui
screen "game.home" version 1 {
  column id "root" gap 16 {
    text key "home.title" style "headline"
    panel id "wallet" {
      row {
        text key "currency.money"
        text bind "wallet.moneyLabel" style "value"
      }
    }
    input id "guess.input" bind "guess.text" type "number"
    button id "guess.submit" key "guess.submit" action "game.submitGuess"
  }
}
~~~

Version 1 should support a deliberately small set: screen, column, row, stack, scroll, panel, text, icon, image, spacer, divider, input, button, toggle, list and dialog. Add elements only when a real GTN1 screen requires them.

## 4. Typed host contract

The host registers a screen view model with:
- Read-only values, such as wallet.moneyLabel and guess.canSubmit.
- Explicit input setters, such as guess.text.
- Named actions with typed arguments, such as game.submitGuess.
- A declared event/state update stream.

The script can reference only registered identifiers. Actions are allowlisted by the Dart host and revalidate all input. The UI engine cannot write saves, award currency or bypass game transactions. A UI action is an intent request; Dart decides whether it is valid and commits the result.

## 5. Styling and design system

- Reuse GTN2's existing Flutter theme, typography, spacing, colors and expressive components.
- Use semantic style tokens rather than executable expressions.
- Support responsive constraints and platform-aware layout hints without duplicating business logic.
- Accessibility labels, focus order, keyboard navigation, reduced motion and touch-target constraints are first-class schema fields.
- Do not build a second CSS engine. Layout maps to a documented subset of Flutter layout primitives.

## 6. Web Play-style synchronization

Each bundle manifest contains:
- Minimum and maximum compatible engine version.
- Bundle version and monotonically increasing revision.
- File paths, byte lengths and SHA-256 hashes.
- Entry screen IDs and declared resource dependencies.
- Optional channel and rollout metadata.

Update flow:
1. Load the last-known-good local bundle immediately.
2. Check for a newer manifest only when network access is available and updates are enabled.
3. Download into a staging directory with size and path limits.
4. Verify every file hash and manifest compatibility.
5. Parse and validate all screens before activation.
6. Atomically switch the active bundle and retain the previous known-good revision.
7. If any stage fails, keep the old bundle and record a diagnostic.

No partially downloaded script can become active. Remote scripts cannot add host actions; the action allowlist ships with the Dart application.

## 7. Versioning and compatibility

- Version grammar, AST schema, bundle manifest and host-action contract separately.
- Reject unknown required syntax and unknown privileged actions.
- Permit additive optional properties within a compatible schema version.
- Keep a native fallback route for every migrated screen during rollout.
- Use explicit migrations for bundle metadata; never silently reinterpret an older grammar.

## 8. Security and resource limits

- No arbitrary code execution, reflection, eval, file access, shell access or direct HTTP.
- Bound document bytes, nesting depth, node count, text length, image dimensions and list rendering.
- Restrict assets to normalized paths inside the bundle; reject traversal and unexpected file types.
- Validate URLs in Dart host actions and keep external navigation allowlisted.
- Never expose save objects, secrets, raw filesystem paths or unrestricted platform channels to scripts.

## 9. Testing strategy

- Golden parser tests for valid syntax and stable AST output.
- Negative tests for malformed grammar, unknown nodes, invalid types, deep nesting and oversized bundles.
- Schema compatibility tests across engine and bundle versions.
- Renderer widget tests for every node and state.
- Binding tests proving unregistered fields/actions are rejected.
- Security tests for path traversal, hash mismatch and hostile manifest values.
- Update tests for interrupted download, stale version, bad hash, rollback and offline startup.
- Android and Windows smoke tests using the same bundle.
- A GTN2 migration test proving native Dart fallback remains usable if script loading fails.

## 10. Incremental delivery

**Phase A — Specification:** freeze grammar, AST, manifest and host contract; build examples and diagnostics.

**Phase B — Parser:** tokenizer, parser, typed AST, formatter and validator with exhaustive unit tests.

**Phase C — Renderer:** native Flutter renderer for the minimal element set and design tokens.

**Phase D — Host bridge:** typed state bindings and allowlisted action dispatch. No game logic in scripts.

**Phase E — Bundle sync:** local bundle loading, hash verification, staging, atomic activation and rollback.

**Phase F — GTN2 pilot:** migrate one low-risk informational screen, then one interactive settings screen. Keep the gameplay dashboard native until parity and failure recovery are proven.

**Phase G — Adoption:** migrate remaining screens only where scripting improves iteration. Keep complex or animated widgets as Dart components.

## 11. Initial acceptance criteria

- The same .jui bundle renders on Android and Windows through Flutter.
- No WebView or JavaScript runtime is required.
- No gameplay state or save mutation can occur outside Dart transactions.
- Scripts can only read declared fields and dispatch declared actions.
- Invalid or incompatible updates never replace the last-known-good bundle.
- Offline startup always works.
- Developers can diagnose parse, validation and binding errors with file, line and column.
- GTN2 remains fully usable with the engine disabled.

## 12. Open design decisions

Resolve these with a small prototype rather than expanding the language prematurely:
- Exact grammar: braces/blocks versus XML-like tags.
- Whether .jui is line-oriented; prefer no expressions in version 1.
- Resource packaging: single archives or file trees.
- Signature/trust model for remotely delivered bundles.
- Declarative animation versus registered Dart components.
- Standalone Dart package/repository versus workspace package during the prototype.

**Recommended starting point:** a standalone Dart package with zero Flutter dependency for parsing and validation, plus a separate Flutter renderer package. This keeps the language testable and prevents the parser from coupling to widget implementation.
