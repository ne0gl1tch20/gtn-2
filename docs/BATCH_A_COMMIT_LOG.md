# Batch A Commit and Verification Ledger

**Status:** ACTIVE — do not enter Batch B until every Batch A exit criterion is satisfied.  
**Target repository:** `ne0gl1tch20/gtn-2`  
**Target branch for the active continuation:** `batch-a/creative-save-active-slot`  
**Parity source:** `ne0gl1tch20/GuessTheNumber` at pinned commit `fe9cf567169e19059e0330d08769fe454336ef94`  
**Authoritative checklist:** [`docs/FINITE_PARITY_PLAN.md`](FINITE_PARITY_PLAN.md)  
**Screen-level diff:** [`docs/GTN1_SCREEN_PARITY_DIFF.md`](GTN1_SCREEN_PARITY_DIFF.md)

This is an append-only audit ledger. Add an entry for every commit made while Batch A is active, including documentation, implementation, test, formatting and CI-fix commits. Never silently rewrite a prior result; append a correction with the new evidence. Each implementation entry must identify the GTN1 source paths inspected and the GTN2 target paths changed.

## 1. Current checkpoint

- **Last inspected main:** `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1` (2026-11-14 15:45:03 UTC).
- **Continuation branch:** `batch-a/creative-save-active-slot`, created from the inspected `main` checkpoint.
- **Validate:** [run 43611843871](https://github.com/ne0gl1tch20/gtn-2/actions/runs/43611843871) — success on `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1`.
- **Build Debug:** [run 43611843795](https://github.com/ne0gl1tch20/gtn-2/actions/runs/43611843795) — success on `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1`.
- The superseded runs for `0c5b01328012792ade30196fbe0f58857049d1b9` were cancelled after the next push. They are not failures.
- **PR #71:** merged at `aad78da64e71853431b87bbb0176466b810c59ce`; dashboard/More structure pass.
- **PR #72:** merged at `9c5afea63af395ae2abaec8a21054f3e5e2d2f71`; Play/More/Profile pass.
- **PR #73:** merged at `871c21d9574971b124ad69b2cf375942d8a50200`; random-event implementation, recorded as baseline context rather than a Batch A surface closure.
- **PR #67:** remains draft/open and deliberately postponed until parity work is complete.

Green CI is build/test evidence only. It does not prove live Android/Windows behavior or visual parity.

## 2. Retrospective ledger at continuation start

| Commit / PR | Scope and evidence | Batch A interpretation |
|---|---|---|
| PR #71 — `aad78da64e71853431b87bbb0176466b810c59ce` | Play content order, More labels/order and phone-sized widget coverage; merged 2026-11-12. | Baseline dashboard/More work; not an exit sign-off. |
| PR #72 — `9c5afea63af395ae2abaec8a21054f3e5e2d2f71` | 26 files; Play/More responsive parity, profile destination/editor, local profile persistence and migration; merged 2026-11-13. | Baseline for Dashboard, More and Profile; runtime/persistence checks remain open. |
| `f82b3599b941ff4866183d38f3cc4d9dc062e6c8` | Updated the screen diff with separate Prestige/Ultra destination follow-up and earlier baseline evidence. | Documentation checkpoint; does not close Batch A. |
| `c07776f5f8a79e8685eadfe3316ae3a156989709` | Refreshed Batch A evidence in the finite parity plan. | Documentation checkpoint. |
| `65f6d23e41b011f44167974101af9482a3a8c9d6` | Clarified the code-bearing baseline and evidence wording in the finite parity plan. | Documentation checkpoint. |
| `0c5b01328012792ade30196fbe0f58857049d1b9` | Recorded the Creative Save source-to-target semantic gap in the finite parity plan. | Explicit blocker; no implementation. |
| `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1` | Distinguished GTN1 active-save Creative Save from GTN2's isolated Creative Mode sandbox in the screen diff. | Explicit blocker; no implementation. |

## 3. Active continuation — Creative Save implementation

**Implementation checkpoint:** branch head before this ledger refresh is `d22f1128ca52ea19ebd6f9f7803334ff73dc765e`. All implementation commits below are on top of the inspected `4fe04ee1572c3e4fb307cd37d796ee5312f30ce1` checkpoint. Workflow validation has not yet run for this branch; every test result remains **pending CI** until exact run URLs are recorded.

**GTN1 sources compared for this pass:**
- `shared/src/jvmAndAndroidMain/kotlin/com/jarrlyyy/guessthenumber/domain/model/GameState.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/viewmodel/GameViewModel.kt`
- `desktopApp/src/jvmMain/kotlin/com/jarrlyyy/guessthenumber/desktop/DesktopWebPlayActions.kt`
- `app/src/main/java/com/jarrlyyy/guessthenumber/ui/screens/SaveSlotsScreen.kt`
- `app/src/main/assets/web-play/index.html`
- `app/src/main/assets/web-play/app.js`

| UTC time | Commit SHA | Subject | GTN2 path(s) | Test / CI status |
|---|---|---|---|---|
| 2026-11-14 21:09:40 | `cb7c0b3f196b6b0b2fe2c24bef7b52ba6fb98314` | Add Batch A commit audit ledger | `docs/BATCH_A_COMMIT_LOG.md` | Documentation only |
| 2026-11-14 21:09:48 | `6c76538893e233888bc503e7c82fa336932e97b6` | Refresh Batch A evidence and audit pointer | `docs/FINITE_PARITY_PLAN.md` | Documentation only |
| 2026-11-14 21:10:18 | `098480e37fb573c4f4d40bb3de4a86d2a52a6d50` | Persist permanent Creative Save eligibility | `lib/data/saves/save_data.dart` | Schema implementation; pending CI |
| 2026-11-14 21:10:33 | `fb1f430e2c9207383456368784134c27d253c7d3` | Cover Creative Save flag migration and round-trip | `test/data/save_data_test.dart` | Test added; pending CI |
| 2026-11-14 21:11:22 | `32b8619ea095b07042a3ddf6f57c5795cef2ab75` | Allow source Creative Save range for opted-in slots | `lib/data/saves/save_data.dart` | Validation implementation; pending CI |
| 2026-11-14 21:11:25 | `9d3356e172b42b34774d9302376ec5179239679b` | Validate Creative Save range by slot eligibility | `lib/data/saves/save_storage.dart` | Storage validation; pending CI |
| 2026-11-14 21:11:28 | `702c157dc0095080d72ee3591709296bdea3d476` | Restore Creative Save ranges up to source limit | `lib/core/game/game_engine.dart` | Engine implementation; pending CI |
| 2026-11-14 21:11:43 | `ab5fdd0342505564b6f7b14235f03da12fe3464b` | Verify Creative Save range migration and storage | `test/data/save_data_test.dart` | Tests added; pending CI |
| 2026-11-14 21:11:48 | `78f3ea1db5e30393d3ce7d4a00cd3592b3fcb86c` | Cover GTN1 Creative Save range restore | `test/core/game_engine_test.dart` | Test added; pending CI |
| 2026-11-14 21:12:01 | `ea4dd1f1ff94a5d95562ec44224e08906f39af7b` | Restore and persist active Creative Save state | `lib/main.dart` | Runtime state wiring; pending CI |
| 2026-11-14 21:12:16 | `4de7858d2dd42c6255bd5c12cdcff05650fe6ac1` | Create permanent Creative Save slots | `lib/saves/save_slots_page.dart` | Save Slots creation flow; pending CI |
| 2026-11-14 21:12:39 | `c10d97d73a1b0157e5b4cafe483a14a1f1086d4c` | Add source-backed active-save transactions | `lib/core/creative/creative_save_policy.dart` | Policy implementation; pending CI |
| 2026-11-14 21:12:52 | `b1741b1ab16ce081cfd6927f07cdf4e2f9a15a55` | Harden catalog level validation and parsing | `lib/core/creative/creative_save_policy.dart` | Validation refinement; pending CI |
| 2026-11-14 21:13:06 | `a65156409629c28adbd472fcca676c782735c739` | Correct Creative Save currency regex | `lib/core/creative/creative_save_policy.dart` | Parser fix; pending CI |
| 2026-11-14 21:13:15 | `baa314654cb2172a0da6b356277438c9fa2113b4` | Enforce full-match currency parsing | `lib/core/creative/creative_save_policy.dart` | Parser hardening; pending CI |
| 2026-11-14 21:13:44 | `4c64f41f99104c3170e5aa428cac7d49f9468de2` | Cover active-save Creative Save transactions | `test/core/creative/creative_save_policy_test.dart` | Tests added; pending CI |
| 2026-11-14 21:14:34 | `a77b2f62f59477d4d3ecbbcfe46edd75ba3e2e0c` | Add inline active-save Creative Save panel | `lib/home/creative_save_panel.dart` | UI implementation; pending CI |
| 2026-11-14 21:14:49 | `8103bc7ca3a548ac4ba46befddcd6b3bd5a67dd7` | Preserve focused Creative Save editor values | `lib/home/creative_save_panel.dart` | UI state refinement; pending CI |
| 2026-11-14 21:15:00 | `4e2685378ba479d65493bc4ca5f0ab93a8acc0d4` | Show Creative Save tools on eligible active saves | `lib/home/game_dashboard_page.dart` | Dashboard placement; pending CI |
| 2026-11-14 21:15:25 | `8865ac2f5fb93b0ae1c50b5c4999bb7dc6a7e3d3` | Wire validated active-save Creative Save edits | `lib/main.dart` | Transaction wiring; pending CI |
| 2026-11-14 21:15:58 | `a5d46132c5b0826ec84f661caffc91d7c909c63a` | Preserve custom range across restored rounds | `lib/main.dart` | Engine range restoration; pending CI |
| 2026-11-14 21:16:05 | `6af0c217149c28dd1b189f87360f57e66e919fe5` | Verify inline Creative Save controls | `test/home/creative_save_panel_test.dart` | Widget test added; pending CI |
| 2026-11-14 21:16:19 | `f59de7d7dddc9b601d3f99f65b6dd302634813ce` | Validate Creative Save flag before range selection | `lib/data/saves/save_data.dart` | Malformed-flag validation fix; pending CI |
| 2026-11-14 21:16:22 | `ed04045c51ffef245b14bbf90ab86550c7419dc4` | Remove duplicate Creative Save flag check | `lib/data/saves/save_data.dart` | Validation cleanup; pending CI |
| 2026-11-14 21:16:26 | `aa4da8bc6c38ef40f09858b709267d2066f99142` | Keep restored slot promotion explicit | `lib/main.dart` | Null-safety refinement; pending CI |
| 2026-11-14 21:16:41 | `d22f1128ca52ea19ebd6f9f7803334ff73dc765e` | Cover permanent Creative Save creation controls | `test/saves/save_slots_page_test.dart` | Widget test added; pending CI |

### Current Creative Save implementation state

- **Implemented, not yet CI-verified:** schema-v6 permanent `creativeModeEnabled` flag with old-save default false; separate from the existing isolated `creativeMode` sandbox payload.
- **Implemented, not yet CI-verified:** permanent Creative Save toggle/range inputs during Save Slot creation; eligible save range and engine restore support up to the GTN1 1,000,000 maximum.
- **Implemented, not yet CI-verified:** inline dashboard panel shown only when the active slot's permanent flag is true.
- **Implemented, not yet CI-verified:** typed active-save range, currency, counter, streak and three upgrade-catalog transactions. Currency parsing accepts GTN1 suffix notation and rejects invalid/negative values.
- **Tests authored, not yet executed:** save schema migration/round-trip, storage persistence at 1,000,000, engine restore, transaction validation, panel interactions and Save Slots creation controls.
- **Still open:** run format/analyze/full tests and both platform builds; verify active-slot switch/restart persistence; compare the exact native Android and desktop behavior; capture paired GTN1/GTN2 screenshots; finish source label, localization, layout and accessibility diffs. Do not mark Creative Save or Batch A complete yet.

## 4. Per-commit audit template

Append one row per commit to the ledger table below, then add a detailed entry under the row. Keep SHAs full length.

| UTC date/time | Commit SHA | Commit subject | Batch A item(s) | GTN1 source paths | GTN2 paths changed | Tests / CI | Result and remaining gaps |
|---|---|---|---|---|---|---|---|
| _Pending new commits_ | — | — | — | — | — | — | — |

### Required evidence for implementation commits

1. Repository state inspected before editing; record the base SHA.
2. Pinned GTN1 source implementation inspected in parallel with current GTN2 implementation.
3. Exact behavioral and UI differences recorded in `GTN1_SCREEN_PARITY_DIFF.md`.
4. Tests added or updated for valid, invalid, boundary, persistence/reload and failure cases as relevant.
5. Dart format, static analysis, complete Flutter tests, Android debug build and Windows desktop debug build results recorded by exact workflow URL and commit SHA.
6. Android and Windows runtime checks and paired GTN1/GTN2 screenshots recorded before claiming visual closure.
7. `FINITE_PARITY_PLAN.md` status and this ledger updated in the same work batch.

### Batch A exit gate

Batch A remains active until Dashboard, More, Settings, Menu Studio, Profile and Save Slots all pass source-backed behavior, persistence/reload, interaction, Android/Windows runtime and paired visual checks. Keep every unverified item open. Do not start Batch B early.
