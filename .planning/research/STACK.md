# Project Research: Stack

**Scope:** Native Lingobar Hub main window for the existing LingoPeek SwiftPM macOS app.

## Recommended Stack

### UI Runtime

- **SwiftUI in `Sources/LingoPeekApp/`** for the Hub layout, settings controls, cards, lists, detail pane, chips, toast, and snapshotable view composition.
- **AppKit `NSWindow` / custom borderless window controller** for the 920x624 Hub shell, drag regions, keyboard close handling, activation, and menu-bar entry integration.
- **Existing `LingobarCore` models** for language actions, settings descriptors, collection target, appearance schemes, setup-gate status, and saved phrases.

### Persistence

- **Existing `PhraseStore`** remains the collection persistence mechanism.
- **New Foundation-only history store** should mirror the `PhraseStore` shape: Codable records, JSON in Application Support, atomic writes, bounded load/save API, no AppKit dependency.
- **Existing `AppSettings` / `UserDefaults` / `LocalTokenStore`** remain the settings persistence boundary.

### Verification

- **`swift build --product LingoPeek`** proves the app target compiles.
- **`swift run LingoPeekCoreChecks`** should cover new Foundation data behavior, history persistence, settings contract regressions, and any model transformations.
- **A Hub snapshot renderer or deterministic environment mode** should be added if practical, modeled after `SettingsSnapshotRenderer`, to compare visual output against `.omx/state/lingobar-hub/reference-full.png`.

## What Not To Use

- `WKWebView` embedding of `Lingobar Hub.html`: rejected because the user asked for native SwiftUI fidelity, and the existing app depends on native focus, window, settings, and persistence behavior.
- Third-party UI packages: rejected because the repo currently has no external Swift dependencies and the design can be implemented with SwiftUI/AppKit.
- A separate web clone output: rejected because the target is the native app, not a shipped website.

## Confidence

High. The existing app already has the right SwiftUI/AppKit patterns, settings persistence, and phrase persistence primitives for this feature.
