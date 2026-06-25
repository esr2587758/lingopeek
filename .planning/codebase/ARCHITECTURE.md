# Architecture

**Analysis Date:** 2026-06-25

## Pattern Overview

**Overall:** Native macOS SwiftPM monolith with target-layered boundaries

**Key Characteristics:**
- Single-process macOS app shipped from the `LingoPeek` SwiftPM executable target in `Package.swift`.
- AppKit owns process lifecycle, global hotkeys, floating panels, menu bar item, Accessibility selection capture, and custom windows under `Sources/LingoPeekApp/`.
- SwiftUI renders the floating Lingobar panel and settings window from observable state in `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Domain models, settings snapshots, AI request contracts, structured result decoding, grammar data, and phrase persistence live in the Foundation-only core target under `Sources/LingobarCore/`.
- Dedicated reusable grammar UI components live in `Sources/LingobarUI/` so grammar rendering can be tested independently from the app shell.
- Language results are AI-required behind setup gating; deterministic fixtures and check targets exist for development and verification.

## Layers

**Package and Target Layer:**
- Purpose: Defines build products and dependency direction.
- Contains: SwiftPM products and target dependencies.
- Location: `Package.swift`.
- Depends on: SwiftPM and Apple platform frameworks.
- Used by: Local builds, check executables, GitHub Actions workflow in `.github/workflows/package-app.yml`.
- Use this layer to add targets or products; keep `LingobarCore` independent from AppKit and SwiftUI.

**Core Domain Layer:**
- Purpose: Encapsulates product concepts, settings value types, result contracts, and local data shapes.
- Contains: language actions, modes, setup gate status, settings descriptors, result rows, saved phrases, grammar structures, fixtures, and local fallback result generation.
- Location: `Sources/LingobarCore/LanguageAction.swift`, `Sources/LingobarCore/LingobarSettings.swift`, `Sources/LingobarCore/SetupGate.swift`, `Sources/LingobarCore/LingobarResult.swift`, `Sources/LingobarCore/GrammarResult.swift`, `Sources/LingobarCore/GrammarUITestFixtures.swift`, `Sources/LingobarCore/LocalLanguageEngine.swift`.
- Depends on: `Foundation`.
- Used by: `Sources/LingoPeekApp/`, `Sources/LingobarUI/`, `Sources/LingoPeekCoreChecks/main.swift`, and `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Use this layer for behavior that should be testable without launching a macOS app window.

**AI Provider Boundary Layer:**
- Purpose: Normalizes provider settings, builds OpenAI-compatible requests, calls chat completions, extracts JSON, and maps provider compatibility.
- Contains: `AIProviderConfiguration`, `OpenAICompatibleClient`, `OpenAICompatibleRequestFactory`, OpenAI request/response DTOs, DeepSeek compatibility wrappers, and `StructuredJSONExtractor`.
- Location: `Sources/LingobarCore/AIProviderConfiguration.swift`, `Sources/LingobarCore/OpenAICompatibleClient.swift`, `Sources/LingobarCore/DeepSeekClient.swift`, `Sources/LingobarCore/StructuredJSONExtractor.swift`, `Sources/LingobarCore/StructuredLingobarResult.swift`.
- Depends on: `Foundation` networking and Codable.
- Used by: `Sources/LingoPeekApp/AppSettings.swift`, `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekAIProbe/main.swift`, and `Sources/LingoPeekCoreChecks/main.swift`.
- Use this layer for provider protocol changes; keep provider-specific product copy out of UI-facing names unless `LingobarSettings.swift` requires it.

**App Orchestration Layer:**
- Purpose: Bridges macOS process events, global input, window management, status item behavior, app settings, and SwiftUI hosting.
- Contains: app entry, delegate, floating panel controller, settings window controller, hotkey registration, selection reader, settings persistence facade, token store, snapshot renderer, and AppKit window helpers.
- Location: `Sources/LingoPeekApp/LingoPeekApp.swift`, `Sources/LingoPeekApp/AppDelegate.swift`, `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/SettingsWindowController.swift`, `Sources/LingoPeekApp/HotKeyManager.swift`, `Sources/LingoPeekApp/LingobarHotKey.swift`, `Sources/LingoPeekApp/SelectionReader.swift`, `Sources/LingoPeekApp/AppSettings.swift`, `Sources/LingoPeekApp/LocalTokenStore.swift`, `Sources/LingoPeekApp/SettingsSnapshotRenderer.swift`, `Sources/LingoPeekApp/WindowDragHandle.swift`.
- Depends on: `AppKit`, `ApplicationServices`, `Carbon.HIToolbox`, `Security`, `SwiftUI`, and `LingobarCore`.
- Used by: The `LingoPeek` executable target.
- Use this layer for macOS-specific adapters and keep direct `NSApplication`, `NSPanel`, `AXUIElement`, `CGEvent`, `NSEvent`, and `UserDefaults` access out of `LingobarCore`.

**State and Workflow Layer:**
- Purpose: Owns Lingobar session state and user action workflows.
- Contains: `@Published` UI state, active language action, selected/input text, AI loading state, grammar result state, saved phrases, setup mode, action order, copy/collect handlers, stale-request protection, and prompt construction.
- Location: `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Depends on: `AppKit` for pasteboard access, `Foundation`, and `LingobarCore`.
- Used by: `Sources/LingoPeekApp/LingobarController.swift` and `Sources/LingoPeekApp/LingobarRootView.swift`.
- Use this layer for user-visible Lingobar behavior; update checks in `Sources/LingoPeekCoreChecks/main.swift` when behavior depends on core contracts.

**Presentation Layer:**
- Purpose: Renders Lingobar panel, settings window, reusable grammar visualizations, and shared style primitives.
- Contains: SwiftUI panel composition, settings sections, result-specific layouts, selectable AppKit text bridges, input text view bridges, grammar tabs, diagrams, cards, styles, colors, and small layout helpers.
- Location: `Sources/LingoPeekApp/LingobarRootView.swift`, `Sources/LingoPeekApp/SettingsView.swift`, `Sources/LingoPeekApp/FlowLayout.swift`, `Sources/LingobarUI/GrammarResultPanel.swift`, `Sources/LingobarUI/Style.swift`.
- Depends on: `SwiftUI`, AppKit bridges where needed, `LingobarCore`, and `LingobarUI`.
- Used by: AppKit hosting views in `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/SettingsWindowController.swift`, and renderer checks in `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Use `Sources/LingobarUI/` for reusable components that should be rendered or verified outside the app target; keep app-only settings and panel state in `Sources/LingoPeekApp/`.

**Persistence Layer:**
- Purpose: Stores settings, token, panel position, hotkey, and collected phrases locally.
- Contains: `UserDefaults` accessors in `AppSettings`, token storage in `LocalTokenStore`, panel origin storage in `LingobarController`, and JSON phrase storage in `PhraseStore`.
- Location: `Sources/LingoPeekApp/AppSettings.swift`, `Sources/LingoPeekApp/LocalTokenStore.swift`, `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingobarCore/PhraseStore.swift`.
- Depends on: `Foundation`; app settings also depend on `ApplicationServices` for Accessibility status.
- Used by: `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekApp/SettingsView.swift`, and `Sources/LingoPeekCoreChecks/main.swift`.
- Use `PhraseStore` for portable JSON persistence and `AppSettings` for app preference persistence; preserve environment-variable precedence for AI configuration.

**Verification and Tooling Layer:**
- Purpose: Provides zero-dependency executable checks, visual rendering checks, connectivity probe, packaging, and CI packaging.
- Contains: core check runner, grammar UI renderer checks, DeepSeek probe, packaging shell script, and GitHub Actions workflow.
- Location: `Sources/LingoPeekCoreChecks/main.swift`, `Sources/LingoPeekGrammarUIChecks/main.swift`, `Sources/LingoPeekAIProbe/main.swift`, `scripts/package_app.sh`, `.github/workflows/package-app.yml`.
- Depends on: SwiftPM products, CoreGraphics/SwiftUI for grammar render checks, and optional user-provided secrets for AI probing.
- Used by: Future agents before claiming behavior changes.
- Use executable check targets for verification because `Tests/` has no XCTest files in this codebase.

## Data Flow

**App Launch and Panel Startup:**

1. SwiftUI starts at `Sources/LingoPeekApp/LingoPeekApp.swift`.
2. `@NSApplicationDelegateAdaptor` installs `AppDelegate` from `Sources/LingoPeekApp/AppDelegate.swift`.
3. `AppDelegate.applicationDidFinishLaunching` handles UI-test reset and settings snapshot environment modes, sets the activation policy, creates `LingobarController`, and calls `start`.
4. `LingobarController.start` updates the menu bar item, registers the configured global hotkey through `HotKeyManager`, observes hotkey/settings notifications, and either opens settings or presents Lingobar.
5. `LingobarController.ensurePanel` creates a borderless floating `LingobarPanel`, hosts `LingobarRootView`, wires callbacks for close/settings/accessibility/actions, and keeps the panel reusable.

**Selection-First Language Action:**

1. User invokes Lingobar from hotkey, menu, or startup path handled by `Sources/LingoPeekApp/LingobarController.swift`.
2. `LingobarController.present(captureSelectionByCopying:)` checks `AppSettings.setupGateStatus`.
3. If setup is incomplete, `LingobarViewModel.presentSetupGate` enters `.setup` mode and `LingobarRootView` renders setup requirements.
4. If setup is complete, `SelectionReader` reads `kAXSelectedTextAttribute`; when the selected range exists but selected text is unavailable, it sends Command-C with `CGEvent`, waits for pasteboard change, reads text, and restores the prior pasteboard snapshot.
5. `LingobarViewModel.present(selection:sourceAppName:)` enters `.selection` mode, chooses the default action through `LanguageAction.defaultSelectionAction(for:)` plus `AppSettings.defaultEnglishAction` or `AppSettings.defaultChineseMixedAction`, initializes a pending result, and starts AI.
6. `LingobarViewModel.runAIIfAvailable` creates `OpenAICompatibleClient` through `AppSettings.makeAIClient`, sends `complete(system:user:)`, extracts JSON with `StructuredJSONExtractor`, and decodes either `GrammarResult` or `StructuredLingobarResult`.
7. The view model ignores stale AI completions by comparing `activeAIRequestID`, then updates `result`, `grammarResult`, `status`, loading flags, and layout callbacks on the main actor.
8. `LingobarController.resizePanelForCurrentState` adjusts the panel size, while `LingobarRootView` renders generic result panels or `GrammarResultPanel`.
9. Footer and inline-selection actions call back into `LingobarViewModel.copyResult`, `saveCurrentPhrase`, `copyInlineSelection`, `reopenInlineSelection`, or `collectInlineSelection`.

**Input Mode Rewrite:**

1. When no selection is available, `LingobarViewModel.present` enters `.input` mode, sets `.rewrite`, optionally preloads clipboard text when `AppSettings.autoReadClipboard` is true, and hides the result until submission.
2. `LingobarRootView` renders `LingobarInputTextView`, a SwiftUI/AppKit bridge for multiline input and IME marked text handling.
3. Return key or the arrow button calls `LingobarViewModel.submitInput`.
4. `submitInput` validates non-empty text, then delegates to `perform(.rewrite)`.
5. The AI flow matches the selection action path and renders the input result panel.

**Settings Flow:**

1. Settings opens from the SwiftUI Settings scene, menu bar item, Lingobar gear button, or setup gate callback.
2. `SettingsWindowController` creates a borderless `SettingsWindow` hosting `SettingsView`.
3. `SettingsView` uses `AppSettings.makeSettingsSnapshot` as its local mutable view state.
4. User changes persist through `AppSettings.save...` methods, which write `UserDefaults` or `LocalTokenStore` and post `AppSettings.settingsDidChangeNotification`.
5. `LingobarController` observes settings changes and refreshes action order, setup gate status, and menu bar visibility.
6. Hotkey edits persist with `AppSettings.saveHotKey`, post `AppSettings.hotKeyDidChangeNotification`, and trigger hotkey re-registration.

**Grammar Fixture and Visual Verification Flow:**

1. When `LINGOPEEK_GRAMMAR_FIXTURE=1`, `LingobarController.present` bypasses selection and AI.
2. `LingobarViewModel.presentGrammarFixture` loads `GrammarResult.fixture(id:)` from `Sources/LingobarCore/GrammarUITestFixtures.swift`.
3. `LingobarRootView` renders the native grammar panel through `GrammarResultPanel`.
4. `Sources/LingoPeekGrammarUIChecks/main.swift` renders every `GrammarVizView` tab with `ImageRenderer` and checks nonblank output.

**State Management:**
- Settings and token values come from environment variables first, then local storage, then defaults in `Sources/LingoPeekApp/AppSettings.swift`.
- `UserDefaults` stores AI provider/model/base URL, local API token via `LocalTokenStore`, launch/menu/appearance/trigger/action/default/collection/clipboard preferences, hotkey, and panel origin.
- `PhraseStore.defaultStore()` writes collected phrases to Application Support at `LingoPeek/phrases.json` with pretty-printed sorted-key JSON and atomic writes.
- Main UI state is `@MainActor` and `@Published` inside `LingobarViewModel`.
- AI operations are async `Task` calls with request IDs; there is no long-lived cancellation token or background queue abstraction.

## Key Abstractions

**LanguageAction:**
- Purpose: Defines Lingobar toolbar actions, availability, keyboard shortcuts, symbols, titles, contextual more-action copy, and default selection behavior.
- Location: `Sources/LingobarCore/LanguageAction.swift`.
- Pattern: Core enum with computed UI and behavior metadata.
- Use this as the source of truth when adding or changing language actions.

**LingobarResult and StructuredLingobarResult:**
- Purpose: Represent generic language action output and the structured AI JSON shape for non-grammar actions.
- Location: `Sources/LingobarCore/LingobarResult.swift`, `Sources/LingobarCore/StructuredLingobarResult.swift`.
- Pattern: Codable/Sendable value objects bridged into UI-ready `LingobarResult`.
- Use this for translate, rewrite, examples, and pronunciation result contracts.

**GrammarResult:**
- Purpose: Represents grammar-specific AI output for native visualization, including chunks, dependencies, tree, trunk, tense/voice, word order, patterns, collocations, phrases, and grammar points.
- Location: `Sources/LingobarCore/GrammarResult.swift`.
- Pattern: Dedicated structured contract with tolerant Codable defaults for missing optional fields.
- Use this instead of flattening grammar into generic rows.

**LingobarViewModel:**
- Purpose: Coordinates user actions, mode transitions, AI execution, result parsing, status text, collection, pasteboard writes, and layout notifications.
- Location: `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Pattern: `@MainActor ObservableObject` used directly by SwiftUI views and AppKit controllers.
- Use this for Lingobar workflow behavior; keep reusable pure model rules in `LingobarCore`.

**LingobarController:**
- Purpose: Owns the floating panel lifecycle, menu bar item, global hotkey registration, setup gate routing, selection capture routing, panel positioning, and window resizing.
- Location: `Sources/LingoPeekApp/LingobarController.swift`.
- Pattern: Main-actor AppKit coordinator hosting SwiftUI.
- Use this for macOS shell behavior and panel geometry.

**AppSettings and LingobarSettingsSnapshot:**
- Purpose: Bridge persistent app preferences to a typed settings model consumed by settings UI and setup gate logic.
- Location: `Sources/LingoPeekApp/AppSettings.swift`, `Sources/LingobarCore/LingobarSettings.swift`.
- Pattern: App-side persistence facade plus core immutable/mutable snapshot model.
- Use the snapshot model for UI state and the app facade for persistence and notifications.

**OpenAICompatibleClient:**
- Purpose: Sends non-streaming chat-completions requests to OpenAI-compatible providers and returns response content.
- Location: `Sources/LingobarCore/OpenAICompatibleClient.swift`.
- Pattern: Sendable service value with injectable `URLSession`.
- Use the request factory for unit-like checks of payloads without network calls.

**PhraseStore:**
- Purpose: Persists collected language items.
- Location: `Sources/LingobarCore/PhraseStore.swift`.
- Pattern: Lock-protected JSON file store with atomic writes.
- Use this for saved-phrase storage; avoid scattering phrase file access in app views.

**GrammarResultPanel:**
- Purpose: Renders native grammar visualizations across annotated chunks, dependency diagrams, tree, trunk, tense/voice, and word-order tabs.
- Location: `Sources/LingobarUI/GrammarResultPanel.swift`.
- Pattern: Reusable SwiftUI view backed by `GrammarResult`.
- Use this target for grammar UI changes that should be render-checkable outside the app executable.

## Entry Points

**Main App:**
- Location: `Sources/LingoPeekApp/LingoPeekApp.swift`.
- Triggers: `swift run LingoPeek`, packaged `LingoPeek.app`, or SwiftPM executable product.
- Responsibilities: Defines the SwiftUI app, installs `AppDelegate`, and exposes the settings scene.

**App Delegate:**
- Location: `Sources/LingoPeekApp/AppDelegate.swift`.
- Triggers: macOS application lifecycle.
- Responsibilities: Handles environment-driven testing/snapshot modes, activation policy, controller startup, and controller shutdown.

**Floating Lingobar Panel:**
- Location: `Sources/LingoPeekApp/LingobarController.swift`.
- Triggers: startup presentation, global hotkey, menu bar commands, and settings callbacks.
- Responsibilities: Capture selection, enforce setup gate, host panel UI, register shortcuts, and place/resize the floating panel.

**Settings Window:**
- Location: `Sources/LingoPeekApp/SettingsWindowController.swift`, `Sources/LingoPeekApp/SettingsView.swift`.
- Triggers: SwiftUI Settings scene, menu bar item, setup gate button, gear buttons.
- Responsibilities: Render and persist settings, test AI connectivity, record hotkey, and open Accessibility settings.

**Core Checks:**
- Location: `Sources/LingoPeekCoreChecks/main.swift`.
- Triggers: `swift run LingoPeekCoreChecks`.
- Responsibilities: Verify domain rules, AI request payloads, setup gate, settings model, structured parsing, grammar contracts, and phrase persistence.

**Grammar UI Checks:**
- Location: `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Triggers: `swift run LingoPeekGrammarUIChecks`.
- Responsibilities: Render every grammar visualization tab for fixture data and check generated images are nonblank.

**AI Probe:**
- Location: `Sources/LingoPeekAIProbe/main.swift`.
- Triggers: `DEEPSEEK_API_KEY=... swift run LingoPeekAIProbe`.
- Responsibilities: Perform a real DeepSeek-compatible completion check when secrets are supplied externally.

**Packaging:**
- Location: `scripts/package_app.sh`, `.github/workflows/package-app.yml`.
- Triggers: Local script or GitHub Actions push/workflow dispatch.
- Responsibilities: Build/package the app and upload `dist/LingoPeek.zip` in CI.

## Error Handling

**Strategy:** Typed core errors and thrown failures are converted at app boundaries into user-facing status, result cards, stderr messages, or process exit codes.

**Patterns:**
- Provider failures throw `OpenAICompatibleError` or `DeepSeekError` from `Sources/LingobarCore/OpenAICompatibleClient.swift` and `Sources/LingobarCore/DeepSeekClient.swift`.
- AI decode failures in `Sources/LingoPeekApp/LingobarViewModel.swift` become a structured error `LingobarResult` with recovery rows and status `"格式错误"`.
- Network/provider failures in `LingobarViewModel` become localized app copy through `userFacingAIErrorMessage`.
- Settings connection tests in `Sources/LingoPeekApp/SettingsView.swift` compact success/failure messages into `AIConnectionTestState`.
- Setup gate failures are represented as `SetupGateStatus` and routed to `.setup` mode instead of attempting language actions.
- Check executables throw local `CheckFailure`, print to stderr, and exit nonzero.
- Snapshot rendering failures in `Sources/LingoPeekApp/AppDelegate.swift` print to stderr and terminate.
- Invalid stored settings fall back to typed defaults in `AppSettings` and `LingobarSettingsSnapshot`.

## Cross-Cutting Concerns

**Concurrency and Main-Actor Safety:**
- UI controllers and view model are main-actor oriented: `LingobarController`, `LingobarViewModel`, `SettingsWindowController`, and `SettingsSnapshotRenderer` are `@MainActor`.
- AI calls use `Task` from the main actor and rely on `activeAIRequestID` to ignore stale completions.
- `PhraseStore` uses `NSLock` and is marked `@unchecked Sendable`; keep file I/O access inside this abstraction.

**Validation:**
- AI provider validation lives in `AIProviderConfiguration.isUsable`.
- Language-action availability lives in `LanguageAction.isAvailable(for:)`.
- Settings allowed defaults and action movement live in `LingobarSettingsSnapshot`.
- Grammar AI response tolerance lives in custom Codable initializers in `GrammarResult` and related structs.
- Check new behavior in `Sources/LingoPeekCoreChecks/main.swift` before relying on it from app UI.

**Accessibility and System Integration:**
- Accessibility readiness uses `AXIsProcessTrusted()` in `Sources/LingoPeekApp/AppSettings.swift`.
- Selection capture uses AX focused element attributes and pasteboard fallback in `Sources/LingoPeekApp/SelectionReader.swift`.
- Global hotkeys use Carbon APIs in `Sources/LingoPeekApp/HotKeyManager.swift`.
- AppKit panels handle Escape, Command-W, dragging, and command shortcuts in `Sources/LingoPeekApp/LingobarController.swift` and `Sources/LingoPeekApp/SettingsWindowController.swift`.

**Secrets and Configuration:**
- Environment variables `AI_API_TOKEN`, `AI_BASE_URL`, `AI_MODEL`, `DEEPSEEK_API_KEY`, `DEEPSEEK_BASE_URL`, and `DEEPSEEK_MODEL` override stored settings in `Sources/LingoPeekApp/AppSettings.swift`.
- Local token storage is `UserDefaults` through `Sources/LingoPeekApp/LocalTokenStore.swift`; do not assume Keychain-backed storage.
- Do not read or commit `.env` files; `.gitignore` excludes `.env` and `.env.*`.

**Logging and Diagnostics:**
- There is no structured logging layer.
- CLI-style diagnostics use `print` and `fputs` in check/probe/snapshot paths.
- User-facing runtime failures are rendered through `LingobarResult`, `status`, or settings badges.

**Testing and Verification:**
- Build with `swift build --product LingoPeek`.
- Run zero-dependency checks with `swift run LingoPeekCoreChecks`.
- Run grammar visual checks with `swift run LingoPeekGrammarUIChecks` after grammar UI/data changes.
- Run `LingoPeekAIProbe` only with user-provided secrets.
- `Tests/` is empty; do not assume XCTest coverage exists.

**Documentation and Decisions:**
- Domain language lives in `CONTEXT.md`.
- ADRs under `docs/adr/` define AI-required results, OpenAI-compatible settings, structured AI responses, grammar-specific result shape, and native grammar rendering.
- Product and interaction specs under `docs/` should guide UI copy and feature boundaries before changing app behavior.

---

*Architecture analysis: 2026-06-25*
*Update when major patterns change*
