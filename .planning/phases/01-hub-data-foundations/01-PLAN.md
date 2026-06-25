---
phase: 01-hub-data-foundations
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - Sources/LingobarCore/LanguageAction.swift
  - Sources/LingobarCore/LingobarHistoryStore.swift
  - Sources/LingobarCore/LingobarHubLibrary.swift
  - Sources/LingoPeekCoreChecks/main.swift
autonomous: true
requirements:
  - HIST-01
  - COLL-01
  - COLL-05
  - HIST-02
  - HIST-06
user_setup: []
must_haves:
  truths:
    - "HIST-01: Completed Lingobar language actions can be represented as compact local history records."
    - "HIST-01: History persistence is Foundation-only JSON under Application Support/LingoPeek/history.json and follows the PhraseStore atomic-write pattern."
    - "HIST-02: History records expose action, item type, source app label, createdAt, visible text, copy text, note, and source text for Hub list/detail rendering."
    - "HIST-06: History records can be loaded, appended, deleted by UUID, cleared, copied through copyText, and capped at 200 records by default."
    - "COLL-01: Existing SavedPhrase values adapt into Hub collection items without creating a second collection store."
    - "COLL-05: Collection adapters expose deterministic copyText equal to the saved phrase title."
  artifacts:
    - "Sources/LingobarCore/LingobarHistoryStore.swift"
    - "Sources/LingobarCore/LingobarHubLibrary.swift"
    - "Updated Sources/LingobarCore/LanguageAction.swift with Codable conformance"
    - "Updated Sources/LingoPeekCoreChecks/main.swift with core Phase 1 checks"
  key_links:
    - "LanguageAction Codable raw values -> LingobarHistoryRecord persistence"
    - "LingobarHistoryRecord.make -> LingobarHistoryStore.append/save cap enforcement"
    - "SavedPhrase -> LingobarHubLibrary.collectionItems"
    - "LingobarHistoryRecord -> LingobarHubLibrary.historyItems"
    - "swift run LingoPeekCoreChecks"
---

## Phase Goal

**As a** Lingobar user, **I want to** have saved phrases and completed language actions represented by real local data contracts, **so that** the Hub can later show collection and history without placeholder data.

<objective>
Create the core data foundation for Phase 1.

Purpose: Give the Hub stable, tested local collection/history contracts before any Hub window or visual surface is built.
Output: Red CoreChecks, `LanguageAction` persistence compatibility, Foundation-only history record/store contracts, collection/history Hub adapters, and bounded history persistence.
</objective>

<execution_context>
@/Users/lancer/.codex/gsd-core/workflows/execute-plan.md
@/Users/lancer/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@CONTEXT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-hub-data-foundations/01-RESEARCH.md
@.planning/phases/01-hub-data-foundations/01-PATTERNS.md
@.planning/phases/01-hub-data-foundations/01-VALIDATION.md
@Sources/LingobarCore/PhraseStore.swift
@Sources/LingobarCore/LingobarResult.swift
@Sources/LingobarCore/LanguageAction.swift
@Sources/LingoPeekCoreChecks/main.swift
@Package.swift
</context>

## Artifacts This Phase Produces

Plan 01 creates or changes:
- `Sources/LingobarCore/LingobarHistoryStore.swift`
- `Sources/LingobarCore/LingobarHubLibrary.swift`
- `Sources/LingobarCore/LanguageAction.swift`
- `Sources/LingoPeekCoreChecks/main.swift`

New symbols:
- `LingobarHistoryLimits`
- `LingobarHistoryRecord`
- `LingobarHistoryRecord.make(action:sourceText:sourceAppName:result:createdAt:id:)`
- `LingobarHistoryStore`
- `LingobarHistoryStore.defaultStore()`
- `LingobarHistoryStore.load()`
- `LingobarHistoryStore.save(_:)`
- `LingobarHistoryStore.append(_:)`
- `LingobarHistoryStore.delete(id:)`
- `LingobarHistoryStore.clear()`
- `LingobarHubLibraryKind`
- `LingobarHubLibraryItem`
- `LingobarHubLibrary.collectionItems(from:)`
- `LingobarHubLibrary.historyItems(from:)`

Changed symbols:
- `LanguageAction` gains `Codable` conformance.
- `Sources/LingoPeekCoreChecks/main.swift` gains `checkLanguageActionCodable()`, `checkLingobarHistoryStore()`, `checkLingobarHistoryRecordBuilderPrivacy()`, and `checkLingobarHubLibraryItems()`.

Unchanged artifacts:
- `Package.swift` is not changed; SwiftPM includes new Swift files under existing targets.
- `SavedPhrase` and `PhraseStore` remain the collection owner and schema.
- No Hub UI, window, design, UI-SPEC, SKELETON.md, database, WebView, or package-dependency work is part of this plan.

## Dependency Graph

| Task | Needs | Creates | Notes |
|------|-------|---------|-------|
| 1-01-01 | Existing CoreChecks and phase requirements | Failing checks for Phase 1 core contracts | Expected to fail before core symbols exist. |
| 1-01-02 | Task 1 check contracts, existing core model shapes | `LanguageAction: Codable`, `LingobarHistoryRecord`, Hub adapter symbols | Pure Foundation core models/adapters. |
| 1-01-03 | Task 2 history record type | `LingobarHistoryStore` CRUD/cap persistence | Reuses the `PhraseStore` file I/O pattern. |

<tasks>

<task id="1-01-01" type="auto" tdd="true">
  <name>Task 1: Add failing CoreChecks for Phase 1 core data contracts</name>
  <files>Sources/LingoPeekCoreChecks/main.swift</files>
  <read_first>
    @Sources/LingoPeekCoreChecks/main.swift
    @Sources/LingobarCore/PhraseStore.swift
    @Sources/LingobarCore/LingobarResult.swift
    @Sources/LingobarCore/LanguageAction.swift
    @.planning/phases/01-hub-data-foundations/01-VALIDATION.md
  </read_first>
  <behavior>
    - `checkLanguageActionCodable()` proves `.translate`, `.grammar`, `.rewrite`, `.examples`, and `.pronounce` encode/decode through stable `LanguageAction.rawValue` values.
    - `checkLingobarHistoryStore()` proves a missing temp `history.json` loads empty, appending three records to a limit-2 store keeps the two newest records, reload preserves fields/order/dates, deleting an existing UUID removes it, deleting a missing UUID is a no-op, and clearing persists an empty list.
    - `checkLingobarHistoryRecordBuilderPrivacy()` proves `LingobarHistoryRecord.make(action:sourceText:sourceAppName:result:createdAt:id:)` returns records for `.translate`, `.grammar`, `.rewrite`, `.examples`, and `.pronounce`; returns nil for `.copy` and `.collect`; trims and bounds text; uses `DefaultCollectionItem` metadata when present; and does not encode sentinel token/base URL/model/provider strings that were never passed to the builder.
    - `checkLingobarHubLibraryItems()` proves `SavedPhrase` adapts to collection items with ID/date/note preserved, `copyText == title`, `kind == .collection`, `source == "Lingobar"`, and `itemType == "文本"`; it also proves history records adapt with action, item type, source app, created date, source text, and copy text preserved.
  </behavior>
  <action>Add the four check functions above near `checkPhraseStore()` and call them in the final `do` block before `checkPhraseStore()`. Use the existing `check(_:_:)` helper and temporary-directory pattern. The first run after this task should fail because `LanguageAction` is not yet `Codable` and the `LingobarHistory...` / `LingobarHub...` symbols do not exist. Do not add XCTest, Swift Testing, new targets, new dependencies, AI probes, app target imports, or UI checks.</action>
  <acceptance_criteria>
    - Source contains the four new check functions with the exact names listed in this task.
    - The final `do` block invokes all four new check functions.
    - Checks reference only `Foundation` and `LingobarCore` APIs available to the `LingoPeekCoreChecks` target.
    - No live AI, clipboard, Accessibility, AppKit, or user environment state is required.
  </acceptance_criteria>
  <verify>
    <automated>swift run LingoPeekCoreChecks</automated>
    <expected_result>After Task 1 only, this command should fail at compile time because production symbols are intentionally missing. After Tasks 2-3, the same command must pass for core checks.</expected_result>
  </verify>
  <done>CoreChecks lock HIST-01, COLL-01, COLL-05, HIST-02, and HIST-06 core behavior before production implementation.</done>
</task>

<task id="1-01-02" type="auto" tdd="true">
  <name>Task 2: Add Foundation-only history and Hub library contracts</name>
  <files>Sources/LingobarCore/LanguageAction.swift, Sources/LingobarCore/LingobarHistoryStore.swift, Sources/LingobarCore/LingobarHubLibrary.swift, Sources/LingoPeekCoreChecks/main.swift</files>
  <read_first>
    @Sources/LingobarCore/LanguageAction.swift
    @Sources/LingobarCore/LingobarResult.swift
    @Sources/LingobarCore/PhraseStore.swift
    @Sources/LingoPeekCoreChecks/main.swift
    @.planning/phases/01-hub-data-foundations/01-PATTERNS.md
  </read_first>
  <behavior>
    - `LanguageAction` persists by raw value while keeping existing `id`, `title`, `symbol`, shortcut, availability, and default-action behavior unchanged.
    - `LingobarHistoryRecord` stores compact, user-visible fields only: `id`, `action`, `itemType`, `visibleText`, `copyText`, `note`, `sourceText`, `sourceAppName`, and `createdAt`.
    - `LingobarHistoryRecord.make(action:sourceText:sourceAppName:result:createdAt:id:)` builds records only for `.translate`, `.grammar`, `.rewrite`, `.examples`, and `.pronounce`; it returns nil for `.copy` and `.collect`.
    - `LingobarHistoryLimits` provides named caps: `defaultRecordLimit = 200`, `visibleTextLength = 240`, `noteLength = 240`, `copyTextLength = 2000`, and `sourceTextLength = 2000`.
    - `LingobarHubLibrary.collectionItems(from:)` adapts existing `SavedPhrase` values; it does not create, require, or imply another collection JSON file.
    - `LingobarHubLibrary.historyItems(from:)` adapts `LingobarHistoryRecord` values into Hub list/detail items without importing AppKit or SwiftUI.
  </behavior>
  <action>Change `LanguageAction` to conform to `Codable`. Create `Sources/LingobarCore/LingobarHistoryStore.swift` with `import Foundation`, `public enum LingobarHistoryLimits`, and `public struct LingobarHistoryRecord: Identifiable, Equatable, Codable, Sendable`. Implement `LingobarHistoryRecord.make(action:sourceText:sourceAppName:result:createdAt:id:)` as a pure builder that trims whitespace, rejects empty source text, uses `result.defaultCollectionItem` first for `visibleText`, `copyText`, `note`, and `itemType`, falls back to `result.defaultCollectionTitle`, `result.summary`, and `"文本"`, bounds strings through the named limits, and defaults an empty source app label to `"Lingobar"`. Create `Sources/LingobarCore/LingobarHubLibrary.swift` with `public enum LingobarHubLibraryKind: String, CaseIterable, Identifiable, Codable, Sendable` cases `.collection` and `.history`, `public struct LingobarHubLibraryItem: Identifiable, Equatable, Sendable`, and `public enum LingobarHubLibrary` static adapter methods. Keep both new core files Foundation-only. Do not modify `SavedPhrase`, `PhraseStore`, or `Package.swift`; collection metadata in Phase 1 is adapter-only by decision from the resolved research questions.</action>
  <acceptance_criteria>
    - `LanguageAction` declaration includes `Codable` and all existing behavior still passes existing checks.
    - `LingobarHistoryRecord` has no fields for API token, provider, model, base URL, Authorization header, prompt, raw provider JSON, request body, response body, clipboard snapshot, AX element, or bundle path.
    - `LingobarHistoryRecord.make(...)` returns nil for `.copy` and `.collect`, so non-language utility actions do not enter history.
    - `LingobarHubLibrary.collectionItems(from:)` preserves `SavedPhrase.id`, `SavedPhrase.title`, `SavedPhrase.note`, and `SavedPhrase.createdAt`; sets `copyText` to `SavedPhrase.title`; sets `source` to `"Lingobar"`; and sets `itemType` to `"文本"`.
    - `LingobarHubLibrary.historyItems(from:)` preserves `LingobarHistoryRecord.action`, `itemType`, `sourceAppName`, `createdAt`, `copyText`, and `sourceText`.
  </acceptance_criteria>
  <verify>
    <automated>swift run LingoPeekCoreChecks</automated>
    <automated>! rg -n 'AIProviderConfiguration|OpenAICompatibleClient|Authorization|apiToken|baseURLString|systemPrompt|DeepSeek|DEEPSEEK|AI_API_TOKEN|AI_MODEL|httpBody' Sources/LingobarCore/LingobarHistoryStore.swift Sources/LingobarCore/LingobarHubLibrary.swift</automated>
  </verify>
  <done>Core history records and Hub library adapters satisfy HIST-01, HIST-02, COLL-01, and COLL-05 contracts without UI, dependency, or duplicate collection storage.</done>
</task>

<task id="1-01-03" type="auto" tdd="true">
  <name>Task 3: Implement bounded local LingobarHistoryStore persistence</name>
  <files>Sources/LingobarCore/LingobarHistoryStore.swift, Sources/LingoPeekCoreChecks/main.swift</files>
  <read_first>
    @Sources/LingobarCore/PhraseStore.swift
    @Sources/LingobarCore/LingobarHistoryStore.swift
    @Sources/LingoPeekCoreChecks/main.swift
    @.planning/phases/01-hub-data-foundations/01-RESEARCH.md
  </read_first>
  <behavior>
    - Missing `history.json` loads as an empty array.
    - Saves create the parent directory, encode pretty-printed sorted-key ISO-8601 JSON, and write atomically.
    - Appends insert newest records first and enforce the configured cap.
    - Saves also enforce the cap so callers cannot bypass bounded history through `save(_:)`.
    - Deletes remove only matching history UUIDs and leave missing UUID deletion as a no-op.
    - Clear persists an empty history list.
    - Corrupt JSON throws instead of silently clearing user history.
  </behavior>
  <action>In `Sources/LingobarCore/LingobarHistoryStore.swift`, add `public final class LingobarHistoryStore: @unchecked Sendable` using the same `fileURL`, `JSONEncoder`, `JSONDecoder`, and `NSLock` pattern as `PhraseStore`. Provide `public init(fileURL: URL, limit: Int = LingobarHistoryLimits.defaultRecordLimit)`, `public static func defaultStore() -> LingobarHistoryStore`, `public func load() throws -> [LingobarHistoryRecord]`, `public func save(_ records: [LingobarHistoryRecord]) throws`, `@discardableResult public func append(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord]`, `@discardableResult public func delete(id: UUID) throws -> [LingobarHistoryRecord]`, and `public func clear() throws`. Use `Application Support/LingoPeek/history.json` for the default path. Avoid nested locking deadlocks by using private unlocked helpers inside mutating methods or by keeping each public method's critical section single-layered. Keep the store in `LingobarCore` with only Foundation imports.</action>
  <acceptance_criteria>
    - `LingobarHistoryStore.defaultStore()` writes to `history.json`, not `phrases.json`.
    - `append(_:)` returns the persisted newest-first capped list.
    - `delete(id:)` returns the persisted list after deletion and does not affect `PhraseStore`.
    - `clear()` persists an empty array and subsequent `load()` returns `[]`.
    - `save(_:)` enforces the configured cap even if passed more records than the limit.
    - `checkLingobarHistoryStore()` passes using a temporary file and `limit: 2`.
  </acceptance_criteria>
  <verify>
    <automated>swift run LingoPeekCoreChecks</automated>
    <automated>rg -n 'history\.json|LingobarHistoryStore|NSLock|\.atomic|dateEncodingStrategy = \.iso8601|dateDecodingStrategy = \.iso8601' Sources/LingobarCore/LingobarHistoryStore.swift</automated>
  </verify>
  <done>HIST-01 and HIST-06 storage operations work through bounded Foundation JSON persistence matching the existing phrase-store pattern.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Core builder -> local history JSON | User text and final user-visible result fields cross into persistent local storage. |
| Existing collection store -> Hub adapters | Existing `SavedPhrase` data is transformed for Hub rendering and copy behavior without duplicating storage. |
| Store caller -> history mutation APIs | App/UI callers can append, save, delete, or clear local history records. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-01-01 | Information Disclosure | `LingobarHistoryRecord` / `history.json` | high | mitigate | Build records only from `LanguageAction`, source text, source app display label, final `LingobarResult` visible fields, UUID, and Date; CoreChecks encode sentinel privacy assertions; source gate rejects provider/token/prompt/raw response references in core history files. |
| T-01-02 | Denial of Service | `LingobarHistoryStore.append` / `save` | medium | mitigate | Enforce `LingobarHistoryLimits.defaultRecordLimit = 200` by default and enforce configured caps on append and save. |
| T-01-03 | Tampering | History mutations vs collection storage | medium | mitigate | Store history in `history.json`; leave collection persistence owned by `PhraseStore` and adapt `SavedPhrase` through `LingobarHubLibrary.collectionItems(from:)`. |
| T-01-04 | Repudiation | Local history mutation audit | low | accept | Single-user local app has no account or audit-log requirement; each record still carries UUID and `createdAt` for deterministic local behavior. |
</threat_model>

## Plan Set Source Audit

| Source | ID | Feature / Requirement | Plan Task | Status | Notes |
|--------|----|-----------------------|-----------|--------|-------|
| GOAL | Phase 1 | Give the Hub real local data contracts before building the full visual surface. | 1-01-01 through 1-02-02 | COVERED | Plan 01 builds data contracts/store; Plan 02 wires successful history recording and verifies all gates. |
| REQ | HIST-01 | Lingobar records completed language actions into a local bounded history store. | 1-01-01, 1-01-02, 1-01-03, 1-02-01 | COVERED | Store plus ViewModel success-path recording. |
| REQ | COLL-01 | User can view locally saved phrases from `PhraseStore` in the Hub collection list. | 1-01-01, 1-01-02 | COVERED | Adapter maps `SavedPhrase` to Hub collection items without duplicate storage. |
| REQ | COLL-05 | User can copy a collection item from card/detail later. | 1-01-01, 1-01-02 | COVERED | Adapter exposes deterministic `copyText == SavedPhrase.title`. |
| REQ | HIST-02 | User can view recent history with action badges, item type, source, and relative time inputs. | 1-01-01, 1-01-02 | COVERED | Records/adapters expose action, itemType, source, and createdAt; UI-relative formatting stays outside Phase 1. |
| REQ | HIST-06 | User can copy, delete, and clear history records. | 1-01-01, 1-01-02, 1-01-03 | COVERED | `copyText`, `delete(id:)`, and `clear()` are planned and checked. |
| RESEARCH | R-01 | Use Foundation `Codable` JSON, atomic writes, ISO-8601 dates, and `NSLock` like `PhraseStore`. | 1-01-03 | COVERED | Store pattern is required. |
| RESEARCH | R-02 | Reuse `PhraseStore`; do not create parallel collection persistence or change `SavedPhrase` in Phase 1. | 1-01-02, 1-02-02 | COVERED | `SavedPhrase` adapter only. |
| RESEARCH | R-03 | Record only after non-stale successful AI decode in `LingobarViewModel.runAIIfAvailable`. | 1-02-01 | COVERED | Plan 02 depends on Plan 01 artifacts. |
| RESEARCH | R-04 | Keep history compact and exclude secrets/raw provider payloads. | 1-01-02, 1-02-01, 1-02-02 | COVERED | Builder signature, privacy checks, and source gates enforce this. |
| RESEARCH | R-05 | Include pronounce history support even if design prototype omitted it. | 1-01-01, 1-01-02 | COVERED | Checks and builder include `.pronounce`. |
| RESEARCH | R-06 | Default bounded history cap is 200. | 1-01-02, 1-01-03 | COVERED | Resolved research decision is encoded in `LingobarHistoryLimits.defaultRecordLimit`. |
| CONTEXT | User revision | Keep Phase 1 data-only: no Hub UI/window/design work, no UI-SPEC requirement, no SKELETON.md. | 1-01-02, 1-02-02 | COVERED | Prohibitions and final verification exclude UI/design outputs. |

No source-audit gaps found.

<verification>
Plan 01 checks:
- `swift run LingoPeekCoreChecks`
- Core history and Hub adapter files import Foundation only.
- No `SavedPhrase`, `PhraseStore`, `Package.swift`, UI, design, database, WebView, or package-dependency changes are introduced.
</verification>

<success_criteria>
1. `LanguageAction` can be persisted by raw value.
2. History records can be appended, loaded, deleted, cleared, and capped through a Foundation-only `LingobarHistoryStore`.
3. Existing `SavedPhrase` values adapt into `LingobarHubLibraryItem` collection items with copy-ready text and metadata.
4. `swift run LingoPeekCoreChecks` covers history persistence and collection/history transformations.
</success_criteria>

<output>
Create `.planning/phases/01-hub-data-foundations/01-SUMMARY.md` when Plan 01 execution is done. Do not commit unless a later explicit instruction asks for a commit.
</output>
