# Phase 3: Library Workflows - Context

**Gathered:** 2026-06-28
**Status:** Complete
**Mode:** Autonomous vertical slice

## Phase Boundary

Complete the collection and history workflows inside the native Hub:

- Search and chip filters.
- List cards backed by real collection/history adapters.
- Detail pane with metadata, source, time, text, note, and original source text.
- Copy, delete, clear history, save history item to collection, and relaunch actions.
- Stable empty and selected states.

## Existing Contracts

- `PhraseStore.defaultStore()` persists saved phrases.
- `LingobarHistoryStore.defaultStore()` persists history records and supports delete/clear.
- `LingobarHubLibrary.collectionItems(from:)` and `historyItems(from:)` convert domain storage into Hub display items.
- `LingobarViewModel.reopenInlineSelection(_:)` can relaunch Lingobar from stored text.

## Decisions

- Keep collection/history local-only and dependency-free.
- Do destructive local actions through existing stores only; no schema changes.
- Use toast feedback for action confirmation.
- Keep relaunch behavior conservative: use `sourceText`, then `copyText`, then visible/title text.

