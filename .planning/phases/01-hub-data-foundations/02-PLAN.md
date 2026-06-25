---
phase: 01-hub-data-foundations
plan: 2
type: execute
wave: 2
depends_on: ["01"]
files_modified:
  - Sources/LingoPeekApp/LingobarViewModel.swift
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
    - "HIST-01: Successful non-stale AI language actions append compact history records through the Plan 01 `LingobarHistoryStore`."
    - "HIST-01: Setup failures, fixture presentation, copy/collect actions, stale completions, decode errors, and provider/network errors do not append history."
    - "HIST-01: Input-mode history uses submitted input text and the source label `输入模式`."
    - "HIST-01: Selection-mode history uses selected text and the current selection source label."
    - "CoreChecks include a source assertion that fails if history recording moves into forbidden paths or before the successful-decode request guard."
    - "The final phase gate requires `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks`."
  artifacts:
    - "Updated Sources/LingoPeekApp/LingobarViewModel.swift with injected LingobarHistoryStore and successful-action recording"
    - "Updated Sources/LingoPeekCoreChecks/main.swift with `checkLingobarViewModelHistoryRecordingSourceGate()`"
    - "Plan 01 artifacts consumed but not modified here: LingobarHistoryStore.swift, LingobarHubLibrary.swift, LanguageAction.swift"
  key_links:
    - "Plan 01 `LingobarHistoryRecord.make` -> Plan 02 `LingobarViewModel.recordCompletedHistory`"
    - "Plan 01 `LingobarHistoryStore.append` -> successful decode branch in `runAIIfAvailable`"
    - "Successful-decode `activeAIRequestID` guard -> history recording call"
    - "CoreChecks source assertion -> forbidden path regression detection"
    - "swift build --product LingoPeek && swift run LingoPeekCoreChecks"
---

## Phase Goal

**As a** Lingobar user, **I want to** have saved phrases and completed language actions represented by real local data contracts, **so that** the Hub can later show collection and history without placeholder data.

<objective>
Wire the Plan 01 history contracts into the existing Lingobar action flow and prove the phase with final gates.

Purpose: Ensure completed language actions are recorded only from the correct successful path, while preserving Phase 1 as data-only work.
Output: `LingobarViewModel` history-store injection, success-path recording, a CoreChecks source gate for privacy/control-flow placement, and final build/check verification.
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
@.planning/phases/01-hub-data-foundations/01-SUMMARY.md
@.planning/phases/01-hub-data-foundations/01-RESEARCH.md
@.planning/phases/01-hub-data-foundations/01-PATTERNS.md
@.planning/phases/01-hub-data-foundations/01-VALIDATION.md
@Sources/LingoPeekApp/LingobarViewModel.swift
@Sources/LingoPeekCoreChecks/main.swift
@Package.swift
</context>

## Artifacts This Phase Produces

Plan 02 consumes these Plan 01 artifacts:
- `LanguageAction: Codable`
- `LingobarHistoryRecord`
- `LingobarHistoryRecord.make(action:sourceText:sourceAppName:result:createdAt:id:)`
- `LingobarHistoryStore`
- `LingobarHubLibraryItem`
- `LingobarHubLibrary.collectionItems(from:)`
- `LingobarHubLibrary.historyItems(from:)`

Plan 02 creates or changes:
- `Sources/LingoPeekApp/LingobarViewModel.swift`
- `Sources/LingoPeekCoreChecks/main.swift`

Changed symbols:
- `LingobarViewModel` gains injected `historyStore: LingobarHistoryStore`.
- `LingobarViewModel.init(store:historyStore:)` keeps the existing default `PhraseStore` behavior and adds a default history store.
- `LingobarViewModel.runAIIfAvailable(for:text:)` records only successful, current, non-stale language-action completions.
- `LingobarViewModel` gains a private recording helper, such as `recordCompletedHistory(action:sourceText:sourceAppName:)`.
- `Sources/LingoPeekCoreChecks/main.swift` gains `checkLingobarViewModelHistoryRecordingSourceGate()`.

Unchanged artifacts:
- Plan 02 does not modify `Sources/LingobarCore/LingobarHistoryStore.swift`, `Sources/LingobarCore/LingobarHubLibrary.swift`, or `Sources/LingobarCore/LanguageAction.swift` unless Plan 01 execution left a compile failure that must be fixed before this plan can proceed.
- `Package.swift` remains unchanged.
- No Hub UI, window, design, UI-SPEC, SKELETON.md, database, WebView, or package-dependency work is part of this plan.

## Dependency Graph

| Task | Needs | Creates | Notes |
|------|-------|---------|-------|
| 1-02-01 | Plan 01 summary and core history symbols | ViewModel history recording plus source gate | Wave 2 because it consumes Plan 01 artifacts. |
| 1-02-02 | Task 1 and all Plan 01 outputs | Final build/check/privacy evidence | No source edits unless verification exposes a regression introduced in this phase. |

<tasks>

<task id="1-02-01" type="auto" tdd="true">
  <name>Task 1: Record successful non-stale Lingobar language actions</name>
  <files>Sources/LingoPeekApp/LingobarViewModel.swift, Sources/LingoPeekCoreChecks/main.swift</files>
  <read_first>
    @.planning/phases/01-hub-data-foundations/01-SUMMARY.md
    @Sources/LingoPeekApp/LingobarViewModel.swift
    @Sources/LingoPeekCoreChecks/main.swift
    @Sources/LingobarCore/LingobarHistoryStore.swift
    @Sources/LingobarCore/LingobarHubLibrary.swift
    @.planning/phases/01-hub-data-foundations/01-RESEARCH.md
    @.planning/phases/01-hub-data-foundations/01-VALIDATION.md
  </read_first>
  <behavior>
    - Completed AI language actions append one compact history record after successful decode and after the existing successful-decode `activeAIRequestID` stale-response guard.
    - Selection-mode records use the selected text and current `selectionSource`.
    - Input-mode records use submitted `inputText` as source text and `"输入模式"` as the source app label.
    - History write failures do not replace successful AI output or change user-facing result status away from `"AI 完成"`.
    - Setup failures, unavailable grammar actions, stale responses, decode errors, network/provider errors, `.copy`, `.collect`, and `presentGrammarFixture` do not append history.
    - `checkLingobarViewModelHistoryRecordingSourceGate()` fails if the recording helper or store append call appears in setup-gate, fixture, copy/collect, catch/error, or pre-guard regions.
  </behavior>
  <action>Update `LingobarViewModel` with `private let historyStore: LingobarHistoryStore` and change the initializer to `init(store: PhraseStore = .defaultStore(), historyStore: LingobarHistoryStore = .defaultStore())`. In `runAIIfAvailable(for:text:)`, capture `historySourceText = text` and `historySourceAppName = mode == .input ? "输入模式" : selectionSource` before starting the async `Task`. After the successful decode branch sets `self.result` and `self.grammarResult`, and only after the successful-decode `guard self.activeAIRequestID == requestID else { return }`, call a private helper such as `recordCompletedHistory(action:sourceText:sourceAppName:)`. The helper calls the Plan 01 history-record builder and then persists through the injected history store with non-fatal error handling. Add `checkLingobarViewModelHistoryRecordingSourceGate()` to `Sources/LingoPeekCoreChecks/main.swift`; it should read `Sources/LingoPeekApp/LingobarViewModel.swift`, region-slice the setup gate, `presentGrammarFixture`, copy/collect functions, both catch branches, the pre-success-guard part of `runAIIfAvailable`, and the helper body, then assert that history recording appears only in the successful branch after the guard and that the store append appears only inside the helper. Call this check in the final `do` block. Do not pass provider configuration, tokens, model names, base URLs, prompts, raw completion text, raw JSON, or provider errors to history. Do not alter existing phrase save, result copy, setup gate, grammar fixture, or error-result behavior.</action>
  <acceptance_criteria>
    - Existing `LingobarViewModel()` construction still works without caller changes.
    - The ViewModel stores an injected `LingobarHistoryStore` and uses it only through the private recording helper.
    - The source gate fails if history recording appears in setup, fixture, copy/collect, catch/error paths, or before the successful-decode request guard.
    - `historySourceAppName` is captured as `"输入模式"` for input mode instead of reusing stale `selectionSource`.
    - `presentGrammarFixture(sourceAppName:)` does not call history recording.
    - `swift build --product LingoPeek` succeeds with the added injected dependency.
  </acceptance_criteria>
  <verify>
    <automated>swift build --product LingoPeek</automated>
    <automated>swift run LingoPeekCoreChecks</automated>
    <automated>rg -n 'checkLingobarViewModelHistoryRecordingSourceGate|recordCompletedHistory|historyStore|activeAIRequestID == requestID|输入模式' Sources/LingoPeekApp/LingobarViewModel.swift Sources/LingoPeekCoreChecks/main.swift</automated>
  </verify>
  <done>HIST-01 completed-action recording is integrated into the existing Lingobar flow without recording stale or failed AI work and without exposing provider secrets.</done>
</task>

<task id="1-02-02" type="auto">
  <name>Task 2: Run final Phase 1 verification and scope gates</name>
  <files>Sources/LingoPeekApp/LingobarViewModel.swift, Sources/LingoPeekCoreChecks/main.swift</files>
  <read_first>
    @AGENTS.md
    @.planning/phases/01-hub-data-foundations/01-SUMMARY.md
    @.planning/phases/01-hub-data-foundations/01-VALIDATION.md
    @Sources/LingoPeekApp/LingobarViewModel.swift
    @Sources/LingoPeekCoreChecks/main.swift
    @Package.swift
  </read_first>
  <action>Run the full Phase 1 gate and fix only issues introduced by Plan 01 or Task 1 of this plan. Confirm `Package.swift` remains unchanged because new files under existing targets need no SwiftPM manifest update. Confirm no UI files or design files were modified. Confirm CoreChecks include encoded sentinel privacy assertions from Plan 01 and the ViewModel source-placement assertion from Task 1. Do not commit.</action>
  <acceptance_criteria>
    - `swift build --product LingoPeek` passes.
    - `swift run LingoPeekCoreChecks` passes.
    - `Package.swift` has no diff from the pre-phase state.
    - Only Plan 01 files plus `Sources/LingoPeekApp/LingobarViewModel.swift` and `Sources/LingoPeekCoreChecks/main.swift` are changed or created by implementation.
    - No Hub UI/AppKit window/view files are created in Phase 1.
    - CoreChecks fail on misplaced history recording and pass only when recording stays after the successful-decode request guard.
  </acceptance_criteria>
  <verify>
    <automated>swift build --product LingoPeek</automated>
    <automated>swift run LingoPeekCoreChecks</automated>
    <automated>git diff --exit-code -- Package.swift</automated>
    <automated>! git diff --name-only -- Sources designs Package.swift | rg 'LingobarHubView|LingobarHubWindow|SettingsView|LingobarRootView|designs/'</automated>
    <automated>! git ls-files --others --exclude-standard -- Sources | rg 'LingobarHubView|LingobarHubWindow|SettingsView|LingobarRootView'</automated>
  </verify>
  <done>The phase is ready for `$gsd-verify-work`: all automated checks pass, source/privacy assertions pass, no forbidden UI/dependency/schema work was introduced, and no commit was made.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| AI completion -> app view model | Untrusted provider text is decoded into typed results before history is built. |
| App workflow -> local history JSON | User text and final AI output cross into persistent local storage through Plan 01 store APIs. |
| User action sequence -> async completion | Later actions can supersede earlier AI requests before async completions return. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-01-05 | Tampering | `LingobarViewModel.runAIIfAvailable` | high | mitigate | Append history only in the successful decode path after the existing `activeAIRequestID == requestID` guard; CoreChecks read the source and fail if recording moves into pre-guard, setup, fixture, copy/collect, or catch/error regions. |
| T-01-06 | Information Disclosure | History recording helper | high | mitigate | Pass only action, source text, source app label, and final `LingobarResult` into the Plan 01 builder; do not pass provider settings, request configuration, prompts, raw responses, or errors. |
| T-01-07 | Information Disclosure | Input-mode source metadata | medium | mitigate | Capture input-mode history source label as `"输入模式"` rather than reusing stale `selectionSource` from a prior selection. |
| T-01-08 | Denial of Service | History write failure during AI success | low | mitigate | Keep history append non-fatal so persistence errors do not replace successful AI output or trap the UI flow. |
</threat_model>

## Plan Set Source Audit

| Source | ID | Feature / Requirement | Plan Task | Status | Notes |
|--------|----|-----------------------|-----------|--------|-------|
| GOAL | Phase 1 | Give the Hub real local data contracts before building the full visual surface. | 1-01-01 through 1-02-02 | COVERED | Plan 01 builds contracts/store; Plan 02 wires recording and verifies final scope. |
| REQ | HIST-01 | Lingobar records completed language actions into a local bounded history store. | 1-01-01, 1-01-02, 1-01-03, 1-02-01 | COVERED | Store plus ViewModel success-path recording. |
| REQ | COLL-01 | User can view locally saved phrases from `PhraseStore` in the Hub collection list. | 1-01-01, 1-01-02, 1-02-02 | COVERED | Adapter remains owned by Plan 01 and verified in final checks. |
| REQ | COLL-05 | User can copy a collection item from card/detail later. | 1-01-01, 1-01-02, 1-02-02 | COVERED | `copyText == SavedPhrase.title` remains in CoreChecks. |
| REQ | HIST-02 | User can view recent history with action badges, item type, source, and relative time inputs. | 1-01-01, 1-01-02, 1-02-02 | COVERED | Records expose fields; rendering is outside Phase 1. |
| REQ | HIST-06 | User can copy, delete, and clear history records. | 1-01-01, 1-01-03, 1-02-02 | COVERED | Store methods and final checks cover copy/delete/clear contracts. |
| RESEARCH | R-03 | Record only after non-stale successful AI decode in `LingobarViewModel.runAIIfAvailable`. | 1-02-01 | COVERED | Source gate verifies placement against the successful-decode request guard. |
| RESEARCH | R-04 | Keep history compact and exclude secrets/raw provider payloads. | 1-02-01, 1-02-02 | COVERED | ViewModel passes only safe inputs to Plan 01 builder; CoreChecks enforce placement and encoded privacy assertions. |
| RESEARCH | R-07 | Do not run AI probes or require secrets for Phase 1 checks. | 1-02-02 | COVERED | Verification uses build and CoreChecks only. |
| CONTEXT | User revision | Keep Phase 1 data-only: no Hub UI/window/design work, no UI-SPEC requirement, no SKELETON.md. | 1-02-02 | COVERED | Final scope gate checks no UI/design files are modified. |

No source-audit gaps found.

<verification>
Plan 02 and phase checks:
- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- `git diff --exit-code -- Package.swift`
- Scope gate proves no Hub UI/window/design files were created or modified.
</verification>

<success_criteria>
1. Completed Lingobar language actions produce compact `LingobarHistoryRecord` values only after successful, current AI decode.
2. Setup, fixture, copy/collect, stale, decode-error, and provider-error paths do not persist history.
3. CoreChecks include a source-placement gate for `LingobarViewModel`.
4. `swift build --product LingoPeek` passes.
5. `swift run LingoPeekCoreChecks` passes.
</success_criteria>

<output>
Create `.planning/phases/01-hub-data-foundations/02-SUMMARY.md` when Plan 02 execution is done. Do not commit unless a later explicit instruction asks for a commit.
</output>
