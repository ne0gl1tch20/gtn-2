# GTN2 Full-Port Completion Plan

**Owner:** GPT-6  
**Project:** GTN1 to GTN2 Flutter/Dart port  
**Source of truth:** GTN1 repository `ne0gl1tch20/GuessTheNumber`, pinned at `fe9cf567169e19059e0330d08769fe454336ef94`  
**Target:** `ne0gl1tch20/gtn-2`

## Goal

Deliver a complete, playable Flutter port of GTN1. Flutter/Dart is the application and gameplay implementation; native C++ is permitted only where it is genuinely required.

Do not publish or hand over an APK as the completed port until the final acceptance criteria in this document pass. A successful compile, a green CI run, matching data files, or a screen that merely resembles GTN1 does not establish feature parity.

No placeholders, mock systems, fake functionality, inert controls, or knowingly missing in-scope features are acceptable in the final release.

## Working rules

1. Treat the pinned GTN1 source as the behavioral reference. Compare implementations, not just names, data structures, or UI.
2. Track each in-scope feature as **Complete**, **Incomplete**, or **Blocked**. A feature is Complete only when its behavior is implemented and supported by appropriate test evidence.
3. Record concrete gaps and dependencies. Do not repeatedly re-audit already verified behavior unless a regression or new source finding requires it.
4. Use CI as a validation gate, not as the definition of project completion.
5. Fix real failures, rerun the affected checks, and continue to the next roadmap stage. Do not wait in an endless check/fix/check loop when the available evidence is sufficient.
6. Keep the final APK/release gate closed until the full-port acceptance criteria pass.
7. Preserve existing player progress and verify migrations, recovery, and save-slot isolation.
8. Do not silently omit a GTN1 feature. If a feature is genuinely out of scope or impossible to reproduce, document the reason and get an explicit scope decision before claiming completion.

## Execution roadmap

Follow the short, meaningful phases in [docs/FINITE_PARITY_PLAN.md](../docs/FINITE_PARITY_PLAN.md). That document is the authoritative scope, phase order, checklist and live status. Do not maintain a conflicting second roadmap here.

**Architecture decision (2026-11-16):** GTN2 remains Flutter + Dart for Android and Windows, with the existing Material 3 Expressive direction and GTN1 visual identity. The Rust + Slint rebuild proposal is shelved. Do not replace Flutter, add Slint, introduce a Rust gameplay core or start a Rust migration under the current parity project. Rust requires a separate explicit architecture decision and must not delay parity.

Execute Phases 0–12 as one continuous development effort. Phase 0 is already verified complete; do not repeat it without evidence of a missed source item. Continue from Phase 1 through Phase 12 without asking for confirmation between phases. Work in small vertical slices; each slice must include implementation, relevant tests and the evidence appropriate to its behavior. If physical Android/Windows evidence blocks a phase, record that blocker and continue independent work without bypassing dependent gates or falsely closing the phase. A phase may be split into smaller batches, but its acceptance criteria and the full source inventory cannot be reduced.

Keep all in-scope GTN1 features. No placeholders, mocks, fake functionality, inert controls or knowingly missing features are acceptable in the final release. Do not publish or hand over an APK as the completed port until the final full-parity acceptance criteria pass.

## UI validation requirement — mandatory three-layer gate

Use all three layers for applicable UI work. The authoritative details and current status live in [docs/FINITE_PARITY_PLAN.md](../docs/FINITE_PARITY_PLAN.md).

1. **Project-owned `overflow_guard`:** Implement and use `test/support/overflow_guard.dart`. There is no verified third-party package by that name in this repository; do not invent a dependency. The helper must fail on Flutter layout exceptions after bounded pumps and meaningful interactions, with screen + logical viewport in the failure reason. Never swallow errors or hide overflow with clipping.
2. **Native Flutter widget tests:** Keep `test/responsive_layout_smoke_test.dart` across 320x640, 360x720, 390x844, 430x900, 600x900, 719x900, 720x900, 1024x768, 1100x800 and 1280x800 for Dashboard, More navigation, Settings, Menu Studio, Profile, Save Slots, Upgrade Shop, World Map and Progression Hub. Focused widget tests must verify real interactions, navigation and state transitions, not just rendering. Use deterministic inputs and bounded pumps, not unbounded `pumpAndSettle`.
3. **Golden tests:** Add reviewed native Flutter snapshots under `test/goldens/` for representative critical screens/states at selected phone/tablet/desktop breakpoints. Stabilize theme, fonts, locale, text scale, device pixel ratio, viewport and animation state. Compare against pinned GTN1 visual references. Inspect before/after images before updating baselines; never auto-approve changed or missing goldens.

The dedicated parallel `Headless responsive UI smoke` job must run the guard-integrated responsive matrix, focused widget regressions and golden tests. Keep the full suite compact and bounded. Headless tests do not replace Android/Windows runtime screenshots and real interaction checks. On failure, record the exact run, SHA, screen, viewport and exception; compare the pinned GTN1 source and fix the root cause before rerunning.

**Current status (2026-11-16):** Responsive matrix/job exist, but `overflow_guard` helper/integration and reviewed golden baselines are not yet implemented. Run `43861735109` at `59b84cd7f9eab97fa575caf794c212db72ca16f2` passed format/analyze and failed the full suite + responsive smoke due to a 20px bottom overflow in World Map at 320x640. Do not mark UI validation complete.
## Final definition of done

The port is complete only when all of the following are true (it is just bullet points, do not check):

- [ ] Every in-scope GTN1 feature has a corresponding working Flutter/Dart implementation.
- [ ] All 320 trait effects and all other source-listed gameplay content are accounted for and functional.
- [ ] No placeholder, mock, fake, inert, or knowingly missing in-scope functionality remains.
- [ ] Gameplay calculations, progression, rewards, unlocks, and transactions match the pinned GTN1 behavior.
- [ ] Saves, migrations, recovery, and save-slot isolation are verified.
- [ ] UI, assets, fonts, localization, audio, and platform behavior are complete.
- [ ] Automated tests cover the important gameplay rules, transactions, migrations, and UI interactions.
- [ ] Android and Windows builds pass on the final source revision.
- [ ] The Android APK is installed and meaningfully play-tested.
- [ ] The final source-to-port inventory contains no unexplained Incomplete or Blocked entries.

**Stop condition:** Once every item above passes, the port is done and the validated APK can be published. Do not extend the project with unrelated polish or arbitrary extra audit rounds. Reopen completed work only for a demonstrated defect, regression, or newly discovered source behavior.

## Current status and execution

The live phase, Batch A/PR status, exact repository checkpoint, CI evidence and remaining gaps are maintained in [docs/FINITE_PARITY_PLAN.md](../docs/FINITE_PARITY_PLAN.md) and its linked audit ledgers. Read the current files on `main` before choosing the next task; never rely on an older checkpoint copied into this instruction file.

Continue from the first open phase and next concrete source-backed gap. Do not stop after reporting a plan or one green workflow. Keep routine progress narration minimal and interrupt the user only for a genuine blocker or decision.

**Release gate:** Never hand over or publish a completion APK until the frozen GTN1 inventory, working implementations, tests, Android and Windows builds, real Android play-test and applicable Windows runtime checks demonstrate full parity. CI alone is not proof. If any in-scope item remains incomplete, continue the work and withhold the completion APK.

## Mandatory coding and validation reminders

Apply these rules before every code change and before reporting work complete:

1. **Work directly on `main`** when the user asks for direct-to-main work. Do not create a feature branch or PR for that task. Do not merge or close unrelated open PRs.
2. Read the target file and its callers/tests before editing. Make the smallest coherent change; avoid broad rewrites and unrelated formatting churn.
3. **Dart formatting is a required pre-commit step.** Run `dart format .` (or at minimum `dart format <every-changed-dart-file>`) with the same stable Dart SDK channel used by CI. This command must write the formatter's output; do not use `--output=none` as the only local formatting step.
4. Immediately verify formatting with `dart format --output=none --set-exit-if-changed .`. If it reports changed files, do not commit. Run the write-mode formatter, inspect the resulting diff, then rerun the check.
5. Avoid manually guessing Dart formatter indentation. Nested conditional expressions, multiline argument lists, collection literals, and trailing commas are common sources of formatter-only CI failures. Prefer simple `if/else` logic over deeply nested ternaries when readability improves.
6. Before committing Dart changes, run `flutter analyze --fatal-infos` and the narrowest relevant tests. Run the full test suite when the change affects shared behavior or CI requires it. Do not claim tests passed unless the actual command or workflow passed.
7. Inspect the exact GitHub Actions run for the pushed commit SHA. Confirm the formatting step, analysis, tests, and applicable platform builds individually; a queued or in-progress run is not a pass.
8. When a validation step fails, read its logs and fix the underlying cause. Do not repeatedly make speculative whitespace edits. If formatter output is unclear, capture a unified diff between the source and `dart format --output=show <file>` before editing.
9. Keep validation finite and fast: run focused checks first, avoid duplicate long-running tests, and do not repeat already-green checks without a code change or a demonstrated reason.
10. Preserve the GTN1-to-GTN2 completion gate: no mock/placeholder functionality and no claim of full parity based on a successful build alone. Do not publish a completion APK before the documented acceptance criteria pass.

### Dart formatting quick checklist

```bash
dart format <changed-dart-files>
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test <relevant-test-files>
```

If the formatter check fails in CI, obtain the formatter's exact output/diff first. Fix that output rather than hand-adjusting indentation by intuition.
