# Phase 2: Native Hub Shell - Context

**Gathered:** 2026-06-27
**Status:** Ready for planning
**Mode:** Smart discuss recommendations auto-accepted by autonomous workflow

<domain>
## Phase Boundary

Create the native Lingobar Hub shell: a 920x624 borderless AppKit window hosting SwiftUI, visually matching `designs/lingobar-hub/Lingobar Hub.html` at the major-layout level. This phase owns the window, sidebar navigation, shell tokens, setup footer, keyboard close behavior, drag regions, and section switching between `收藏`, `历史`, and `设置`.

Phase 2 may show lightweight real counts and shell-level placeholders/previews, but complete collection/history workflows are Phase 3, settings behavior migration is Phase 4, and full entry replacement/visual verification hardening is Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Window and Entry Shape
- Add a new `LingobarHubWindowController` adjacent to `SettingsWindowController`, using a borderless 920x624 `NSWindow` with clear background, 16pt radius, shadow, Escape close, Command-W close, and explicit drag hit regions.
- Keep the old settings window source available for compatibility during this phase, but build the Hub as a real native app window rather than a web view.
- Add a UI-test launch affordance through environment, so the Hub can be opened deterministically for render/screenshot checks without relying on menu-bar clicks.
- Use a shared observable Hub state so the controller can open directly to `收藏`, `历史`, or `设置`.

### Navigation and Layout
- Match the reference's 188pt sidebar, grouped nav labels (`我的内容`, `应用`), brand header, nav counts, and setup footer.
- Main content uses the reference shell proportions: header, toolbar/chips when applicable, and a two-column `1fr + 320pt` library layout.
- Sidebar navigation must switch sections in-place without opening separate windows or nesting old settings chrome.
- Phase 2 shell should keep layout dimensions stable: fixed window size, fixed sidebar, fixed detail width, stable button/icon sizes.

### Visual Fidelity
- Port the major design tokens from the reference: accent `#6E8BFF`, accent text `#AAB6FF`, radius 16, hairline opacity 0.09, chip opacity 0.06, chip hover opacity 0.11, ok `#4FD0A0`, warn `#E0915C`.
- Use native SF Symbols for icons and SwiftUI controls. No `WKWebView`, no third-party dependencies.
- Keep text scale compact and tool-like, matching the operational Hub rather than a marketing page.
- Preserve dark glass tone without decorative gradient/orb motifs beyond subtle window surface depth.

### Data Surface in Shell
- Use Phase 1's `PhraseStore`, `LingobarHistoryStore`, and `LingobarHubLibrary` adapters to populate counts and initial cards where safe.
- For Phase 2, deletion, search filtering, save-to-collection, clear history, relaunch, and settings writes may be stubbed or minimal unless needed for shell validation. They become hard requirements in later phases.
- Empty states should be present and stable so first-run users see a polished shell.

### Verification
- Add source/build checks that prove the native Hub shell exists, uses the intended size/sidebar/detail constants, contains the three Chinese navigation labels, and is reachable through a deterministic launch path.
- Continue to run `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks`.
- Prefer a deterministic screenshot/render path for later visual comparison; Phase 2 should leave hooks that Phase 5 can harden.

### the agent's Discretion
- Minor wording, spacing, and private helper factoring can follow existing SwiftUI/AppKit patterns.
- Use the existing `SettingsView` as a behavioral reference, but do not visually nest it inside the Hub shell.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SettingsWindowController` already demonstrates a borderless transparent `NSWindow`, Escape/Command-W close, and drag-region handling.
- `SettingsView` contains the current `AppSettings` bindings, setup gate presentation, control styles, and settings section vocabulary.
- `LingobarController` owns settings entry points from the menu bar, floating gear, and setup gate.
- `LingobarHubLibrary`, `LingobarHistoryStore`, and `PhraseStore` provide the real data contracts for collection/history previews.
- `LingobarSettingsSectionDescriptor`, `LingobarSettingsSnapshot`, `LanguageAction`, and setup gate models provide native labels and state.

### Established Patterns
- App/window controllers are `@MainActor` and keep AppKit behavior out of SwiftUI body code.
- SwiftUI views are built from private computed sections and helper views in large flat files.
- Core checks are executable assertions in `Sources/LingoPeekCoreChecks/main.swift`, often including source gates for app-shell wiring.
- No new dependencies; use SwiftUI, AppKit, Foundation, and existing modules only.

### Integration Points
- `AppDelegate` can open deterministic windows based on environment variables.
- `LingobarController.start(openSettingsOnLaunch:)` currently opens the old settings window and should later route to Hub settings.
- `LingobarRootView(onOpenSettings:)` is the floating-panel gear/setup action path.
- `Package.swift` already links AppKit, SwiftUI, ApplicationServices, Carbon, and Security for `LingoPeekApp`.

</code_context>

<specifics>
## Specific Ideas

- Reference design source: `designs/lingobar-hub/Lingobar Hub.html`, `app.jsx`, `data.jsx`, `cards.jsx`, `icons.jsx`.
- Reference screenshot: `.omx/state/lingobar-hub/reference-full.png`.
- Shell dimensions: 920x624 native window, 188pt sidebar, 320pt detail column, 16pt radius.
- Required top-level nav labels: `收藏`, `历史`, `设置`.
- Setup footer labels: `已就绪` or `需完成必填项`.

</specifics>

<deferred>
## Deferred Ideas

- Full card actions, delete/clear/save/relaunch workflows: Phase 3.
- Full settings behavior and all persisted controls inside Hub: Phase 4.
- Replacing every normal settings entry point and adding final visual verification hardening: Phase 5.
- Cloud sync, accounts, direct insertion, and microphone enablement remain out of scope.

</deferred>
