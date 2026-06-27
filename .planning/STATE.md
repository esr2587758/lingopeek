---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Phase 1 complete; ready to plan Phase 2
last_updated: "2026-06-27T16:28:02.209Z"
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 20
---

# Project State: LingoPeek Native Lingobar Hub

**Initialized:** 2026-06-26
**Status:** Ready to plan Phase 2

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-27)

**Core value:** Users can manage saved language material, revisit previous language actions, and change Lingobar settings in one native window without breaking the selection-first Lingobar workflow.
**Current focus:** Plan Phase 2: Native Hub Shell

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
| 1. Hub Data Foundations | Complete | 2/2 plans complete |
| 2. Native Hub Shell | Ready to plan | 0% |
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
*Last updated: 2026-06-27 after Phase 1 completion*

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 01-hub-data-foundations P01 | 372 | 3 tasks | 4 files |

## Decisions

- [Phase 01-hub-data-foundations]: Keep Phase 1 Plan 01 data-only: no Hub UI/window/design files and no Package.swift changes.
- [Phase 01-hub-data-foundations]: Keep collection metadata adapter-only; SavedPhrase and PhraseStore schema remain unchanged.
- [Phase 01-hub-data-foundations]: Persist history as compact user-visible Foundation JSON with bounded fields and no provider configuration inputs.

## Session

**Last session:** 2026-06-27T16:28:02.209Z
**Stopped at:** Phase 1 complete; ready to plan Phase 2
**Resume file:** None
