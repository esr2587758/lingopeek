# Roadmap: LingoPeek Native Lingobar Hub

**Created:** 2026-06-26
**Mode:** Vertical MVP
**Granularity:** Standard

## Overview

This roadmap adds the native Hub as a brownfield vertical slice: real persistence first, native shell second, then collection/history workflows, settings migration, and final integration/verification polish.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 1 | Hub Data Foundations | Add real local history persistence and collection adapters needed by the Hub. | HIST-01, COLL-01, COLL-05, HIST-02, HIST-06 |
| 2 | Native Hub Shell | Build the 920x624 native Hub window, sidebar, core layout, status footer, and visual tokens. | HUB-01, HUB-02, HUB-03, HUB-04, FID-01, FID-02 |
| 3 | Library Workflows | Complete collection/history search, filters, detail pane, delete, save-to-collection, and relaunch behavior. | COLL-02, COLL-03, COLL-04, COLL-06, COLL-07, HIST-03, HIST-04, HIST-05, HIST-07, HIST-08 |
| 4 | Settings In Hub | Port real settings behavior into the Hub with native controls and existing `AppSettings` persistence. | SET-01, SET-02, SET-03, SET-04, SET-05, SET-06, SET-07 |
| 5 | Entry Replacement And Verification | Replace old settings entry points, add render/check coverage, polish fidelity, and verify the product. | HUB-05, FID-03, FID-04, FID-05 |

## Phases

### Phase 1: Hub Data Foundations
**Goal:** Give the Hub real local data contracts before building the full visual surface.
**Mode:** mvp

**Requirements:** HIST-01, COLL-01, COLL-05, HIST-02, HIST-06

**Success Criteria**:
1. History records can be appended, loaded, deleted, cleared, and capped through a Foundation-only store.
2. Completed Lingobar language actions produce compact history records without storing API tokens or provider secrets.
3. Existing saved phrases can be adapted into Hub collection items with copy-ready text and metadata.
4. Core checks cover history persistence and collection/history transformations.

**UI hint:** no

### Phase 2: Native Hub Shell
**Goal:** Create the native Hub window and main visual structure matching the local HTML reference.
**Mode:** mvp

**Requirements:** HUB-01, HUB-02, HUB-03, HUB-04, FID-01, FID-02

**Success Criteria**:
1. A 920x624 borderless native Hub window renders a dark glass shell with 188pt sidebar and main content region.
2. Sidebar navigation switches between `收藏`, `历史`, and `设置` without separate windows.
3. Setup readiness footer reflects current setup state.
4. Escape/Command-W close the Hub and configured drag regions move the window.
5. Visual tokens and major layout proportions match `designs/lingobar-hub/Lingobar Hub.html`.

**UI hint:** yes

### Phase 3: Library Workflows
**Goal:** Make collection and history usable with real search, filters, details, and item actions.
**Mode:** mvp

**Requirements:** COLL-02, COLL-03, COLL-04, COLL-06, COLL-07, HIST-03, HIST-04, HIST-05, HIST-07, HIST-08

**Success Criteria**:
1. Collection and history lists support search and chip filters.
2. Selecting an item opens a detail pane with type/action metadata, source, time, notes, and primary text.
3. Copy, delete, clear history, save-to-collection, and relaunch actions update state and show toast feedback.
4. Empty and selected states match the reference layout without layout jumps.

**UI hint:** yes

### Phase 4: Settings In Hub
**Goal:** Move settings behavior into the Hub while preserving existing persistence and notifications.
**Mode:** mvp

**Requirements:** SET-01, SET-02, SET-03, SET-04, SET-05, SET-06, SET-07

**Success Criteria**:
1. Hub settings subnav exposes all existing settings sections.
2. Every settings control writes through existing `AppSettings.save...` APIs.
3. AI token/base URL/model/provider behavior preserves current environment/local precedence.
4. Hotkey, action ordering, defaults, and collection behavior update floating Lingobar behavior through existing notifications.
5. The old settings view is either retired or clearly no longer used by normal entry points.

**UI hint:** yes

### Phase 5: Entry Replacement And Verification
**Goal:** Make the Hub the shipped management window and prove it works.
**Mode:** mvp

**Requirements:** HUB-05, FID-03, FID-04, FID-05

**Success Criteria**:
1. Menu bar settings, floating gear, and setup-gate settings actions open the Hub settings section.
2. Automated checks cover new persistence and transformation behavior.
3. A deterministic Hub rendering or screenshot workflow exists for visual comparison with the captured reference.
4. `swift build --product LingoPeek` passes.
5. `swift run LingoPeekCoreChecks` passes.

**UI hint:** yes

## Risks

- Settings migration can regress setup flow if not routed through a single Hub controller.
- Real history persistence can accidentally store too much AI result or provider context; keep records compact and user-visible.
- Visual fidelity can drift if snapshot verification is deferred too late.
- Existing untracked design prototype directories should remain out of implementation commits unless intentionally added.

## Next Step

Run `$gsd-plan-phase 1` to plan the Hub Data Foundations phase.

---
*Roadmap created: 2026-06-26*
