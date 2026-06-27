---
phase: 01-hub-data-foundations
verified: 2026-06-27T16:04:50Z
status: human_needed
score: 10/12 must-haves verified
behavior_unverified: 2
overrides_applied: 0
behavior_unverified_items:
  - truth: "Successful non-stale AI language actions append compact history records through LingobarViewModel after successful decode and the activeAIRequestID guard."
    test: "With AI configured, trigger a language action, then inspect Application Support/LingoPeek/history.json."
    expected: "Exactly one newest-first record is appended for the completed action after the result appears; fields are compact and user-visible only."
    why_human: "CoreChecks verify source placement, but no executable test injects a fake AI client or exercises the async success transition at runtime."
  - truth: "Setup, fixture, copy/collect, stale completion, decode-error, and provider/network-error paths do not append history."
    test: "Exercise each non-success path, including starting one AI action and superseding it before completion, then inspect history.json."
    expected: "No record is appended for setup/fixture/copy/collect/error paths; stale completions do not write history."
    why_human: "The source gate verifies forbidden regions, but no behavioral test drives these runtime paths with observable store state."
human_verification:
  - test: "Successful AI completion writes history"
    expected: "A successful translate/grammar/rewrite/examples/pronounce action appends one compact history record to Application Support/LingoPeek/history.json."
    why_human: "Requires configured AI access or an injectable fake AI client; current automated checks only verify source placement and core store behavior."
  - test: "Non-success paths do not write history"
    expected: "Setup gate, grammar fixture, copy/collect, stale completions, decode errors, and provider/network errors leave history unchanged."
    why_human: "Requires driving app/runtime paths or a dedicated ViewModel test seam that does not exist in Phase 1."
---

# Phase 1: Hub Data Foundations Verification Report

**Phase Goal:** Give the Hub real local data contracts before building the full visual surface.  
**MVP Story Verified:** As a Lingobar user, I want to have saved phrases and completed language actions represented by real local data contracts, so that the Hub can later show collection and history without placeholder data.  
**Verified:** 2026-06-27T16:04:50Z  
**Status:** human_needed  
**Re-verification:** No - initial verification

## User Flow Coverage

| Step | Expected | Evidence in Codebase | Status |
| --- | --- | --- | --- |
| Saved phrases become Hub collection data | Existing `SavedPhrase` values adapt without a second store and expose copy-ready text. | `LingobarHubLibrary.collectionItems(from:)` maps id/title/note/date, `source == "Lingobar"`, `itemType == "文本"`, `copyText == title`; CoreChecks assert this. | VERIFIED |
| Completed actions become Hub history data | Successful language actions can produce compact records and persist through local history. | `LingobarHistoryRecord.make(...)`, `LingobarHistoryStore`, and source-gated ViewModel wiring exist; core persistence tests pass. Runtime AI success append still needs human/runtime verification. | PRESENT_BEHAVIOR_UNVERIFIED |
| Later Hub can render real list/detail fields | Collection/history adapters expose action, item type, source, created date, visible text, note, source text, and copy text. | `LingobarHubLibraryItem` and adapters expose these fields; CoreChecks verify collection/history transformations. | VERIFIED |
| Phase stays data-only | No Hub UI/window/design/prototype source scope is added by the phase. | Phase commits touched only planned Swift files; `Package.swift` has no diff; source/diff gates found zero Hub UI additions. | VERIFIED |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | History records can be appended, loaded, deleted, cleared, and capped through a Foundation-only store. | VERIFIED | `LingobarHistoryStore.swift` imports only Foundation; `load`, `save`, `append`, `delete`, `clear`, cap enforcement, and `history.json` path are implemented. `swift run LingoPeekCoreChecks` passed. |
| 2 | History persistence is Foundation JSON under Application Support/LingoPeek/history.json and follows the PhraseStore atomic-write pattern. | VERIFIED | `defaultStore()` uses Application Support/LingoPeek/history.json; encoder uses pretty/sorted ISO-8601; writes use `.atomic`; `NSLock` guards public methods. |
| 3 | Completed Lingobar language actions produce compact history records without storing API tokens or provider secrets. | VERIFIED | Record fields are limited to id/action/itemType/visibleText/copyText/note/sourceText/sourceAppName/createdAt; forbidden provider/token grep over core history/adapters returned no matches; CoreChecks encode privacy sentinels. Runtime ViewModel append is tracked separately below. |
| 4 | Existing saved phrases adapt into Hub collection items with copy-ready text and metadata. | VERIFIED | `collectionItems(from:)` maps existing `SavedPhrase` values; no collection store/schema changes were found. |
| 5 | Core checks cover history persistence and collection/history transformations. | VERIFIED | CoreChecks include and invoke `checkLanguageActionCodable`, `checkLingobarHistoryStore`, `checkLingobarHistoryRecordBuilderPrivacy`, `checkLingobarHubLibraryItems`, and `checkLingobarViewModelHistoryRecordingSourceGate`; command passed. |
| 6 | `LanguageAction` persists through stable raw values. | VERIFIED | `LanguageAction: Codable`; CoreChecks assert raw-value encode/decode for translate/grammar/rewrite/examples/pronounce. |
| 7 | History records expose action, item type, source app label, createdAt, visible text, copy text, note, and source text. | VERIFIED | `LingobarHistoryRecord` fields and `historyItems(from:)` preserve these values; CoreChecks assert adapter preservation. |
| 8 | History records can be loaded, appended, deleted by UUID, cleared, copied through copyText, and capped at 200 by default. | VERIFIED | `LingobarHistoryLimits.defaultRecordLimit = 200`; store mutation checks pass; `copyText` is part of record and adapter contract. |
| 9 | Collection adapters expose deterministic `copyText == SavedPhrase.title`. | VERIFIED | `LingobarHubLibrary.collectionItems(from:)` assigns `copyText: phrase.title`; CoreChecks assert equality. |
| 10 | Input/selection source data is captured for history. | VERIFIED | `runAIIfAvailable` captures `historySourceText = text` and `historySourceAppName = mode == .input ? "输入模式" : selectionSource`; source gate asserts the input label and captured arguments. |
| 11 | Successful non-stale AI language actions append through the Plan 01 store only after successful decode and the current-request guard. | PRESENT_BEHAVIOR_UNVERIFIED | Source evidence: record call is after `guard self.activeAIRequestID == requestID`; helper calls `LingobarHistoryRecord.make` and `_ = try? historyStore.append(record)`. No runtime test exercises successful async AI completion with store state. |
| 12 | Setup, fixture, copy/collect, stale completion, decode-error, and provider/network-error paths do not append history. | PRESENT_BEHAVIOR_UNVERIFIED | Source gate slices setup, fixture, copy/collect, catch/error, and pre-guard regions and passed. No runtime test drives each negative path and asserts unchanged history. |

**Score:** 10/12 truths verified (2 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `Sources/LingobarCore/LanguageAction.swift` | Raw-value Codable action enum | VERIFIED | `LanguageAction` conforms to `Codable`; CoreChecks cover encode/decode. |
| `Sources/LingobarCore/LingobarHistoryStore.swift` | Foundation-only history record/store | VERIFIED | Substantive model, builder, limits, default store, CRUD, locking, atomic JSON persistence. |
| `Sources/LingobarCore/LingobarHubLibrary.swift` | Foundation-only collection/history adapters | VERIFIED | Substantive `LingobarHubLibraryItem`, kind enum, and collection/history mapping functions. |
| `Sources/LingoPeekApp/LingobarViewModel.swift` | Injected history store and guarded recording helper | VERIFIED | `historyStore` injection, success-path call, and isolated append helper exist and compile. Runtime behavior remains human-needed as listed. |
| `Sources/LingoPeekCoreChecks/main.swift` | Phase 1 checks and source gate | VERIFIED | All planned check functions exist, are invoked, and `swift run LingoPeekCoreChecks` passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `LanguageAction` | `LingobarHistoryRecord` persistence | Codable raw values | VERIFIED | `LanguageAction: String, Codable`; records store `action: LanguageAction`; CoreChecks assert raw JSON. |
| `LingobarHistoryRecord.make` | `LingobarHistoryStore.append/save` | `recordCompletedHistory` helper | PRESENT_BEHAVIOR_UNVERIFIED | Static wiring is correct and source-gated; live success transition is not behavior-tested. |
| `SavedPhrase` | `LingobarHubLibrary.collectionItems` | Adapter method | VERIFIED | Maps saved phrase fields directly, preserving identity/date/note/title and copy text. |
| `LingobarHistoryRecord` | `LingobarHubLibrary.historyItems` | Adapter method | VERIFIED | Preserves action/type/source/date/sourceText/copyText. |
| `CoreChecks` | Phase gates | SwiftPM commands | VERIFIED | `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks` both passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `LingobarHistoryStore` | `[LingobarHistoryRecord]` | Injected/default file URL at `history.json` | Yes | FLOWING |
| `LingobarHubLibrary.collectionItems` | `[SavedPhrase]` | Existing `PhraseStore`/caller-provided saved phrases | Yes | FLOWING |
| `LingobarHubLibrary.historyItems` | `[LingobarHistoryRecord]` | Local history store records | Yes | FLOWING |
| `LingobarViewModel.recordCompletedHistory` | `result`, `historySourceText`, `historySourceAppName` | Successful decode branch in `runAIIfAvailable` | Source-wired; runtime unexercised | PRESENT_BEHAVIOR_UNVERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| App target builds | `swift build --product LingoPeek` | Build complete | PASS |
| Core data/source checks pass | `swift run LingoPeekCoreChecks` | `LingoPeekCoreChecks passed` | PASS |
| Package manifest unchanged | `git diff --exit-code -- Package.swift` | No diff | PASS |
| No Hub UI source additions | `git ls-files --others --exclude-standard -- Sources ...` | 0 matching untracked Source UI files | PASS |

### Probe Execution

No phase probes were declared or discovered for Phase 1. Step 7c skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| HIST-01 | 01, 02 | Lingobar records completed language actions into a local bounded history store. | NEEDS HUMAN | Store/builder and source-gated ViewModel wiring are present; live AI success/stale runtime append behavior is not behavior-tested. |
| COLL-01 | 01, 02 | User can view locally saved phrases from `PhraseStore` in the Hub collection list. | SATISFIED | `SavedPhrase` adapter exists and is tested; UI rendering deferred to later phases by roadmap. |
| COLL-05 | 01, 02 | User can copy a collection item from card/detail later. | SATISFIED | Adapter exposes `copyText == SavedPhrase.title`; CoreChecks assert this. |
| HIST-02 | 01, 02 | User can view recent history with action badges, item type, source, and relative time inputs. | SATISFIED | Records/adapters expose action, itemType, source, and createdAt; actual UI rendering is Phase 3. |
| HIST-06 | 01, 02 | User can copy, delete, and clear history records. | SATISFIED | `copyText`, `delete(id:)`, `clear()`, and persistence checks are implemented and pass. |

No orphaned Phase 1 requirements found; REQUIREMENTS.md maps exactly HIST-01, COLL-01, COLL-05, HIST-02, and HIST-06 to Phase 1.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `Sources/LingobarCore/LingobarHistoryStore.swift` | 160 | `return []` for missing history file | Info | Expected behavior: missing `history.json` loads empty and is covered by CoreChecks. |

Debt marker scan over modified phase files found no TODO/FIXME/XXX/TBD/HACK/PLACEHOLDER markers.

### Human Verification Required

#### 1. Successful AI completion writes history

**Test:** Configure AI, trigger a successful language action, and inspect Application Support/LingoPeek/history.json.  
**Expected:** One compact newest-first record appears for the completed action; no token/provider/raw payload fields are present.  
**Why human:** Requires a configured AI client or a fake-AI test seam; Phase 1 only has source-placement and core persistence checks.

#### 2. Non-success paths do not write history

**Test:** Exercise setup gate, grammar fixture, copy/collect, decode/provider errors, and a superseded stale completion; inspect history before and after.  
**Expected:** History remains unchanged for non-success paths and stale completions.  
**Why human:** Current automated coverage proves source regions and helper placement, not end-to-end runtime state for each path.

### Gaps Summary

No implementation gaps or blocker anti-patterns were found. Automated build, core checks, privacy greps, and scope checks passed. The only remaining verification need is behavioral runtime confirmation of the async ViewModel success/negative paths, because the implemented source gate is not a live state-transition test.

---

_Verified: 2026-06-27T16:04:50Z_  
_Verifier: the agent (gsd-verifier)_
