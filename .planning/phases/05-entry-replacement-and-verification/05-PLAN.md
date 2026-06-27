---
phase: 05-entry-replacement-and-verification
status: complete
created: 2026-06-28T00:00:00Z
completed: 2026-06-28T00:00:00Z
mode: mvp
---

# Phase 5 Plan - Entry Replacement And Verification

## Goal

Make the Hub the shipped management window and prove it works.

## Tasks

### Task 1 - Entry replacement

- Route menu settings to Hub settings.
- Route floating/setup gear actions to Hub settings.
- Add a menu item for opening the Hub collection section.
- Preserve `LINGOPEEK_OPEN_SETTINGS=1` compatibility by opening Hub settings.

### Task 2 - Deterministic launch

- Add `LINGOPEEK_OPEN_HUB`.
- Add `LINGOPEEK_OPEN_HUB_SECTION`.
- Use regular activation when Hub is opened on launch.

### Task 3 - Verification

- Add source gates to `LingoPeekCoreChecks`.
- Build and run checks.
- Launch native app and inspect Hub window.

## Verification

- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- Native Hub visual smoke through temporary `.app` wrapper.

