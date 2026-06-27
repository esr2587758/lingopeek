---
phase: 01-hub-data-foundations
plan: 01
subsystem: core-data
tags: [swift, foundation, codable, json, history, hub-library]
requires: []
provides:
  - LanguageAction raw-value Codable persistence
  - Compact LingobarHistoryRecord builder and bounded LingobarHistoryStore
  - LingobarHubLibrary adapters for SavedPhrase collection items and history records
  - CoreChecks coverage for history persistence, privacy, and adapter behavior
affects: [phase-02-native-hub-shell, phase-03-library-workflows]
tech-stack:
  added: []
  patterns:
    - Foundation JSON store matching PhraseStore encoder, decoder, locking, and atomic-write shape
    - Adapter-only collection metadata over existing SavedPhrase values
key-files:
  created:
    - Sources/LingobarCore/LingobarHistoryStore.swift
    - Sources/LingobarCore/LingobarHubLibrary.swift
  modified:
    - Sources/LingobarCore/LanguageAction.swift
    - Sources/LingoPeekCoreChecks/main.swift
key-decisions:
  - "Keep Phase 1 data-only: no Hub UI/window/design files and no Package.swift changes."
  - "Keep collection metadata adapter-only; SavedPhrase and PhraseStore schema remain unchanged."
  - "Persist history as compact user-visible Foundation JSON with bounded fields and no provider configuration inputs."
patterns-established:
  - "LingobarHistoryStore uses Application Support/LingoPeek/history.json with ISO-8601 Codable JSON and atomic writes."
  - "LingobarHubLibrary converts existing SavedPhrase and history records into copy-ready Hub library items."
requirements-completed: [HIST-01, COLL-01, COLL-05, HIST-02, HIST-06]
coverage:
  - id: D1
    description: "LanguageAction encodes and decodes by stable raw values for persisted history records."
    requirement: HIST-01
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLanguageActionCodable"
        status: pass
    human_judgment: false
  - id: D2
    description: "LingobarHistoryRecord builds compact records for language actions while rejecting copy/collect and bounding stored text."
    requirement: HIST-02
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarHistoryRecordBuilderPrivacy"
        status: pass
      - kind: other
        ref: "privacy source grep over Sources/LingobarCore/LingobarHistoryStore.swift and Sources/LingobarCore/LingobarHubLibrary.swift"
        status: pass
    human_judgment: false
  - id: D3
    description: "LingobarHistoryStore loads missing history as empty, appends newest-first, enforces caps, deletes, clears, and throws on corrupt JSON."
    requirement: HIST-06
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarHistoryStore"
        status: pass
      - kind: other
        ref: "rg source assertion for history.json, NSLock, atomic writes, and ISO-8601 strategies"
        status: pass
    human_judgment: false
  - id: D4
    description: "SavedPhrase values adapt into Hub collection items with preserved identity/date/note and copyText equal to title."
    requirement: COLL-01
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarHubLibraryItems"
        status: pass
    human_judgment: false
  - id: D5
    description: "Hub collection and history adapters expose copy-ready text for later card/detail workflows."
    requirement: COLL-05
    verification:
      - kind: unit
        ref: "swift run LingoPeekCoreChecks#checkLingobarHubLibraryItems"
        status: pass
    human_judgment: false
duration: 6m12s
completed: 2026-06-27
status: complete
---

# Phase 1 Plan 01: Hub Data Foundations Summary

**Foundation-only Lingobar history records, bounded JSON persistence, and Hub library adapters for real collection/history data**

## Performance

- **Duration:** 6m12s
- **Started:** 2026-06-27T15:44:09Z
- **Completed:** 2026-06-27T15:50:21Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added TDD CoreChecks for `LanguageAction` Codable behavior, history persistence, history privacy/bounding, and Hub collection/history adapters.
- Added `LingobarHistoryLimits`, `LingobarHistoryRecord`, and `LingobarHistoryStore` under `LingobarCore` using Foundation-only JSON persistence at `history.json`.
- Added `LingobarHubLibraryKind`, `LingobarHubLibraryItem`, and `LingobarHubLibrary` adapters over existing `SavedPhrase` and history records without changing collection persistence.
- Kept Plan 01 data-only: no Hub UI/window/design files, no `Package.swift` changes, and no `SavedPhrase`/`PhraseStore` schema changes.

## Task Commits

1. **Task 1: Add failing CoreChecks for Phase 1 core data contracts** - `15019c1` (`test`)
2. **Task 2: Add Foundation-only history and Hub library contracts** - `424993b` (`feat`)
3. **Task 3: Implement bounded local LingobarHistoryStore persistence** - `f06c260` (`feat`)

## Files Created/Modified

- `Sources/LingobarCore/LingobarHistoryStore.swift` - History limits, compact history record builder, and bounded local JSON store.
- `Sources/LingobarCore/LingobarHubLibrary.swift` - Hub-facing collection/history item type and adapters.
- `Sources/LingobarCore/LanguageAction.swift` - Added `Codable` conformance for raw-value persistence.
- `Sources/LingoPeekCoreChecks/main.swift` - Added Phase 1 core checks for Codable, store, privacy, and adapter behavior.

## Decisions Made

- Used `LanguageAction` raw values for persisted action identity so history records stay aligned with existing toolbar semantics.
- Kept `SavedPhrase` unchanged and supplied Phase 1 item type/source metadata only through `LingobarHubLibrary.collectionItems(from:)`.
- Bounded stored text via named `LingobarHistoryLimits` constants and rejected `.copy`/`.collect` history records at the builder boundary.
- Used the existing `PhraseStore` persistence pattern rather than adding dependencies, SQLite/Core Data, or package changes.

## Verification

- `swift run LingoPeekCoreChecks` - passed after Task 2 and Task 3; final run passed.
- `swift build --product LingoPeek` - passed.
- `! rg -n 'AIProviderConfiguration|OpenAICompatibleClient|Authorization|apiToken|baseURLString|systemPrompt|DeepSeek|DEEPSEEK|AI_API_TOKEN|AI_MODEL|httpBody' Sources/LingobarCore/LingobarHistoryStore.swift Sources/LingobarCore/LingobarHubLibrary.swift` - passed with no matches.
- `rg -n 'history\.json|LingobarHistoryStore|NSLock|\.atomic|dateEncodingStrategy = \.iso8601|dateDecodingStrategy = \.iso8601' Sources/LingobarCore/LingobarHistoryStore.swift` - passed with expected store-pattern matches.
- Scope gate from `075526d..HEAD` changed only `Sources/LingoPeekCoreChecks/main.swift`, `Sources/LingobarCore/LanguageAction.swift`, `Sources/LingobarCore/LingobarHistoryStore.swift`, and `Sources/LingobarCore/LingobarHubLibrary.swift`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed throwing calls inside CoreChecks `check` autoclosures**
- **Found during:** Task 2
- **Issue:** The red tests used `try` inside the non-throwing `check(_:_:)` autoclosure, so Swift rejected the test harness once production symbols existed.
- **Fix:** Moved throwing decode/load calls into local variables before calling `check`.
- **Files modified:** `Sources/LingoPeekCoreChecks/main.swift`
- **Verification:** `swift run LingoPeekCoreChecks`
- **Committed in:** `424993b`

**2. [Rule 3 - Blocking] Added a provisional store surface before Task 3 hardening**
- **Found during:** Task 2
- **Issue:** Task 1 required `checkLingobarHistoryStore()` to be invoked in the final CoreChecks block, so Task 2's required `swift run LingoPeekCoreChecks` could not pass unless a `LingobarHistoryStore` type already existed.
- **Fix:** Added the minimal file-backed store methods needed for the wired checks in Task 2, then completed the full locked/default-store/save-cap implementation in Task 3.
- **Files modified:** `Sources/LingobarCore/LingobarHistoryStore.swift`
- **Verification:** `swift run LingoPeekCoreChecks`; Task 3 store source assertion
- **Committed in:** `424993b`, `f06c260`

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 3: 1).  
**Impact on plan:** No scope creep into UI, package dependencies, or collection schema. The final implementation matches Plan 01 behavior and verification gates.

## Issues Encountered

- Existing `.planning/config.json` was already modified before execution and remains unstaged.
- Existing untracked `designs/lingobar-hub/`, `designs/lingobar-langmap/`, and `designs/lingobar-navmap/` directories remain untouched and unstaged.

## Known Stubs

None - stub scan found only existing test assertions for `nil` and empty decoded defaults, not placeholder data paths or UI stubs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can build on `LingobarHistoryRecord.make(...)`, `LingobarHistoryStore.defaultStore()`, and `LingobarHubLibrary` adapters. The core data foundation is green, compact, and data-only; Plan 02 should wire successful Lingobar action recording without creating Hub UI/window/design files.

---
*Phase: 01-hub-data-foundations*
*Completed: 2026-06-27*

## Self-Check: PASSED

- Files found: `Sources/LingobarCore/LingobarHistoryStore.swift`, `Sources/LingobarCore/LingobarHubLibrary.swift`, `Sources/LingobarCore/LanguageAction.swift`, `Sources/LingoPeekCoreChecks/main.swift`, `.planning/phases/01-hub-data-foundations/01-SUMMARY.md`
- Commits found: `15019c1`, `424993b`, `f06c260`
