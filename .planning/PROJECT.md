# LingoPeek Native Lingobar Hub

## What This Is

LingoPeek is an existing native macOS Swift package for Lingobar, a selection-first language bar for English reading, writing, and remembering. This project adds a native Lingobar Hub main window that matches `designs/lingobar-hub/Lingobar Hub.html`, with left navigation for `收藏`, `历史`, and `设置`.

The Hub replaces the current standalone settings entry points: menu bar settings, floating Lingobar gear actions, and setup-gate settings actions should open the Hub. The first version prioritizes native macOS behavior and real local data wiring while preserving the reference design's dark glass layout, spacing, and interaction feel.

## Core Value

Users can manage saved language material, revisit previous language actions, and change Lingobar settings in one native window without breaking the selection-first Lingobar workflow.

## Requirements

### Validated

- ✓ Native macOS SwiftPM app shell exists with AppKit lifecycle, menu bar item, floating panel, custom borderless windows, and SwiftUI-hosted views — existing
- ✓ Lingobar already supports selection-first language actions, setup gating, hotkey invocation, AI result rendering, copy, and collection actions — existing
- ✓ Settings are persisted through `AppSettings` and `LingobarSettingsSnapshot`, including AI provider, API token, base URL, model, permissions, trigger behavior, action order, default actions, collection target, clipboard behavior, and hotkey — existing
- ✓ Saved phrases persist locally through `PhraseStore.defaultStore()` under Application Support — existing
- ✓ The codebase has zero-dependency verification targets with `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks` — existing
- ✓ Reference Hub design exists locally under `designs/lingobar-hub/` and has been captured as `.omx/state/lingobar-hub/reference-full.png` for visual comparison — existing

### Active

- [ ] Add a native `LingobarHub` window matching the HTML reference's 920x624 dark glass shell, 188pt sidebar, two-column content region, typography, colors, dividers, cards, chips, detail drawer, settings subnav, and toast behavior.
- [ ] Replace existing settings entry points so the menu bar settings item, floating Lingobar gear, and setup-gate AI settings action open the Hub instead of the old standalone settings window.
- [ ] Wire `收藏` to real saved phrase data from `PhraseStore`, preserving copy, delete, detail, and relaunch affordances in a native SwiftUI surface.
- [ ] Add real local history persistence for language actions so `历史` shows recent translation, grammar, rewrite, examples, and pronunciation records rather than demo-only data.
- [ ] Port settings behavior into the Hub with native controls that read and write the existing `AppSettings` contract.
- [ ] Preserve native macOS behavior: keyboard close, command shortcuts where appropriate, draggable borderless window headers, focus handling, UserDefaults persistence, and no new runtime dependencies.
- [ ] Add focused verification for Hub data models, persistence, settings wiring, and snapshot/rendering checks where practical.

### Out of Scope

- Cloud sync for collection or history — this milestone is local-only and should not introduce accounts or backend services.
- General AI chat, productivity launcher, or agent workspace behavior — Lingobar remains focused on English reading, writing, and memory.
- Microphone or speech-recognition permissions — voice input remains outside the MVP.
- Direct insertion or replacement in source apps from the Hub — copy/relaunch remain the first version's write-back path.
- Rebuilding the floating Lingobar result panel — this milestone integrates with it but does not redesign it.
- Multi-page web clone output — the HTML prototype is a visual source of truth, not a shipped web artifact.

## Context

The repo is a brownfield native macOS app. The current implementation has a separate `SettingsWindowController` and `SettingsView`, while the target UI is a broader Hub that combines collection, history, and settings in one main window. `LingobarController` owns menu bar items, panel gear callbacks, setup-gate callbacks, window positioning, hotkey registration, and settings-change observation, so Hub integration should be made there or through an adjacent controller.

The design source is local and concrete:

- `designs/lingobar-hub/Lingobar Hub.html`
- `designs/lingobar-hub/app.jsx`
- `designs/lingobar-hub/cards.jsx`
- `designs/lingobar-hub/data.jsx`
- `designs/lingobar-hub/icons.jsx`
- `.omx/state/lingobar-hub/reference-full.png`
- `.omx/state/lingobar-hub/reference-metrics.json`

The reference page uses a dark glass window over a wallpaper stage for preview. The shipped native window should reproduce the Hub window itself, not necessarily the demo menubar or wallpaper stage unless needed for snapshot testing.

## Constraints

- **Tech stack**: Use Swift, SwiftUI, AppKit, Foundation, and existing targets only — the repo has no third-party Swift dependencies and should stay dependency-free.
- **Design fidelity**: Match the reference design's major dimensions and visual tokens: accent `#6E8BFF`, accent text `#AAB6FF`, window radius 16, sidebar width 188, Hub size 920x624, hairline opacity 0.09, chip opacity 0.06, and two-column `1fr + 320` layout.
- **Native behavior**: Favor real AppKit/SwiftUI window, focus, keyboard, persistence, and controls over web embedding.
- **Data integrity**: Collection uses existing `PhraseStore`; history persistence must be additive and local, with bounded storage and no AI secrets in history records.
- **Compatibility**: Preserve existing floating Lingobar behavior, setup gate behavior, and settings persistence keys.
- **Verification**: Build with `swift build --product LingoPeek` and run `swift run LingoPeekCoreChecks`; add or update check coverage when persistence or settings contracts change.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Replace settings entry points with the Hub | The user chose `Entry 1`; the Hub is the new main management window and contains settings. | — Pending |
| Wire both collection and history to real local data | The user chose `Data 3`; demo-only history is insufficient for the native Hub milestone. | — Pending |
| Prioritize native behavior over exact web mechanics | The user chose `Fidelity 2`; SwiftUI/AppKit fidelity and real settings/data behavior take precedence over cloning DOM interactions. | — Pending |
| Keep implementation dependency-free | Existing package has no third-party dependencies and AGENTS.md asks to avoid new dependencies without explicit request. | — Pending |
| Use local design artifacts as the source of truth | The target is a local prototype, so research and verification should compare against checked-out design files and captured screenshots. | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-26 after initialization*
