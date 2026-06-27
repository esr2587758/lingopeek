---
phase: 02-native-hub-shell
status: complete
created: 2026-06-27T16:40:00Z
completed: 2026-06-28T00:00:00Z
mode: mvp
---

# Phase 2 Plan - Native Hub Shell

## Goal

Create the native Hub window and main visual structure matching the local HTML reference.

## User Story

As a Lingobar user, I want to open a native Hub shell with `收藏`, `历史`, and `设置` navigation, so that I can manage language material from one coherent macOS window before the detailed workflows are filled in.

## Tasks

### Task 1 - Add native Hub window controller

Files:
- `Sources/LingoPeekApp/LingobarHubWindowController.swift`
- `Sources/LingoPeekApp/AppDelegate.swift`
- `Sources/LingoPeekApp/LingobarController.swift`

Work:
- Add a 920x624 borderless `NSWindow` controller with Escape and Command-W close.
- Add drag-region handling for sidebar/header safe areas.
- Add observable Hub state with selected section.
- Add deterministic environment launch path for Hub visual checks.

Acceptance:
- Hub can open directly to collection/history/settings through controller API.
- `LINGOPEEK_OPEN_HUB=1` opens the Hub in regular activation mode.

### Task 2 - Add SwiftUI Hub shell

Files:
- `Sources/LingoPeekApp/LingobarHubView.swift`

Work:
- Port visual tokens and major layout proportions from the HTML reference.
- Add sidebar grouped nav with `收藏`, `历史`, `设置`, counts, and setup footer.
- Add collection/history shell panes with header, search field, chips, list, and 320pt detail column.
- Add settings shell pane with settings subnav placeholders.
- Load real collection/history data for counts and shell cards.

Acceptance:
- Native view matches the reference at major geometry/token/navigation level.
- Navigation switches sections in-place.
- Empty states and first-run states are polished.

### Task 3 - Add verification gates

Files:
- `Sources/LingoPeekCoreChecks/main.swift`

Work:
- Add source assertions for Hub controller, view, window dimensions, sidebar/detail widths, nav labels, deterministic launch route, and entry wiring placeholders.
- Keep existing checks green.

Acceptance:
- `swift build --product LingoPeek` passes.
- `swift run LingoPeekCoreChecks` passes.

## Risks

- Visual drift if the SwiftUI shell diverges from the reference token values.
- Old settings entry points can create duplicate management windows if routing is not handled carefully in later phases.
- Phase 2 should not overfit placeholder workflows that Phase 3/4 will replace.

## Verification

- Build: `swift build --product LingoPeek`
- Core checks: `swift run LingoPeekCoreChecks`
- Manual/native UI: launch with `LINGOPEEK_OPEN_HUB=1` through a temporary `.app` wrapper and inspect the native `Lingobar Hub` window.

## Completion Notes

- Implemented `LingobarHubWindowController` with a 920x624 borderless AppKit window, Escape close, Command-W close, regular activation launch path, and SwiftUI hosting.
- Implemented `LingobarHubView` with the 188pt sidebar, `收藏` / `历史` / `设置` navigation, dark glass tokens, 320pt detail column, real counts, list shells, settings shell, and ready footer.
- Added `LINGOPEEK_OPEN_HUB` and `LINGOPEEK_OPEN_HUB_SECTION` for deterministic launch.
- Added source-gate checks in `LingoPeekCoreChecks` to lock the native Hub shell dimensions, labels, real stores, and entry wiring.
