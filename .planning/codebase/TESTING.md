# Testing Patterns

**Analysis Date:** 2026-06-25

## Test Framework

**Runner:**
- The repository uses Swift executable check targets instead of XCTest or Swift Testing.
- `Package.swift` defines `LingoPeekCoreChecks`, `LingoPeekGrammarUIChecks`, and `LingoPeekAIProbe` as executable targets.
- `Tests/LingoPeekAppUITests` and `Tests/LingobarCoreTests` exist as empty directories; no XCTest test target is declared in `Package.swift`.

**Assertion Library:**
- Use local `check(_:_:)` helpers that throw custom error enums.
- `Sources/LingoPeekCoreChecks/main.swift` defines `CheckFailure` and `check(_:_:)`.
- `Sources/LingoPeekGrammarUIChecks/main.swift` defines `GrammarUICheckFailure` and `check(_:_:)`.
- Assertions use Swift equality, collection predicates, and typed `do/catch` blocks rather than external matchers.

**Run Commands:**
```bash
swift build --product LingoPeek                      # Build/type-check the app product
swift run LingoPeekCoreChecks                        # Run core model, request, settings, parsing, and persistence checks
swift run LingoPeekGrammarUIChecks                   # Render grammar tabs and verify nonblank output
DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeekAIProbe
                                                       # Optional live DeepSeek connectivity probe
```

## Test File Organization

**Location:**
- Put deterministic non-UI checks in executable check targets under `Sources/`, following `Sources/LingoPeekCoreChecks/main.swift`.
- Put SwiftUI render checks in executable check targets under `Sources/`, following `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Put live external-service probes in dedicated executable targets, following `Sources/LingoPeekAIProbe/main.swift`.
- Do not add XCTest files under `Tests/` unless `Package.swift` also gains a supported test target and the toolchain supports XCTest or Swift Testing.

**Naming:**
- Name check executables after the product area plus `Checks`: `LingoPeekCoreChecks`, `LingoPeekGrammarUIChecks`.
- Name check functions with a `check` prefix and the behavior area: `checkDeepSeekRequestFactory()`, `checkGrammarAIResponseTolerance()`, `checkPhraseStore()`.
- Name visual assertion helpers with intent verbs: `assertAllGrammarTabsRender(for:)`, `visiblePixelCount(in:)`.

**Structure:**
```text
Sources/
  LingoPeekCoreChecks/
    main.swift
  LingoPeekGrammarUIChecks/
    main.swift
  LingoPeekAIProbe/
    main.swift
  LingobarCore/
    GrammarResult.swift
    GrammarUITestFixtures.swift
Tests/
  LingoPeekAppUITests/
  LingobarCoreTests/
```

## Test Structure

**Core Check Pattern:**
```swift
enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw CheckFailure.failed(message)
    }
}
```

**Executable Entrypoint Pattern:**
```swift
do {
    try checkLocalLanguageEngine()
    try checkOpenAICompatibleRequestFactory()
    try checkPhraseStore()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
```

**Patterns:**
- Keep each check function synchronous unless it must call an async API.
- Group related assertions in one focused function, as in `checkLingobarSettingsSnapshotBehavior()` and `checkGrammarTabContracts(_:)`.
- Use messages that describe the contract, not implementation mechanics: `"request should use POST"`, `"grammar fixture should JSON round-trip"`.
- For negative-path decoding checks, use `do/catch` and catch the expected error type, as in `checkStructuredAIResultParsing()`.

## Mocking and Isolation

**Framework:**
- No mocking framework is used.
- Prefer dependency injection and local deterministic fixtures over mocks.

**Patterns:**
- Inject file locations for persistence checks. `checkPhraseStore()` creates a unique temporary directory and passes a custom URL to `PhraseStore(fileURL:)`.
- Inject AI configuration into request factories instead of making network calls. `checkOpenAICompatibleRequestFactory()` decodes `URLRequest.httpBody` and checks headers, timeout, model, JSON mode, and token budget.
- Use `GrammarResult.grammarUITestFixtures` and named fixtures from `Sources/LingobarCore/GrammarUITestFixtures.swift` for deterministic grammar rendering.
- Use environment variables to switch app runtime modes for manual/UI verification: `LINGOPEEK_GRAMMAR_FIXTURE`, `LINGOPEEK_GRAMMAR_FIXTURE_ID`, `LINGOPEEK_OPEN_SETTINGS`, `LINGOPEEK_RENDER_SETTINGS_SNAPSHOT`, and `LINGOPEEK_UI_TEST_RESET_SETTINGS`.

**What to Mock or Avoid:**
- Do not call live AI providers in default checks. Use `Sources/LingoPeekAIProbe/main.swift` only when secrets are explicitly provided.
- Do not depend on the user's clipboard, Accessibility permissions, menu bar state, or frontmost app in automated core checks.
- Do not mock pure value-type transformations; check them directly through public APIs such as `LanguageAction.defaultSelectionAction(for:)`, `StructuredJSONExtractor.extractObject(from:)`, and `GrammarResult.lingobarResult(shortcut:)`.

## Fixtures and Factories

**Core Fixtures:**
- Store reusable grammar fixtures in `Sources/LingobarCore/GrammarUITestFixtures.swift` and expose them through `GrammarResult.grammarUITestFixtures`.
- Keep base grammar fixture coverage in `GrammarResult.mockupFixture` in `Sources/LingobarCore/GrammarResult.swift`.
- Build ad hoc JSON fixtures inline in `Sources/LingoPeekCoreChecks/main.swift` when checking decoding tolerance or schema behavior.

**Factory Checks:**
- Check request factory output without sending it over the network:
  - `DeepSeekRequestFactory.request(...)` in `Sources/LingobarCore/DeepSeekClient.swift`
  - `OpenAICompatibleRequestFactory.request(...)` in `Sources/LingobarCore/OpenAICompatibleClient.swift`
  - `OpenAICompatibleRequestFactory.connectivityTestRequest(configuration:)` in `Sources/LingobarCore/OpenAICompatibleClient.swift`
- Decode request bodies using the same public Codable DTOs used by production code.

**Temporary Data:**
- Use `FileManager.default.temporaryDirectory` plus a UUID for filesystem checks.
- Write via production APIs and read back through production APIs; `checkPhraseStore()` is the model.

## Coverage

**Requirements:**
- No numeric coverage target is configured.
- No coverage command or coverage reporting artifact is detected.
- CI currently gates packaging with `swift run LingoPeekCoreChecks` in `.github/workflows/package-app.yml`.

**Effective Coverage Areas:**
- `Sources/LingoPeekCoreChecks/main.swift` covers language action defaults, keyboard shortcut mapping, AI request factories, setup gating, settings snapshots, AI provider configuration, structured result parsing, grammar fixtures, grammar AI response tolerance, and phrase persistence.
- `Sources/LingoPeekGrammarUIChecks/main.swift` covers grammar tab enumeration, fixture count, SwiftUI renderability, image dimensions, and nonblank rendered pixels.
- `Sources/LingoPeekAIProbe/main.swift` covers live DeepSeek connectivity only when the environment provides a token.

**Gaps:**
- AppKit selection capture, Carbon global hot-key registration, menu bar behavior, panel placement, and Settings window interactions are not automated in default checks.
- `Sources/LingoPeekApp/SettingsView.swift` and `Sources/LingoPeekApp/LingobarRootView.swift` have indirect coverage through render/snapshot affordances but no interaction test suite.

## Test Types

**Unit-Style Executable Checks:**
- Use `Sources/LingoPeekCoreChecks/main.swift` for pure or mostly pure domain behavior.
- Keep checks deterministic and free of user secrets.
- Add new checks to the final `do` block so failures exit with status 1.

**Render Checks:**
- Use `Sources/LingoPeekGrammarUIChecks/main.swift` for SwiftUI rendering that can be verified without launching the app.
- Render with `ImageRenderer`, set a fixed proposed width, and verify dimensions plus `visiblePixelCount(in:)`.
- Prefer deterministic fixtures from `LingobarCore` over live AI output.

**Manual/Runtime Checks:**
- Run the app with `swift run LingoPeek` for panel behavior.
- Run deterministic grammar fixture modes:
```bash
LINGOPEEK_GRAMMAR_FIXTURE=1 LINGOPEEK_GRAMMAR_FIXTURE_ID=policy-incentives swift run LingoPeek
LINGOPEEK_GRAMMAR_FIXTURE=1 LINGOPEEK_GRAMMAR_FIXTURE_ID=engineering-redesign swift run LingoPeek
```
- Render Settings snapshots through the app delegate environment path when visual inspection is needed:
```bash
LINGOPEEK_RENDER_SETTINGS_SNAPSHOT=/tmp/settings.png swift run LingoPeek
```

**External Connectivity Probe:**
- Use `Sources/LingoPeekAIProbe/main.swift` for live provider verification.
- Require explicit environment variables; never store or commit API keys:
```bash
DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeekAIProbe
```

## Common Patterns

**Async Testing:**
- Default check targets avoid async behavior.
- For live async provider behavior, `Sources/LingoPeekAIProbe/main.swift` uses top-level `try await client.complete(...)` inside a `do/catch`.
- For app code, stale async responses are guarded with UUID request IDs; checks should assert stale-response behavior through injected clients if an injectable client seam is introduced.

**Error Testing:**
```swift
let invalid = #"{"title":"翻译"}"#.data(using: .utf8)!
do {
    _ = try JSONDecoder().decode(StructuredLingobarResult.self, from: invalid)
    throw CheckFailure.failed("structured AI result should reject missing required fields")
} catch is DecodingError {
    // Expected.
}
```

**JSON and Codable Testing:**
- Round-trip Codable fixtures when persistence or AI schema compatibility matters, as in `GrammarResult` fixture checks.
- Use `decodeIfPresent` tolerance intentionally in models like `GrammarResult` and verify defaults in `checkGrammarAIResponseTolerance()`.
- Keep request-body checks close to the public request factory contract; do not assert private implementation details unrelated to HTTP/API behavior.

**Visual Testing:**
```swift
let content = GrammarResultPanel(result: fixture, initialView: tab)
    .frame(width: 720)
    .fixedSize(horizontal: false, vertical: true)
    .environment(\.colorScheme, .dark)
let renderer = ImageRenderer(content: content)
renderer.scale = 1
renderer.proposedSize = ProposedViewSize(width: 720, height: nil)
```
- Check that `cgImage` exists, width is at panel scale, height is contentful, and alpha pixels exceed a minimum threshold.
- Add fixtures before adding render checks for new grammar tabs or states.

## Adding New Checks

**Core Behavior:**
- Add a focused function to `Sources/LingoPeekCoreChecks/main.swift`.
- Use `try check(condition, "contract message")` for each assertion.
- Call the new function in the final `do` block before the success print.

**New UI Render Surface:**
- Add deterministic model data to `Sources/LingobarCore/GrammarUITestFixtures.swift` or another core fixture file.
- Add render assertions to `Sources/LingoPeekGrammarUIChecks/main.swift` with fixed dimensions and nonblank pixel checks.
- Use accessibility identifiers in SwiftUI views when future UI automation will need stable selectors.

**New External Integration:**
- Put request construction and response parsing behind a core client/factory, following `Sources/LingobarCore/OpenAICompatibleClient.swift`.
- Cover request construction in `Sources/LingoPeekCoreChecks/main.swift`.
- Put live connectivity in a separate probe target and require environment variables.

## CI and Release Verification

**GitHub Actions:**
- `.github/workflows/package-app.yml` runs on push and workflow dispatch.
- The workflow runs `swift run LingoPeekCoreChecks`, then `scripts/package_app.sh`, then uploads `dist/LingoPeek.zip`.
- The workflow does not run `swift run LingoPeekGrammarUIChecks` by default.

**Packaging Script:**
- `scripts/package_app.sh` builds with `swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"`, creates an app bundle, lints `Info.plist`, ad-hoc signs by default, verifies codesign, clears xattrs, and zips the bundle.
- Run packaging after app lifecycle, entitlement-like metadata, product name, or bundle metadata changes.

## Verification Checklist

- For source changes: run `swift build --product LingoPeek`.
- For core/domain changes: run `swift run LingoPeekCoreChecks`.
- For grammar visualization or fixtures: run `swift run LingoPeekGrammarUIChecks`.
- For AI provider configuration changes: run request-factory checks via `swift run LingoPeekCoreChecks`; run `LingoPeekAIProbe` only with provided secrets.
- For app packaging changes: run `scripts/package_app.sh`.

---

*Testing analysis: 2026-06-25*
*Update when test patterns change*
