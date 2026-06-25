# Project State: LingoPeek Native Lingobar Hub

**Initialized:** 2026-06-26
**Status:** Ready to execute Phase 1

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-26)

**Core value:** Users can manage saved language material, revisit previous language actions, and change Lingobar settings in one native window without breaking the selection-first Lingobar workflow.
**Current focus:** Execute Phase 1: Hub Data Foundations

## Workflow Settings

- Mode: YOLO
- Granularity: Standard
- Execution: Parallel
- Git Tracking: Yes
- Research: Yes
- Plan Check: Yes
- Verifier: Yes
- Drift Guard: Yes
- AI Models: Inherit
- Project mode: Vertical MVP

## Current Roadmap

| Phase | Status | Progress |
|-------|--------|----------|
| 1. Hub Data Foundations | Planned | 100% planning |
| 2. Native Hub Shell | Pending | 0% |
| 3. Library Workflows | Pending | 0% |
| 4. Settings In Hub | Pending | 0% |
| 5. Entry Replacement And Verification | Pending | 0% |

## Decisions Captured

- Replace settings entry points with the Hub.
- Use real collection and real history data.
- Prioritize native behavior while staying visually faithful to the prototype.
- Avoid new dependencies.
- Treat local design files and captured screenshot as reference artifacts.

## Verification Baseline

Required after implementation phases:

- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- Hub visual comparison against `.omx/state/lingobar-hub/reference-full.png`

---
*Last updated: 2026-06-26 after Phase 1 planning*
