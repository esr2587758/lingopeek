# Phase 1: Hub Data Foundations - Research

**Researched:** 2026-06-26  
**Domain:** Native macOS SwiftPM local persistence and Hub data contracts  
**Confidence:** HIGH for codebase contracts and resolved Phase 1 product defaults

## User Constraints

- Phase 1 is `Hub Data Foundations`; it must give the Hub real local data contracts before the visual surface is built. [VERIFIED: user prompt]
- Requirements in scope: `HIST-01`, `COLL-01`, `COLL-05`, `HIST-02`, `HIST-06`. [VERIFIED: user prompt]
- Do not implement code and do not commit. [VERIFIED: user prompt]
- No phase-local `CONTEXT.md` exists; the user selected continuing without it. [VERIFIED: gsd init.phase-op + user prompt]
- New-project decisions are locked: replace settings as the native Hub entry, use real collection plus real generated history, and prioritize native SwiftUI behavior over pixel-perfect web clone. [VERIFIED: user prompt]
- Keep the implementation dependency-free unless explicitly requested; the repository has no third-party Swift package dependencies. [VERIFIED: AGENTS.md, Package.swift]
- Checker resolution decisions are locked for Phase 1: default history cap is `200`; collection metadata is adapter-only and `SavedPhrase` is not changed. [VERIFIED: user prompt]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HIST-01 | Lingobar records completed language actions into a local bounded history store. | Add `LingobarHistoryStore` plus `LingobarHistoryRecord`; record only after non-stale successful AI decode in `LingobarViewModel.runAIIfAvailable`. [VERIFIED: .planning/REQUIREMENTS.md, Sources/LingoPeekApp/LingobarViewModel.swift:214] |
| COLL-01 | User can view locally saved phrases from `PhraseStore` in the Hub collection list. | Reuse `PhraseStore.defaultStore()` and expose `SavedPhrase` through a non-duplicating Hub adapter. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:16, Sources/LingobarCore/LingobarResult.swift:59] |
| COLL-05 | User can copy a collection item from card or detail pane. | Adapter should expose `copyText == SavedPhrase.title`; current saved phrase storage already has the copy-ready title. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:59] |
| HIST-02 | User can view recent history with action badges, item type, source, and relative time. | History record needs `action`, `itemType`, `sourceAppName`, and `createdAt`; these are available from `LanguageAction`, `LingobarResult`/`DefaultCollectionItem`, and `LingobarViewModel.selectionSource`. [VERIFIED: Sources/LingobarCore/LanguageAction.swift:9, Sources/LingobarCore/LingobarResult.swift:47, Sources/LingoPeekApp/LingobarViewModel.swift:18] |
| HIST-06 | User can copy, delete, and clear history records. | Store API should include `delete(id:)` and `clear()`; adapter should expose `copyText`. [VERIFIED: .planning/REQUIREMENTS.md] |

## Findings

- `PhraseStore` is the pattern to copy for local JSON persistence: it uses `JSONEncoder`/`JSONDecoder`, pretty-printed sorted-key JSON, ISO-8601 dates, `NSLock`, Application Support storage, and atomic writes. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:3]
- `SavedPhrase` currently persists only `id`, `title`, `note`, and `createdAt`; type/source metadata from `DefaultCollectionItem` is currently dropped when phrases are saved. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:59, Sources/LingoPeekApp/LingobarViewModel.swift:136]
- `LingobarViewModel.runAIIfAvailable` is the correct recording seam for generated history because it is where successful AI output is decoded into either `GrammarResult` or `StructuredLingobarResult` and stale responses are rejected by `activeAIRequestID`. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:223, Sources/LingoPeekApp/LingobarViewModel.swift:239]
- History should not record setup failures, unavailable actions, stale completions, decode errors, network errors, copy, or collect actions in Phase 1; those paths either return before AI completion or set error state instead of completed result state. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:90, Sources/LingoPeekApp/LingobarViewModel.swift:214, Sources/LingoPeekApp/LingobarViewModel.swift:252]
- The design prototype models collection and history with similar fields (`type`, `text`, `meta`, `src`, `when`), while history adds `action` and `status`; use that as UI-facing adapter shape, not as persisted JavaScript data. [VERIFIED: designs/lingobar-hub/data.jsx:1]
- The design mock history actions omit `发音`, but project requirements include pronunciation history; requirements should win and history contracts should support `.pronounce`. [VERIFIED: designs/lingobar-hub/data.jsx:37, .planning/REQUIREMENTS.md]

**Primary recommendation:** add a small Foundation-only history model/store plus Hub adapter structs in `LingobarCore`, inject the history store into `LingobarViewModel`, and record compact successful action summaries without duplicating collection storage. [VERIFIED: codebase architecture]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| History persistence | Core Domain / Persistence | App Workflow | `LingobarCore` already owns portable JSON stores; `LingobarViewModel` only supplies completed action events. [VERIFIED: .planning/codebase/ARCHITECTURE.md] |
| Collection list data | Core Domain / Persistence | Hub UI later | `PhraseStore` is the collection owner; the Hub should read adapters, not a second collection file. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:16] |
| Completed action recording | App Workflow | Core builder | Only the app view model sees mode, source app, active action, and final decoded result together. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:36] |
| Copy/delete/clear contracts | Core Domain | Hub UI later | Phase 1 can define deterministic copy text and store mutations before Phase 2/3 renders them. [VERIFIED: .planning/ROADMAP.md] |
| Privacy filtering | Core builder | App Workflow | A pure builder can constrain persisted fields and avoid passing provider/client/secrets into history storage. [VERIFIED: Sources/LingoPeekApp/AppSettings.swift:50] |

## Existing Patterns

### Persistence

- Use a dedicated `final class ...Store: @unchecked Sendable` with an injected `fileURL` for tests and a `defaultStore()` path under Application Support `LingoPeek`. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:3]
- Missing JSON files should load as an empty array; saves should create the parent directory and write atomically. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:22]
- Temporary-file persistence checks already exist in `LingoPeekCoreChecks`; `checkPhraseStore()` creates a UUID temp directory, writes through the production API, loads through the production API, and asserts persisted fields. [VERIFIED: Sources/LingoPeekCoreChecks/main.swift:530]

### Result and Collection Shape

- Generic AI results bridge through `StructuredLingobarResult.lingobarResult(shortcut:)`, preserving `summary`, rows, chips, `moreActionTitle`, and `defaultCollectionItem`. [VERIFIED: Sources/LingobarCore/StructuredLingobarResult.swift:25]
- Grammar results bridge through `GrammarResult.lingobarResult(shortcut:)`, where `summary` is the Chinese meaning and `defaultCollectionItem` is preserved. [VERIFIED: Sources/LingobarCore/GrammarResult.swift:78]
- `DefaultCollectionItem` already carries the desired collected item label, note, and source-based type string such as `短语|英文|例句|句型|文本`. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:47, Sources/LingoPeekApp/LingobarViewModel.swift:276]
- Existing result copy behavior copies `result.summary`; Hub history copy should intentionally choose whether it mirrors that panel copy behavior or copies a stored `copyText` field. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:151]

## Proposed Contracts

### New Core Types

Add these in `Sources/LingobarCore/`, preferably one focused file such as `LingobarHubData.swift` or split `LingobarHistoryStore.swift` / `LingobarHubItem.swift`. [VERIFIED: .planning/codebase/CONVENTIONS.md]

```swift
public enum LingobarHubItemType: String, Codable, CaseIterable, Identifiable, Sendable {
    case phrase = "短语"
    case sentencePattern = "句型"
    case example = "例句"
    case english = "英文"
    case text = "文本"
}
```

Use this enum only as the Hub/core normalized type; keep `DefaultCollectionItem.type` as `String` at the AI boundary so provider JSON remains tolerant. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:47]

```swift
public struct LingobarCollectionItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var phraseID: UUID
    public var type: LingobarHubItemType
    public var text: String
    public var note: String
    public var source: String
    public var createdAt: Date
    public var copyText: String
}
```

`LingobarCollectionItem` should be an adapter over `SavedPhrase`, not a persisted replacement; `copyText` should default to `SavedPhrase.title`. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:59]

```swift
public struct LingobarHistoryRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var action: LanguageAction
    public var itemType: LingobarHubItemType
    public var visibleText: String
    public var copyText: String
    public var note: String
    public var sourceText: String
    public var sourceAppName: String
    public var createdAt: Date
}
```

`visibleText` supports the history list, `copyText` supports `HIST-06`, `sourceText` supports relaunch/details later, and `sourceAppName` supports the `src` design field. [VERIFIED: designs/lingobar-hub/data.jsx:36]

```swift
public final class LingobarHistoryStore: @unchecked Sendable {
    public init(fileURL: URL, limit: Int = 200)
    public static func defaultStore() -> LingobarHistoryStore
    public func load() throws -> [LingobarHistoryRecord]
    @discardableResult public func append(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord]
    @discardableResult public func delete(id: UUID) throws -> [LingobarHistoryRecord]
    public func clear() throws
    public func save(_ records: [LingobarHistoryRecord]) throws
}
```

Use `Application Support/LingoPeek/history.json`, newest-first order, and a named cap. The resolved default history cap is `200`, exposed through a named constant so later requirements can intentionally change it. [VERIFIED: user prompt]

### SavedPhrase Metadata

Phase 1 should not create a parallel collection database. [VERIFIED: .planning/PROJECT.md]

Phase 1 decision: add a Hub adapter that maps existing `SavedPhrase` rows to `type: .text`, `source: "Lingobar"`, `text/copyText: title`, `note: note`, and `createdAt: createdAt`. Do not add `type` or `source` fields to `SavedPhrase` in Phase 1. [VERIFIED: user prompt, Sources/LingobarCore/LingobarResult.swift:59]

## Integration Points

- Add `private let historyStore: LingobarHistoryStore` and dependency-inject it through `LingobarViewModel.init(store:historyStore:)` so core checks can use temp files without touching user history. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:24]
- Record after successful decode and after the request ID guard in `runAIIfAvailable`, once `self.result` and `self.grammarResult` have been set. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:239]
- Pass only `action`, the current mode-derived source text, source app label, final `LingobarResult`, and timestamp into a pure history-record builder. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:210]
- For selection mode, use `selectedText` and `selectionSource`; for input mode, use `inputText` and source label `输入模式`, not the previous `selectionSource` value. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:18, Sources/LingoPeekApp/LingobarViewModel.swift:51]
- Record `.translate`, `.grammar`, `.rewrite`, `.examples`, and `.pronounce`; do not record `.copy` or `.collect`. [VERIFIED: Sources/LingobarCore/LanguageAction.swift:9, .planning/REQUIREMENTS.md]
- Do not record when `runAIIfAvailable` returns because AI setup is missing, when `perform` rejects unavailable grammar, when decoding/network errors occur, or when a stale response returns after another request has started. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:90, Sources/LingoPeekApp/LingobarViewModel.swift:214, Sources/LingoPeekApp/LingobarViewModel.swift:252]
- `presentGrammarFixture` is a deterministic development path; do not automatically persist fixture runs unless a future visual/test mode explicitly needs seeded history. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:63]

## Privacy

- History must not store API tokens, provider secrets, Authorization headers, raw `AIProviderConfiguration`, or `OpenAICompatibleClient` state. Token inputs currently come from environment variables or `LocalTokenStore`, and outbound requests put the token in an Authorization header. [VERIFIED: Sources/LingoPeekApp/AppSettings.swift:50, Sources/LingobarCore/OpenAICompatibleClient.swift:91]
- History must not store provider error response bodies; `OpenAICompatibleError.server` can carry raw server body text, and Phase 1 history is for completed actions only. [VERIFIED: Sources/LingobarCore/OpenAICompatibleClient.swift:42]
- Store compact user-visible data only: action, item type, visible text, copy text, note, source text, source app display name, UUID, and created date. [VERIFIED: .planning/PROJECT.md]
- Normalize strings before persistence: trim whitespace, avoid empty records, and cap `visibleText`/`note` for list display while preserving a bounded `copyText` field for copy behavior. The exact copy cap is not specified; use a named constant and test it. [ASSUMED]
- Do not store hidden clipboard snapshots, AX element details, bundle paths, prompt text, raw AI JSON, rows/chips wholesale, model names, base URLs, or token-bearing settings in `history.json`. [VERIFIED: Sources/LingoPeekApp/SelectionReader.swift via codebase audit, Sources/LingoPeekApp/AppSettings.swift:32]

## Test Strategy

Add focused checks to `Sources/LingoPeekCoreChecks/main.swift`; do not add XCTest unless the package gains a test target. [VERIFIED: .planning/codebase/TESTING.md]

- `checkHistoryStore()` should create a temp `history.json`, assert missing file loads empty, append persists newest-first records, appending beyond the cap drops oldest records, and reload preserves fields. [VERIFIED: Sources/LingoPeekCoreChecks/main.swift:530]
- `checkHistoryDeleteAndClear()` should delete by UUID, ignore or safely handle missing UUIDs, clear all records, and verify reload after clear is empty. [VERIFIED: .planning/REQUIREMENTS.md]
- `checkHistoryRecordBuilder()` should build deterministic records for translate, grammar, rewrite, examples, and pronounce using local fixture `LingobarResult` values, then assert action title, item type, source app, source text, visible text, copy text, and timestamp. [VERIFIED: Sources/LingobarCore/LocalLanguageEngine.swift:6]
- `checkHistoryRecordPrivacy()` should use sentinel strings that look like token/base URL/model values outside the builder input and assert they cannot appear in encoded `history.json`; this works best by not passing provider settings to the builder at all. [VERIFIED: Sources/LingoPeekApp/AppSettings.swift:50]
- `checkHubCollectionAdapter()` should adapt old `SavedPhrase` values and assert id/date preservation, `copyText == title`, note preservation, default type/source, and no second collection file requirement. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:59]
- Because Phase 1 does not change `SavedPhrase`, no `SavedPhrase` migration or old-JSON decode check is required in this phase. [VERIFIED: user prompt, Sources/LingobarCore/PhraseStore.swift:30]

## Risks

- Adding non-optional fields to `SavedPhrase` without custom/default decoding would break old `phrases.json` files. [VERIFIED: Sources/LingobarCore/LingobarResult.swift:59]
- Recording history before the `activeAIRequestID` guard would persist stale completions after rapid action switching. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:223]
- Using `selectionSource` for input mode can leak stale source-app labels from a previous selection; derive `输入模式` from `mode == .input`. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:18]
- Storing whole `LingobarResult.rows`, raw provider JSON, or prompts would make history larger and less privacy-preserving than the milestone asks. [VERIFIED: .planning/PROJECT.md]
- Full-file JSON writes match current MVP patterns but can become slow for very large collections/history; keep the bounded cap and avoid SQLite in Phase 1. [VERIFIED: .planning/codebase/CONCERNS.md]
- The design data's history filters omit pronunciation; plans must follow requirements and include `.pronounce`. [VERIFIED: designs/lingobar-hub/data.jsx:37, .planning/REQUIREMENTS.md]

## Standard Stack

| Area | Use | Why |
|------|-----|-----|
| Persistence | Foundation `Codable`, `JSONEncoder`, `JSONDecoder`, `FileManager`, atomic file writes | Matches `PhraseStore` and keeps `LingobarCore` dependency-free. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:1] |
| Domain models | Public `struct`/`enum` value types conforming to `Codable`, `Equatable`, `Sendable`, `Identifiable` where useful | Matches existing core model conventions. [VERIFIED: .planning/codebase/CONVENTIONS.md] |
| App integration | `LingobarViewModel` dependency injection and main-actor workflow state | This is the existing language action coordinator. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:5] |
| Checks | `swift run LingoPeekCoreChecks` with local `check(_:_:)` helper | Current zero-dependency verification pattern. [VERIFIED: Sources/LingoPeekCoreChecks/main.swift:14] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collection persistence | A second Hub collection JSON file | `PhraseStore` plus `LingobarCollectionItem` adapter | Avoids duplicate storage and divergent delete/copy behavior. [VERIFIED: Sources/LingobarCore/PhraseStore.swift:16] |
| History database | SQLite/Core Data/custom migration layer | Small bounded JSON `LingobarHistoryStore` | Phase 1 is local MVP data foundation and existing persistence is JSON. [VERIFIED: .planning/ROADMAP.md] |
| Action labels | Separate string tables for history actions | `LanguageAction.title`, `id`, and enum cases | Keeps Hub badges aligned with existing toolbar actions. [VERIFIED: Sources/LingobarCore/LanguageAction.swift:42] |
| Copy semantics | Ad hoc per-view pasteboard text guessing | Explicit `copyText` in Hub adapters | Lets card/detail copy use the same deterministic value. [VERIFIED: .planning/REQUIREMENTS.md] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| SwiftPM / Swift | Build and checks | yes | Apple Swift 6.3.2 | None needed. [VERIFIED: `swift --version`] |
| `rg` | Research/source grounding | yes | bundled Codex path | `grep` if unavailable. [VERIFIED: `command -v rg`] |
| External packages | None for Phase 1 | n/a | n/a | Stay dependency-free. [VERIFIED: Package.swift] |

**Missing dependencies with no fallback:** none. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Custom Swift executable checks in `LingoPeekCoreChecks`. [VERIFIED: Sources/LingoPeekCoreChecks/main.swift] |
| Config file | none; SwiftPM target is declared in `Package.swift`. [VERIFIED: Package.swift] |
| Quick run command | `swift run LingoPeekCoreChecks` |
| Full suite command | `swift build --product LingoPeek && swift run LingoPeekCoreChecks` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| HIST-01 | Append/load bounded completed action history | unit-style executable check | `swift run LingoPeekCoreChecks` | Existing file; add `checkHistoryStore()` [VERIFIED: Sources/LingoPeekCoreChecks/main.swift] |
| COLL-01 | Adapt `SavedPhrase` into Hub collection list item | unit-style executable check | `swift run LingoPeekCoreChecks` | Existing file; add `checkHubCollectionAdapter()` [VERIFIED: Sources/LingoPeekCoreChecks/main.swift] |
| COLL-05 | Collection adapter exposes copy-ready text | unit-style executable check | `swift run LingoPeekCoreChecks` | Existing file; extend `checkHubCollectionAdapter()` [VERIFIED: .planning/REQUIREMENTS.md] |
| HIST-02 | History adapter exposes action badge/type/source/created date | unit-style executable check | `swift run LingoPeekCoreChecks` | Existing file; add `checkHistoryRecordBuilder()` [VERIFIED: .planning/REQUIREMENTS.md] |
| HIST-06 | Delete and clear history mutate persisted store | unit-style executable check | `swift run LingoPeekCoreChecks` | Existing file; add `checkHistoryDeleteAndClear()` [VERIFIED: .planning/REQUIREMENTS.md] |

### Sampling Rate

- Per task commit: `swift run LingoPeekCoreChecks` for core model/store work. [VERIFIED: .planning/codebase/TESTING.md]
- Per wave merge: `swift build --product LingoPeek && swift run LingoPeekCoreChecks`. [VERIFIED: AGENTS.md]
- Phase gate: full suite green before verification; do not run live AI probe unless user provides secrets. [VERIFIED: AGENTS.md]

### Wave 0 Gaps

- [ ] `Sources/LingobarCore/LingobarHistoryStore.swift` or equivalent core file for history model/store. [VERIFIED: no existing history store found by rg]
- [ ] `Sources/LingobarCore/LingobarHubData.swift` or equivalent adapter file for collection/history Hub item contracts. [VERIFIED: no existing Hub data model found by rg]
- [ ] New check functions in `Sources/LingoPeekCoreChecks/main.swift` for history store, history builder/privacy, and collection adapter. [VERIFIED: Sources/LingoPeekCoreChecks/main.swift:546]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No app user auth in Phase 1. [VERIFIED: .planning/codebase/INTEGRATIONS.md] |
| V3 Session Management | no | No sessions. [VERIFIED: .planning/codebase/INTEGRATIONS.md] |
| V4 Access Control | no | Single-user local app boundary. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Trim, reject empty records, bound stored history strings, and use typed enum/action validation. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:118] |
| V6 Cryptography | yes | Do not store tokens/secrets in history; do not introduce crypto or custom secret storage in this phase. [VERIFIED: Sources/LingoPeekApp/LocalTokenStore.swift:3] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage into history JSON | Information Disclosure | History builder must not accept or persist provider configuration, token, Authorization header, model, base URL, raw server errors, or prompt text. [VERIFIED: Sources/LingoPeekApp/AppSettings.swift:50] |
| Stale AI completion persisted after action switch | Tampering | Record only after request ID guard. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:239] |
| Unbounded local history growth | Denial of Service | Enforce `LingobarHistoryLimits.defaultRecordLimit = 200` at append/save. [VERIFIED: user prompt] |

## Package Legitimacy Audit

No external packages should be installed for Phase 1; `Package.swift` declares only local targets and AGENTS.md forbids new dependencies without explicit request. [VERIFIED: Package.swift, AGENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Bound `visibleText`, `note`, and `copyText` with named constants. | Privacy | Too-small caps could make Hub copy less useful; tests should lock chosen behavior. |

## Open Questions (RESOLVED)

1. **Exact history retention cap**
   - What we know: history must be bounded. [VERIFIED: .planning/ROADMAP.md]
   - Resolution: use `200` as the default cap for Phase 1 history records. Implement this as `LingobarHistoryLimits.defaultRecordLimit` and keep `LingobarHistoryStore(fileURL:limit:)` injectable for checks. [VERIFIED: user prompt]

2. **Whether to persist collection type/source now**
   - What we know: `DefaultCollectionItem.type` exists, but current `SavedPhrase` drops it. [VERIFIED: Sources/LingoPeekApp/LingobarViewModel.swift:143]
   - Resolution: Phase 1 uses adapter-only collection metadata and does not change `SavedPhrase`. `LingobarHubLibrary.collectionItems(from:)` supplies `itemType == "文本"` and `source == "Lingobar"` for existing saved phrases. [VERIFIED: user prompt]

## Sources

- `AGENTS.md` - project constraints and verification commands. [VERIFIED: AGENTS.md]
- `CONTEXT.md` - product language, collection semantics, and privacy boundaries. [VERIFIED: CONTEXT.md]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - phase scope and milestone decisions. [VERIFIED: planning docs]
- `.planning/codebase/ARCHITECTURE.md`, `STACK.md`, `TESTING.md`, `CONVENTIONS.md`, `CONCERNS.md`, `INTEGRATIONS.md` - existing boundaries, checks, and risks. [VERIFIED: codebase docs]
- `Sources/LingobarCore/PhraseStore.swift` - local JSON persistence pattern. [VERIFIED: codebase grep]
- `Sources/LingobarCore/LingobarResult.swift` - `LingobarResult`, `DefaultCollectionItem`, and `SavedPhrase` contracts. [VERIFIED: codebase grep]
- `Sources/LingobarCore/LanguageAction.swift` - action enum, labels, availability, shortcuts. [VERIFIED: codebase grep]
- `Sources/LingoPeekApp/LingobarViewModel.swift` - current action flow, collection save, copy, and AI completion seam. [VERIFIED: codebase grep]
- `Sources/LingoPeekApp/AppSettings.swift`, `LocalTokenStore.swift`, `OpenAICompatibleClient.swift` - token/provider boundaries. [VERIFIED: codebase grep]
- `Sources/LingoPeekCoreChecks/main.swift` - zero-dependency check pattern. [VERIFIED: codebase grep]
- `designs/lingobar-hub/data.jsx` - prototype collection/history adapter shape. [VERIFIED: local design file]

## RESEARCH COMPLETE
