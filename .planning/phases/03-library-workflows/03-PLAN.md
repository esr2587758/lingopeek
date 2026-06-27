---
phase: 03-library-workflows
status: complete
created: 2026-06-28T00:00:00Z
completed: 2026-06-28T00:00:00Z
mode: mvp
---

# Phase 3 Plan - Library Workflows

## Goal

Make collection and history usable with real search, filters, details, and item actions.

## Tasks

### Task 1 - Real list filtering

- Add query fields for collection/history.
- Add chip filters derived from real item types.
- Keep selection stable as filters change.

### Task 2 - Detail pane

- Show type, action, source, time, content, note, and original text.
- Keep a 320pt detail column with stable empty state.

### Task 3 - Item actions

- Copy item text to pasteboard.
- Delete collection/history items through their stores.
- Clear history through `LingobarHistoryStore.clear()`.
- Save history items to collection through `PhraseStore.save(_:)`.
- Relaunch Lingobar through `LingobarViewModel.reopenInlineSelection(_:)`.

## Verification

- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- Native Hub launch smoke with real local collection/history data.

