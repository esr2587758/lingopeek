# Phase 2 Summary - Native Hub Shell

**Status:** Complete
**Completed:** 2026-06-28

## Delivered

- Added a native `LingobarHubWindowController` for the Hub main window.
- Added a SwiftUI `LingobarHubView` matching the reference shell proportions: 920x624 window, 188pt sidebar, 320pt detail column, grouped navigation, dark glass tokens, chips, cards, dividers, and status footer.
- Wired top-level navigation for `收藏`, `历史`, and `设置` in one native window.
- Added deterministic launch routing through `LINGOPEEK_OPEN_HUB` and `LINGOPEEK_OPEN_HUB_SECTION`.
- Used real `PhraseStore`, `LingobarHistoryStore`, and `LingobarHubLibrary` data for counts and list cards rather than demo fixtures.

## Notes

This implementation intentionally went beyond the shell-only phase boundary and also completed the library workflows, settings migration, and entry replacement that later phases requested. Those are documented separately in Phases 3-5.

## Changed Files

- `Sources/LingoPeekApp/LingobarHubWindowController.swift`
- `Sources/LingoPeekApp/LingobarHubView.swift`
- `Sources/LingoPeekApp/AppDelegate.swift`
- `Sources/LingoPeekApp/LingobarController.swift`
- `Sources/LingoPeekCoreChecks/main.swift`

