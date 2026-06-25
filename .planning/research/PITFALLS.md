# Project Research: Pitfalls

## Pitfall: Recreating Settings Logic Instead Of Reusing It

- **Warning signs:** New UserDefaults keys, duplicate provider/model/token state, or settings controls that do not update the floating Lingobar after changes.
- **Prevention:** Keep `AppSettings` as the only app-side settings persistence facade and keep `LingobarSettingsSnapshot` as the Hub settings state.
- **Phase:** Settings migration phase.

## Pitfall: Treating History As Demo UI

- **Warning signs:** History list is hard-coded, not updated after actions, or stores AI output with secrets/configuration payloads.
- **Prevention:** Add a bounded local `LingobarHistoryStore` and append compact user-visible action records only.
- **Phase:** History persistence phase.

## Pitfall: Breaking Floating Lingobar Setup Flow

- **Warning signs:** Incomplete setup opens an old settings window, opens the wrong Hub section, or no longer guides users to AI/accessibility configuration.
- **Prevention:** Replace all settings callbacks consistently and preserve `SetupGateStatus` checks.
- **Phase:** Hub integration phase.

## Pitfall: Pixel Chasing At The Expense Of Native Behavior

- **Warning signs:** Web embedding, custom fake controls that do not focus correctly, broken keyboard close behavior, or inaccessible controls.
- **Prevention:** Use SwiftUI/AppKit controls styled to match the prototype; prioritize native behavior as requested.
- **Phase:** Visual fidelity phase.

## Pitfall: Large Shared-File Diff

- **Warning signs:** Massive rewrites of `SettingsView.swift` or `LingobarController.swift` that mix visual implementation, persistence, and routing.
- **Prevention:** Add new Hub files and keep existing controllers changed only at integration points.
- **Phase:** All phases.

## Pitfall: Unverified Visual Drift

- **Warning signs:** Build passes but Hub dimensions, sidebar width, card spacing, and detail pane proportions do not match the reference.
- **Prevention:** Add a deterministic Hub snapshot path and compare against `.omx/state/lingobar-hub/reference-full.png`.
- **Phase:** Verification and polish phase.
