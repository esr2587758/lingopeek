---
phase: 01-hub-data-foundations
plan: 02
subsystem: app-workflow
tags: [swift, mainactor, history, source-gate, core-checks]
requires:
  - phase: 01-hub-data-foundations
    provides: [LingobarHistoryRecord, LingobarHistoryStore, LingobarHubLibrary]
provides:
  - Successful Lingobar AI action history recording
  - Source-placement gate for history recording control flow
  - Final Phase 1 build and CoreChecks verification
affects: [phase-02-native-hub-shell, phase-03-library-workflows]
tech-stack:
  added: []
  patterns:
    - MainActor ViewModel dependency injection for local history persistence
    - CoreChecks source gate for async success-path placement
key-files:
  created:
    - .planning/phases/01-hub-data-foundations/02-SUMMARY.md
  modified:
    - Sources/LingoPeekApp/LingobarViewModel.swift
    - Sources/LingoPeekCoreChecks/main.swift
key-decisions:
  - "Record history only after successful decoded AI output passes the current-request guard."
  - "Use `输入模式` as the source label for input-mode history instead of reusing stale selection source state."
  - "Keep history append failures non-fatal so they do not replace successful AI output."
patterns-established:
  - "LingobarViewModel accepts `LingobarHistoryStore` through initializer injection with `.defaultStore()` as the production default."
  - "LingoPeekCoreChecks can source-slice app files to enforce control-flow placement without adding an app-target dependency."
requirements-completed: [HIST-01, COLL-01, COLL-05, HIST-02, HIST-06]
coverage:
  - id: D1
    description: "Successful non-stale AI language actions append compact history records through the injected history store."
    requirement: HIST-01
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarViewModelHistoryRecordingSourceGate"
        status: pass
      - kind: other
        ref: "swift build --product LingoPeek"
        status: pass
    human_judgment: false
  - id: D2
    description: "Setup, fixture, copy/collect, catch/error, and pre-guard paths cannot record history without failing CoreChecks."
    requirement: HIST-01
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarViewModelHistoryRecordingSourceGate"
        status: pass
    human_judgment: false
  - id: D3
    description: "Input-mode history records use submitted input text and the source label `输入模式`."
    requirement: HIST-01
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarViewModelHistoryRecordingSourceGate"
        status: pass
    human_judgment: false
  - id: D4
    description: "Final Phase 1 scope gates kept Package.swift, Hub UI files, and design prototypes untouched."
    verification:
      - kind: other
        ref: "git diff --exit-code -- Package.swift"
        status: pass
      - kind: other
        ref: "scope gate for Sources/designs/Package.swift Hub UI paths"
        status: pass
    human_judgment: false
duration: 4m
completed: 2026-06-27
status: complete
---

# Phase 1 Plan 02: App Workflow History Recording Summary

**Successful Lingobar AI completions now write privacy-bounded local history records from the guarded success path**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-27T15:54:40Z
- **Completed:** 2026-06-27T15:58:47Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Injected `LingobarHistoryStore` into `LingobarViewModel` while preserving the existing default `PhraseStore` construction path.
- Captured source text/source label before async AI work and recorded history only after successful decoded output passed the current-request guard.
- Added `checkLingobarViewModelHistoryRecordingSourceGate()` so CoreChecks fail if recording moves into setup, fixture, copy/collect, error, or pre-guard regions.
- Re-ran final Phase 1 gates: app build, CoreChecks, Package.swift no-diff, and no Hub UI/design file scope changes.

## Task Commits

1. **Task 1: Record successful non-stale Lingobar language actions** - `f7b77ec` (`feat`)
2. **Task 2: Run final Phase 1 verification and scope gates** - no source commit; verification-only task covered by this metadata summary.

## Files Created/Modified

- `Sources/LingoPeekApp/LingobarViewModel.swift` - Added history store injection and guarded success-path recording.
- `Sources/LingoPeekCoreChecks/main.swift` - Added the ViewModel source-placement gate and wired it into the check suite.
- `.planning/phases/01-hub-data-foundations/02-SUMMARY.md` - Captures Plan 02 completion evidence.

## Decisions Made

- Kept history recording out of `perform(_:)`, setup handling, copy/collect handling, fixture presentation, and AI error branches.
- Used a private helper to isolate `historyStore.append` so source checks can prove there is only one append site.
- Used `_ = try? historyStore.append(record)` so local history write failures remain non-fatal and do not mask successful AI output.

## Verification

- `swift build --product LingoPeek` - passed.
- `swift run LingoPeekCoreChecks` - passed.
- `rg -n 'checkLingobarViewModelHistoryRecordingSourceGate|recordCompletedHistory|historyStore|activeAIRequestID == requestID|输入模式' Sources/LingoPeekApp/LingobarViewModel.swift Sources/LingoPeekCoreChecks/main.swift` - passed with expected source evidence.
- `git diff --exit-code -- Package.swift` - passed.
- `! git diff --name-only -- Sources designs Package.swift | rg 'LingobarHubView|LingobarHubWindow|SettingsView|LingobarRootView|designs/'` - passed.
- `! git ls-files --others --exclude-standard -- Sources | rg 'LingobarHubView|LingobarHubWindow|SettingsView|LingobarRootView'` - passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Swift initially warned that the result of `try? historyStore.append(record)` was unused. The helper now assigns it to `_`, keeping the build warning-free while preserving non-fatal behavior.
- The temporary `_auto_chain_active: false` config diff created by the orchestrator was removed before metadata closeout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 1 execution is ready for verifier review. Later Hub UI phases can rely on `LingobarHistoryStore`, `LingobarHistoryRecord`, and `LingobarHubLibrary` for real collection/history data, plus `LingobarViewModel` for completed-action history capture.

---
*Phase: 01-hub-data-foundations*
*Completed: 2026-06-27*

## Self-Check: PASSED

- Files found: `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekCoreChecks/main.swift`, `.planning/phases/01-hub-data-foundations/02-SUMMARY.md`
- Commit found: `f7b77ec`
- Final gates passed: `swift build --product LingoPeek`, `swift run LingoPeekCoreChecks`, Package.swift no-diff, no Hub UI/design scope changes.
