# Phase 5: Entry Replacement And Verification - Context

**Gathered:** 2026-06-28
**Status:** Complete
**Mode:** Autonomous vertical slice

## Phase Boundary

Make the Hub the shipped management window and prove it works:

- Normal settings entry points open Hub settings.
- A menu entry opens Hub collection.
- Deterministic launch route supports UI smoke testing.
- Build and core checks pass.
- Visual smoke compares the native Hub against the captured reference.

## Existing Entry Points

- AppDelegate launch environment.
- Menu bar settings item in `LingobarController`.
- Floating Lingobar gear/setup settings callback through `LingobarRootView(onOpenSettings:)`.

## Decisions

- Keep `LINGOPEEK_OPEN_SETTINGS=1` compatible by mapping it to Hub settings.
- Add `LINGOPEEK_OPEN_HUB=1` and `LINGOPEEK_OPEN_HUB_SECTION`.
- Keep the old settings source unused but present for a future cleanup phase.

