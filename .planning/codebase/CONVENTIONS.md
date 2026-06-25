# Coding Conventions

**Analysis Date:** 2026-06-25

## Naming Patterns

**Files:**
- Use `PascalCase.swift` for Swift source files that define app, UI, or core types, matching the primary type name where practical: `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingobarCore/GrammarResult.swift`, `Sources/LingobarUI/GrammarResultPanel.swift`.
- Use `main.swift` only for executable utility/check targets: `Sources/LingoPeekCoreChecks/main.swift`, `Sources/LingoPeekGrammarUIChecks/main.swift`, `Sources/LingoPeekAIProbe/main.swift`.
- Keep target names in `Package.swift` as `PascalCase` product/module names: `LingoPeekApp`, `LingobarCore`, `LingobarUI`, `LingoPeekCoreChecks`.
- Use descriptive shell script names with lowercase words and underscores, as in `scripts/package_app.sh`.

**Types:**
- Use `PascalCase` for structs, classes, enums, and protocol-like view types: `LingobarViewModel`, `OpenAICompatibleClient`, `GrammarResultPanel`, `AIProviderConfiguration`.
- Core domain value types generally conform to `Equatable` and `Sendable`; add `Codable` when the type crosses JSON or persistence boundaries, as in `Sources/LingobarCore/GrammarResult.swift` and `Sources/LingobarCore/LingobarResult.swift`.
- SwiftUI-visible enums should conform to `CaseIterable` and `Identifiable` when they back pickers, tabs, or repeated controls: `LanguageAction`, `GrammarRole`, `LingobarAIProvider`, `LingobarSettingsSectionID`.
- Use lower-camel enum cases with domain names, not display labels: `.translate`, `.grammar`, `.openAICompatible`, `.followCurrentPanel`.

**Functions:**
- Use lower-camel function names and prefer verb-led names for commands and mutations: `present(selection:sourceAppName:)`, `perform(_:)`, `saveCurrentPhrase()`, `testAIConnection()`.
- Use noun/adjective-led computed properties for derived state: `setupGateStatus`, `settingsSetupGate`, `normalizedBaseURL`, `canTestAIConnection`.
- Use `check...` prefixes for zero-dependency executable check functions in `Sources/LingoPeekCoreChecks/main.swift`.
- Use `@discardableResult` only when a mutating API returns a status that callers may intentionally ignore, as in `LingobarSettingsSnapshot.selectDefaultEnglishAction(_:)`.

**Variables and Constants:**
- Use lower-camel for local variables and properties, including constants stored as `static let`: `defaultModel`, `selectionPanelSize`, `hotKeyDidChangeNotification`.
- Keep private constants close to the owning type, especially UI sizes and persistence keys in `Sources/LingoPeekApp/LingobarController.swift` and `Sources/LingoPeekApp/AppSettings.swift`.
- Avoid underscore prefixes for private members; use Swift access control (`private`, `public`, internal-by-default) instead.
- For persisted keys, keep string values namespaced and stable, for example `Lingobar.settings.actionOrder` in `Sources/LingoPeekApp/AppSettings.swift`.

## Code Style

**Formatting:**
- Use standard Swift formatting: 4-space indentation, opening braces on the declaration line, trailing commas omitted, and one blank line between declarations.
- No formatter config is detected: `.swiftformat` and `.swiftlint.yml` are not present. Match nearby Swift style manually.
- Use multiline initializers and argument lists when calls carry domain meaning or exceed one concise line, as in `LingobarResult(...)` construction in `Sources/LingobarCore/LocalLanguageEngine.swift`.
- Prefer concise implicit returns in computed properties and single-expression branches where Swift permits it: `var id: String { rawValue }`, `switch self { case .translate: "翻译" }`.

**Linting:**
- No SwiftLint or custom static-analysis config is detected.
- Build verification is the primary syntax/type gate: `swift build --product LingoPeek`.
- Keep warning-prone interop code explicit and localized in AppKit/Carbon boundary files such as `Sources/LingoPeekApp/HotKeyManager.swift` and `Sources/LingoPeekApp/SelectionReader.swift`.

## Import Organization

**Order:**
1. System frameworks used by the file: `AppKit`, `ApplicationServices`, `Carbon.HIToolbox`, `CoreGraphics`, `Foundation`, `SwiftUI`.
2. Internal modules: `LingobarCore`, then `LingobarUI`.

**Patterns:**
- Keep imports minimal per file. Core model files generally import only `Foundation`, as in `Sources/LingobarCore/OpenAICompatibleClient.swift`.
- UI files import `SwiftUI` plus internal modules they render, as in `Sources/LingobarUI/GrammarResultPanel.swift`.
- AppKit bridge/controller files import platform frameworks explicitly, as in `Sources/LingoPeekApp/LingobarController.swift`.
- There are no path aliases; Swift package targets are referenced by module name from `Package.swift`.

## Access Control and Module Boundaries

**Core:**
- Put shared domain models, AI clients, JSON parsing, settings snapshots, and persistence helpers in `Sources/LingobarCore/`.
- Mark cross-target APIs `public`; keep JSON response DTOs and implementation details internal or private, as in `OpenAIChatResponse` in `Sources/LingobarCore/OpenAICompatibleClient.swift`.
- Prefer value types for core data and behavior: `struct` and `enum` dominate `Sources/LingobarCore/`.

**App:**
- Put macOS lifecycle, settings persistence, selection capture, hot keys, windows, and view models in `Sources/LingoPeekApp/`.
- Use `@MainActor` for app controllers and observable state that interact with AppKit/SwiftUI: `LingobarViewModel`, `LingobarController`, `SettingsWindowController`.
- Keep global app settings centralized in `Sources/LingoPeekApp/AppSettings.swift`; do not scatter `UserDefaults` keys across views.

**UI Library:**
- Put reusable UI style and grammar visualization components in `Sources/LingobarUI/`.
- Keep visual constants as SwiftUI extensions or private helper views near the component that uses them: `Sources/LingobarUI/Style.swift`, `Sources/LingobarUI/GrammarResultPanel.swift`.

## Error Handling

**Patterns:**
- Throw typed errors for expected failure modes at service/client boundaries. Use `LocalizedError`, `Equatable`, and `Sendable` for public error enums such as `OpenAICompatibleError` and `DeepSeekError`.
- Use `guard` for preconditions and early returns. Invalid provider configuration throws `.unusableConfiguration` in `Sources/LingobarCore/OpenAICompatibleClient.swift`; unavailable UI actions update status and return in `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Preserve HTTP status and response body text when AI providers fail: `.server(statusCode:message:)` in `Sources/LingobarCore/OpenAICompatibleClient.swift`.
- Convert low-level errors to user-facing copy at UI boundaries, not in core clients: `userFacingAIErrorMessage(_:)` in `Sources/LingoPeekApp/LingobarViewModel.swift`.

**Expected Failures:**
- Return optionals for unavailable platform data such as selected text or clipboard fallback in `Sources/LingoPeekApp/SelectionReader.swift`.
- Return `nil` from factory helpers when setup is incomplete, as in `AppSettings.makeAIClient()`.
- Use `try?` only for non-critical local persistence where the UI can continue with fallback data: phrase load/save in `Sources/LingoPeekApp/LingobarViewModel.swift`.

**Process Failures:**
- Executable check/probe targets print clear failures to `stderr` with `fputs` and terminate with `exit(1)`: `Sources/LingoPeekCoreChecks/main.swift`, `Sources/LingoPeekGrammarUIChecks/main.swift`, `Sources/LingoPeekAIProbe/main.swift`.

## Concurrency and State

**Main Actor:**
- Annotate UI-facing classes and snapshot rendering with `@MainActor`: `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/SettingsSnapshotRenderer.swift`.
- Wrap AppKit callbacks into main-actor work using `Task { @MainActor in ... }` or `DispatchQueue.main.async` when crossing Carbon/AppKit callback boundaries, as in `Sources/LingoPeekApp/HotKeyManager.swift`.

**Async Requests:**
- Use request IDs to ignore stale async results. `activeAIRequestID` in `Sources/LingoPeekApp/LingobarViewModel.swift` and `aiConnectionTestID` in `Sources/LingoPeekApp/SettingsView.swift` are the established pattern.
- Set loading/status state before launching a task and reset it only after confirming the response still belongs to the latest request.

**Sendability:**
- Use `Sendable` on core value types.
- Reserve `@unchecked Sendable` for reference types that protect mutable state or bridge C APIs manually, such as `PhraseStore` and `HotKeyManager`.

## Logging and Diagnostics

**Framework:**
- No logging framework is detected.
- Use `print` for success output in executable checks/probes and `fputs(..., stderr)` for failures.

**Patterns:**
- Keep production UI diagnostics user-facing through `status`, result rows, or badges rather than console logging.
- Do not log API tokens or settings secrets. Token handling is centralized through environment variables and `LocalTokenStore` in `Sources/LingoPeekApp/AppSettings.swift` and `Sources/LingoPeekApp/LocalTokenStore.swift`.

## Comments

**When to Comment:**
- Prefer self-describing names and small helpers over comments.
- Use comments sparingly for intentional expectations in checks, such as `// Expected.` in `Sources/LingoPeekCoreChecks/main.swift`.
- Keep prompt/schema text in multiline string literals where the text itself is product behavior, as in `grammarSystemPrompt()` in `Sources/LingoPeekApp/LingobarViewModel.swift`.

**TODO Comments:**
- No `TODO`, `FIXME`, `HACK`, or `XXX` comments are detected in `Sources/` or `Tests/`.
- If introduced, link to the relevant GitHub issue or document why the follow-up cannot be handled immediately.

## Function Design

**Size and Shape:**
- Prefer small private helpers for platform interactions and UI calculations: `clampedOrigin(_:size:in:)`, `placementVisibleFrame(for:)`, `firstNonEmpty(_:)`, `compactAIConnectionError(_:)`.
- Large SwiftUI files may contain many computed view sections; keep each section as a private computed property or private helper view rather than one monolithic `body`.
- Keep AppKit bridge types nested/private when they exist only to support one view, as in `LingobarPanel`, `SettingsWindow`, and `LingobarInputNSTextView`.

**Parameters and Returns:**
- Use labeled parameters for clarity at call sites: `present(selection:sourceAppName:)`, `request(configuration:system:user:)`.
- Use simple result types (`Bool`, optional, domain enum) for validation-style APIs and typed throws for operational failures.
- Preserve domain order in arrays when it is user-visible; update checks in `Sources/LingoPeekCoreChecks/main.swift` when changing `LanguageAction.selectionActions` or `LingobarSettingsSnapshot.defaultActionOrder`.

## SwiftUI and AppKit Patterns

**SwiftUI Views:**
- Compose screens from private computed properties and helper views: `Sources/LingoPeekApp/LingobarRootView.swift`, `Sources/LingoPeekApp/SettingsView.swift`, `Sources/LingobarUI/GrammarResultPanel.swift`.
- Use `@State` for local UI state, `@ObservedObject` for the app view model, and `@Binding` for representable bridges.
- Use SF Symbols through `Image(systemName:)` with domain symbols supplied by model enums, such as `LanguageAction.symbol`.
- Keep accessibility identifiers on interactive/render-verified grammar UI elements, for example `grammar-tab-*` and `grammar-viz-*` in `Sources/LingobarUI/GrammarResultPanel.swift`.

**AppKit Bridges:**
- Use `NSViewRepresentable` and coordinator classes for custom text input/selection behavior in `Sources/LingoPeekApp/LingobarRootView.swift`.
- Keep macOS window behavior in controller/window classes, not SwiftUI view bodies: `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/SettingsWindowController.swift`.
- Keep Carbon hot-key registration isolated in `Sources/LingoPeekApp/HotKeyManager.swift` and hot-key display mapping in `Sources/LingoPeekApp/LingobarHotKey.swift`.

## Persistence and Configuration

**Environment and Defaults:**
- Environment variables override stored settings for AI provider fields: `AI_MODEL`, `DEEPSEEK_MODEL`, `AI_BASE_URL`, `DEEPSEEK_BASE_URL`, `AI_API_TOKEN`, `DEEPSEEK_API_KEY` in `Sources/LingoPeekApp/AppSettings.swift`.
- Use `UserDefaults` for non-secret settings and `LocalTokenStore` for the API token. The token store also uses `UserDefaults`, so do not treat it as secure storage.
- Use deterministic defaults from model enums rather than duplicating literals in views: `LingobarAIProvider.defaultModel`, `LingobarAIProvider.defaultBaseURLString`.

**Files:**
- Store saved phrases as pretty-printed, sorted-key, ISO-8601 JSON through `PhraseStore` in `Sources/LingobarCore/PhraseStore.swift`.
- Use atomic writes for local persisted files, as in `data.write(to: fileURL, options: [.atomic])`.

## Verification Commands

- Build the app with `swift build --product LingoPeek`.
- Run core zero-dependency checks with `swift run LingoPeekCoreChecks`.
- Run grammar UI render checks with `swift run LingoPeekGrammarUIChecks`.
- Run AI connectivity only with user-provided secrets: `DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeekAIProbe`.
- Package the unsigned local app with `scripts/package_app.sh`; CI runs `swift run LingoPeekCoreChecks` and `scripts/package_app.sh` in `.github/workflows/package-app.yml`.

---

*Convention analysis: 2026-06-25*
*Update when patterns change*
