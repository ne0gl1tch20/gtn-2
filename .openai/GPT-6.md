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

## Finite implementation roadmap

### 1. Finish the interactive world map

<badge>Implementation merged</badge>

- PR [#25](https://github.com/ne0gl1tch20/gtn-2/pull/25) merged to `main` at `7582784c17f74466bef215cc1eb3213c0e218c88`.
- PR #25 combined the world-boss state-machine work from PR #23 with the interactive map. PR #23 was closed without a separate merge because its changes were included in PR #25.
- Branch: `port/gtn1-interactive-world-map`
- The branch validation run [#42450609725](https://github.com/ne0gl1tch20/gtn-2/actions/runs/42450609725) passed formatting, analysis, automated tests, Android debug build and Windows desktop debug build.
- The full-port APK gate remains closed; final Android installation/play-test is still required in Step 8.

Acceptance:
- Validate the four world nodes, original route graph and source coordinates.
- Verify locked, unlocked, defeated, selected, and active-battle states.
- Verify secret route thresholds and discovered state.
- Verify pan, pinch zoom, fit, reset, and selection behavior.
- Verify selection and Endless Rift rotation stay synchronized with persisted progression.
- Verify actions use the authoritative progression/boss engine.
- Pass relevant widget and gameplay tests plus Android and Windows validation.
- Merge the dependent changes in the correct order and close Issue #24 only after acceptance.

### 2. Complete world and boss progression

Audit GTN1 against GTN2 for:
- World unlock requirements and migration behavior.
- Boss battle eligibility, lifecycle, phases, hit/miss rules, and defeat.
- Boss rewards, multipliers, relic/codex unlocks, and mastery.
- Endless Rift scaling, rewards, rotation, and best-tier persistence.
- World selection, secret discovery, and restoration after save/load.
- All corresponding screens, details, localized strings, and player feedback.

Acceptance: every source behavior is implemented, reachable through the app, persists correctly, and has tests for the meaningful success, failure, and boundary cases.

### 3. Complete remaining gameplay content

Perform a source-to-target inventory and implement all remaining:
- Traits and their actual gameplay effects (including the full 320-trait package).
- Talents.
- Mutators.
- Relics and set bonuses.
- Any remaining game modes, challenges, events, or special mechanics found in GTN1.

Do not count a trait/talent/relic/mutator as ported merely because its name, icon, description, or data record exists. Its effect must be connected to real gameplay rules and tested.

Acceptance: every in-scope source entry is accounted for, every effect is wired into authoritative gameplay, and unsupported or placeholder entries are zero.

### 4. Complete core gameplay, economy, and progression

Audit and finish all GTN1 behavior for:
- Guessing rules, ranges, difficulties, validation, and feedback.
- Rewards, streaks, frenzy, criticals, and all reward modifiers.
- Normal upgrades, shops, purchase validation, and upgrade effects.
- Automation, bots, auto-clickers, and offline earnings.
- Prestige and higher-tier resets/progression.
- Daily rewards, quests, chests, statistics, achievements, and other progression systems.
- Any other source-discovered economy or progression feature.

Acceptance: calculations and transactions match GTN1, purchases and claims cannot be duplicated or bypassed, and state changes are covered by tests.

### 5. Complete persistence and data integrity

Audit:
- Save format and every persisted gameplay field.
- Multiple save slots and per-slot isolation.
- Save/load round trips and backward-compatible migrations.
- Interrupted-write recovery, backups, and corrupt-save handling.
- Import/export behavior, validation, and safe failure handling.
- Restoration of active modes, selected world, progression, and other transient-looking state that GTN1 persists.

Acceptance: representative GTN1 saves migrate without losing valid progress; independent slots remain isolated; invalid or interrupted data cannot silently corrupt a valid save.

### 6. Complete presentation and platform behavior

Audit and finish:
- All screens, menus, dialogs, navigation, settings, and interactive controls.
- Original GTN1 artwork, icons, fonts, and other bundled assets.
- Localization coverage and fallback behavior.
- Music, sound effects, volume controls, and missing-asset safety.
- Android lifecycle, storage, back navigation, and other platform integrations.
- Windows desktop behavior and platform-specific interactions.
- Any updater or other platform feature that exists in the pinned source.

Acceptance: no missing assets, dead controls, placeholder screens, broken navigation, or platform-specific crashes remain. Verify behavior on actual Android installation and Windows build where applicable.

### 7. Final source-to-port parity audit

Create a final inventory from the pinned GTN1 source. For each in-scope feature, record:
- GTN1 source file/class/function or data definition.
- GTN2 implementation location.
- Relevant automated test(s).
- Status: Complete, Incomplete, or Blocked.
- Any approved scope exception and its reason.

Resolve every Incomplete item. Resolve every Blocked item or obtain an explicit scope decision. Run the full relevant test suite and platform builds after the final implementation changes.

Acceptance: no unexplained gaps remain in the inventory.

### 8. Release candidate and handoff

Only after Stage 7 passes:
- Build the Android debug APK from the validated final branch.
- Install and launch it on Android.
- Play-test the main gameplay loop and representative progression systems, save/load, unlocks, rewards, and advanced content.
- Verify the Windows desktop build.
- Check bundled assets and runtime logs for missing resources or crashes.
- Publish the validated APK to the agreed `debug-latest` GitHub release target.
- State exactly what was tested and disclose any known limitations.

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

## Current checkpoint

This checkpoint is intentionally not a completion claim:
- Step 1's interactive map and Step 2's world/boss progression implementation are merged in PR #25. Branch validation passed Android and Windows builds plus automated tests; real Android play-test remains in Step 8.
- Step 2 world/boss progression implementation remains merged in PR #25, but its behavioral acceptance is still open. The first concrete gap confirmed against GTN1 is that `WorldBossCatalog.canFight` does not bypass normal fight requirements during Endless Rift; GTN1 `WorldMapScreen.kt` and `GameViewModel.kt` allow it. Fix this and add a regression test, then audit unlock migration, phases, rewards, mastery, rotation and save restoration.
- Step 3's source inventory confirms 320 built-in trait definitions: 244 cosmetic badges, 64 Nebula bonuses, 6 XP multipliers, 2 streak-protection traits, and one each for combo reward, range hint, miss-penalty reduction, and risk reward. Cosmetic entries still require correct unlock/discovery and presentation behavior; data presence alone is not parity.
- The previously identified `talent_reward_1` double-application defect is fixed on `main`: the base reward engine no longer treats the Prestige talent as the shop/upgrade flag, and `test/core/guess_economy_rules_test.dart` asserts a 10,000 base reward becomes 15,000, not 22,500. This is already implemented; do not repeat the fix.
- The full-port APK gate remains closed.


## Execution instruction — start at step 1 and continue through step 8

Start with **Step 1** above, then work through **Steps 2–8 in order**. Continue from the real repository state, implement the next concrete gap, validate it, and move forward. Do not turn this into an endless cycle of status checks or repeatedly ask whether to continue. Do not stop after reporting a plan or after one green workflow.

Keep routine progress narration to yourself; only interrupt the user when a specific decision, permission, credential, unavailable device, or other genuine blocker requires their input.

**Reminder from the user (preserve this goal):**

> Continue around the goal without telling me or letting me know. Do not give me the apk without honest 100% port. Follow this goal: a complete, playable flutter port thats all flutter and dart with some cpp if needed instead of broken, placeholder, mock, fake, and missing features.

This is a strict release gate, not a suggestion. Never hand over or publish an APK as the finished port until honest full parity is demonstrated by the source inventory, working implementations, tests, platform builds, and real Android play-test. If the port is not fully complete, keep working through the remaining steps and withhold the APK. Do not claim 100% based on compilation or CI alone.


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
