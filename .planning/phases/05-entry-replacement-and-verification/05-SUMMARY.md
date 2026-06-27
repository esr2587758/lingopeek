# Phase 5 Summary - Entry Replacement And Verification

**Status:** Complete
**Completed:** 2026-06-28

## Delivered

- `LINGOPEEK_OPEN_SETTINGS=1` now opens Hub settings.
- `LINGOPEEK_OPEN_HUB=1` opens the Hub deterministically.
- `LINGOPEEK_OPEN_HUB_SECTION` can open collection/history/settings directly.
- Menu settings opens Hub settings.
- Menu now includes `Open Lingobar Hub`.
- Floating gear/setup settings callback opens Hub settings.
- Hub detail relaunch opens the floating Lingobar with stored text.
- Core checks now guard the Hub dimensions, labels, real store wiring, entry routes, and deterministic launch variables.

## Changed Files

- `Sources/LingoPeekApp/AppDelegate.swift`
- `Sources/LingoPeekApp/LingobarController.swift`
- `Sources/LingoPeekCoreChecks/main.swift`

