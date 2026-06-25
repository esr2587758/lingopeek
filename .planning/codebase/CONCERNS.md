# Codebase Concerns

**Analysis Date:** 2026-06-25

## Tech Debt

**Large SwiftUI surface files:**
- Issue: Major view composition, AppKit bridges, selection UI, sizing constants, and interaction handlers live in a few large files: `Sources/LingoPeekApp/LingobarRootView.swift` (1604 lines), `Sources/LingoPeekApp/SettingsView.swift` (1494 lines), and `Sources/LingobarUI/GrammarResultPanel.swift` (1023 lines).
- Why: The native prototype is implemented close to the design surfaces, with many private view builders and AppKit adapters colocated in each surface.
- Impact: Small behavior changes can touch unrelated rendering, sizing, selection, and input code; merge conflicts and visual regressions are likely around `Sources/LingoPeekApp/LingobarRootView.swift` and `Sources/LingoPeekApp/SettingsView.swift`.
- Fix approach: Extract behavior-preserving subviews and coordinators by boundary: input text bridge, selectable result text, result rendering per `LanguageAction`, settings AI form, settings hotkey recorder, and grammar diagram widgets. Lock each extraction with `swift run LingoPeekCoreChecks` and `swift run LingoPeekGrammarUIChecks`.

**Duplicate panel sizing rules:**
- Issue: Panel sizes are hard-coded in `Sources/LingoPeekApp/LingobarController.swift:8` through `Sources/LingoPeekApp/LingobarController.swift:14`, while matching root view heights are hard-coded in `Sources/LingoPeekApp/LingobarRootView.swift:435` through `Sources/LingoPeekApp/LingobarRootView.swift:451`.
- Why: AppKit window management and SwiftUI content layout are controlled from separate layers.
- Impact: A UI size change can update one side and leave the other stale, causing clipped content, excessive empty space, or inconsistent grammar/input panel sizes.
- Fix approach: Move panel sizing into one shared model or one controller-owned layout table, then make `LingobarRootView` consume the same sizing source.

**Settings model exposes preferences before platform behavior exists:**
- Issue: `Sources/LingoPeekApp/SettingsView.swift:233` exposes "launch at login", `Sources/LingoPeekApp/SettingsView.swift:455` exposes selection-trigger and floating-button toggles, and `Sources/LingoPeekApp/AppSettings.swift:176` through `Sources/LingoPeekApp/AppSettings.swift:247` persists them, but no `ServiceManagement`, global selection monitor, or floating-button implementation appears in `Sources/`.
- Why: Settings UI and persisted preferences are ahead of the platform integrations.
- Impact: Users and future agents can assume these settings work when they only change `UserDefaults`.
- Fix approach: Either implement each integration behind the existing settings or hide/disable the controls until the platform behavior exists.

**Provider model outpaces transport model:**
- Issue: `Sources/LingobarCore/LingobarSettings.swift:74` exposes Claude, OpenAI, and OpenAI-compatible providers, but `Sources/LingoPeekApp/AppSettings.swift:277` always creates `OpenAICompatibleClient`, which posts OpenAI chat-completions JSON in `Sources/LingobarCore/OpenAICompatibleClient.swift:75`.
- Why: The product language is provider-neutral, while the transport layer is OpenAI-compatible only.
- Impact: Provider-specific additions can silently route through the wrong protocol, especially Anthropic Claude.
- Fix approach: Keep the picker limited to OpenAI-compatible providers or introduce provider-specific clients with separate request factories and tests.

**Local deterministic engine remains in source but not product path:**
- Issue: `Sources/LingobarCore/LocalLanguageEngine.swift` contains deterministic fallback-style language results, while `docs/adr/0001-ai-required-language-results.md` and `Sources/LingoPeekApp/LingobarViewModel.swift:214` require AI configuration for language actions.
- Why: Local content supports checks and prototype fixtures.
- Impact: New code can accidentally reintroduce local fallback behavior that violates the AI-required product contract.
- Fix approach: Keep `LocalLanguageEngine` test-only or rename/document it as fixtures, and ensure app code never calls it for user-facing results.

## Known Bugs

**Claude provider selection cannot work through the current client:**
- Symptoms: Selecting `Claude (Anthropic)` in settings produces a base URL of `https://api.anthropic.com/v1` and a Claude model from `Sources/LingobarCore/LingobarSettings.swift:81` through `Sources/LingobarCore/LingobarSettings.swift:108`, then sends an OpenAI-style `/chat/completions` request from `Sources/LingobarCore/OpenAICompatibleClient.swift:86`.
- Trigger: Choose Claude in `Sources/LingoPeekApp/SettingsView.swift:277`, save settings, and test or run a language action.
- Workaround: Use the custom OpenAI-compatible provider path with a provider that supports OpenAI chat-completions.
- Root cause: `AppSettings.makeAIClient()` in `Sources/LingoPeekApp/AppSettings.swift:277` ignores `LingobarAIProvider` and always returns `OpenAICompatibleClient`.
- Fix approach: Hide Claude until an Anthropic client exists, or route Claude to a dedicated request factory with Anthropic headers and message schema.

**Repeated hotkey does not implement documented toggle behavior:**
- Symptoms: The product guide says pressing the hotkey again closes or refreshes based on selection state, but the registered hotkey calls `presentFromHotKey()` in `Sources/LingoPeekApp/LingobarController.swift:40`, which always calls `present(captureSelectionByCopying: true)` through `Sources/LingoPeekApp/LingobarController.swift:104`.
- Trigger: Open Lingobar with the global hotkey, then press the same hotkey again.
- Workaround: Use `Esc`, the close button, or the menu Hide command.
- Root cause: `LingobarController.toggle()` exists at `Sources/LingoPeekApp/LingobarController.swift:92`, but the hotkey path does not call it or compare the current selection.
- Fix approach: Make the hotkey path evaluate panel visibility and current selection, then close, focus input, or refresh according to `docs/interaction-guide.md:164`.

**AI generation is hidden, not cancelled, on close:**
- Symptoms: Closing the panel while an AI request is loading hides the UI but does not cancel the underlying `URLSession` request.
- Trigger: Start a slow grammar request, then press `Esc` or close the panel.
- Workaround: Wait for the request to complete; stale results are guarded by `activeAIRequestID` when another request starts.
- Root cause: `Sources/LingoPeekApp/LingobarViewModel.swift:229` creates an untracked `Task`, while `Sources/LingoPeekApp/LingobarController.swift:210` only hides the panel on cancel.
- Fix approach: Store the active `Task`, cancel it on close/action switch, and make `OpenAICompatibleClient.complete` cancellation visible in UI state.

**Error recovery rows are not wired as actions:**
- Symptoms: AI errors render rows and chips for retry/settings from `Sources/LingoPeekApp/LingobarViewModel.swift:414`, but the result footer only exposes Copy and Collect in `Sources/LingoPeekApp/LingobarRootView.swift:385`.
- Trigger: Use an invalid token, invalid model, unsupported provider, or parse-breaking AI response.
- Workaround: Manually trigger the action again or open Settings through the top gear/setup panel.
- Root cause: `LingobarResult` carries error recovery text but not action callbacks or typed recovery actions.
- Fix approach: Add typed result actions for retry and open settings, then render them in the footer or error panel.

**README describes a local fallback that the app gate does not provide:**
- Symptoms: `README.md:60` says the app uses deterministic local fallback content without `DEEPSEEK_API_KEY`, while `Sources/LingoPeekApp/LingobarViewModel.swift:214` returns an AI setup error when no usable AI client exists.
- Trigger: Follow the README and run without a token.
- Workaround: Configure AI settings or use grammar fixture environment variables for deterministic grammar rendering.
- Root cause: Documentation drift between `README.md` and `docs/adr/0001-ai-required-language-results.md`.
- Fix approach: Update `README.md` to describe the setup gate and test fixtures instead of user-facing fallback.

## Security Considerations

**API token stored in UserDefaults:**
- Risk: `Sources/LingoPeekApp/LocalTokenStore.swift:17` stores the API token under `aiAPIToken` in `UserDefaults`, which is local preference storage rather than protected secret storage.
- Current mitigation: `docs/product-brief.md:76` explicitly accepts UserDefaults for the self-use MVP, `Sources/LingoPeekApp/SettingsView.swift:330` uses a SecureField by default, and no `.env*` files were detected in the repository.
- Recommendations: Move tokens to Keychain before broader distribution; keep `UserDefaults` only for non-secret provider/model/base URL values.

**Custom base URL permits plaintext HTTP:**
- Risk: `Sources/LingobarCore/AIProviderConfiguration.swift:26` accepts both `http` and `https`, and `Sources/LingobarCore/OpenAICompatibleClient.swift:91` sends the bearer token to the configured endpoint.
- Current mitigation: Built-in provider defaults in `Sources/LingobarCore/LingobarSettings.swift:104` through `Sources/LingobarCore/LingobarSettings.swift:108` use HTTPS.
- Recommendations: Require HTTPS by default; allow `http://localhost` only behind an explicit development exception.

**Selected text and clipboard-derived text are sent to the configured AI provider:**
- Risk: `Sources/LingoPeekApp/LingobarController.swift:141` captures selected text, `Sources/LingoPeekApp/LingobarViewModel.swift:49` immediately starts an AI request for selection mode, and `Sources/LingoPeekApp/LingobarViewModel.swift:53` can auto-fill input from the clipboard when that setting is enabled.
- Current mitigation: Normal use is blocked until AI settings and Accessibility permission pass `Sources/LingobarCore/SetupGate.swift:10`.
- Recommendations: Add clear first-run privacy copy, provider display in the panel, and an option to require manual submit before sending selected text.

**Provider error bodies can surface raw response text:**
- Risk: `Sources/LingobarCore/OpenAICompatibleClient.swift:43` and `Sources/LingobarCore/OpenAICompatibleClient.swift:62` store server response bodies in `OpenAICompatibleError.server`, and `Sources/LingoPeekApp/SettingsView.swift:809` can display compacted error text in the settings connection test.
- Current mitigation: Main Lingobar error copy only shows HTTP status in `Sources/LingoPeekApp/LingobarViewModel.swift:435`; the settings message is truncated to 140 characters at `Sources/LingoPeekApp/SettingsView.swift:814`.
- Recommendations: Redact token-like substrings and provider payloads before showing or logging errors.

**Global pasteboard fallback can overwrite unrelated clipboard changes:**
- Risk: `Sources/LingoPeekApp/SelectionReader.swift:60` snapshots the general pasteboard, sends global Command-C at `Sources/LingoPeekApp/SelectionReader.swift:84`, then restores the snapshot at `Sources/LingoPeekApp/SelectionReader.swift:76`.
- Current mitigation: A pasteboard snapshot is restored after copied text is read.
- Recommendations: Treat pasteboard fallback as privileged behavior: keep it opt-in where possible, add tests around non-text pasteboard contents, and avoid restoring if the pasteboard changed for reasons unrelated to the app's copy event.

## Performance Bottlenecks

**Non-streaming AI response path:**
- Problem: Language actions wait for a complete response before rendering because `Sources/LingobarCore/OpenAICompatibleClient.swift:102` sets `stream: false` and `Sources/LingoPeekApp/LingobarViewModel.swift:231` waits for `complete`.
- Measurement: Static bounds only: main requests allow `timeoutInterval = 120` in `Sources/LingobarCore/OpenAICompatibleClient.swift:89`; grammar loading copy in `Sources/LingoPeekApp/LingobarRootView.swift:781` tells users grammar usually takes 15-20 seconds.
- Cause: MVP rule in `docs/product-brief.md:89` chooses full-response rendering over streaming.
- Improvement path: Keep non-streaming for MVP if desired, but add cancellation, shorter action-specific timeouts, and optional streaming/partial rendering for grammar.

**Selection fallback blocks the main interaction path:**
- Problem: `Sources/LingoPeekApp/SelectionReader.swift:66` spins the run loop until pasteboard change or a 0.22 second deadline while selection capture is called from the main-actor controller path in `Sources/LingoPeekApp/LingobarController.swift:141`.
- Measurement: Static bound: up to 0.22 seconds per fallback attempt before Lingobar can present input/no-selection state.
- Cause: Clipboard fallback relies on global Command-C and pasteboard change polling.
- Improvement path: Prefer Accessibility-selected text when available, move copy fallback behind a visible loading state, and make the timeout configurable/tested.

**Grammar visualization renders several custom layout surfaces in one panel:**
- Problem: `Sources/LingobarUI/GrammarResultPanel.swift` combines tab state, dependency drawing, recursive tree rendering, custom wrapping layout, and hover chrome in one 1023-line file.
- Measurement: No runtime timing is recorded; `Sources/LingoPeekGrammarUIChecks/main.swift:49` renders all tabs for two long fixtures and only checks nonblank image dimensions.
- Cause: Native recreation of a detailed grammar mockup uses SwiftUI layout and custom Canvas-style drawing.
- Improvement path: Add render-time assertions or lightweight benchmarks for the grammar fixtures before adding more grammar tabs or denser result models.

**Phrase storage rewrites the full collection file:**
- Problem: `Sources/LingobarCore/PhraseStore.swift:22` loads all phrases and `Sources/LingobarCore/PhraseStore.swift:33` writes the whole JSON array on each save.
- Measurement: No collection-size benchmark is present.
- Cause: The MVP uses a simple local JSON file.
- Improvement path: Keep the JSON store for small local collections; introduce pagination, compaction, or SQLite only when collection size makes full rewrites measurable.

## Fragile Areas

**Accessibility selection reading:**
- Why fragile: `Sources/LingoPeekApp/SelectionReader.swift:25`, `Sources/LingoPeekApp/SelectionReader.swift:44`, and `Sources/LingoPeekApp/SelectionReader.swift:51` use force casts for Accessibility values returned by system APIs.
- Common failures: Unsupported focused elements, permission edge cases, or unexpected AX value types can crash instead of falling back to input mode.
- Safe modification: Replace force casts with conditional casts and preserve the existing nil/fallback behavior.
- Test coverage: No automated checks cover `SelectionReader`; `Sources/LingoPeekCoreChecks/main.swift` focuses on core models and request factories.

**AI schema contract:**
- Why fragile: `Sources/LingoPeekApp/LingobarViewModel.swift:276` embeds JSON schemas in prompt strings, `Sources/LingobarCore/StructuredLingobarResult.swift:1` requires strict generic result fields, and `Sources/LingobarCore/GrammarResult.swift` contains custom decoding defaults for grammar.
- Common failures: Provider output drift causes decoding errors and user-visible format failures.
- Safe modification: Add fixtures for each action's real expected JSON, validate prompts against those fixtures, and keep schema changes synchronized with UI renderers.
- Test coverage: `Sources/LingoPeekCoreChecks/main.swift:327` covers one generic structured result and `Sources/LingoPeekCoreChecks/main.swift:471` covers one tolerant grammar response; there are no fixtures for every language action.

**Carbon global hotkey bridge:**
- Why fragile: `Sources/LingoPeekApp/HotKeyManager.swift:4` is `@unchecked Sendable`, stores Carbon event references manually, and calls `MainActor.assumeIsolated` in `Sources/LingoPeekApp/HotKeyManager.swift:76`.
- Common failures: Re-registration, lifetime, or threading mistakes can leave stale event handlers or route callbacks off the intended actor.
- Safe modification: Keep registration changes small, always unregister the previous hotkey, and add manual verification on macOS after touching `HotKeyManager`.
- Test coverage: `Sources/LingoPeekCoreChecks/main.swift:82` checks shortcut matching logic, but no automated test covers Carbon registration.

**Inline selectable text and input AppKit bridges:**
- Why fragile: `Sources/LingoPeekApp/LingobarRootView.swift:1223` and `Sources/LingoPeekApp/LingobarRootView.swift:1379` bridge `NSTextView` into SwiftUI with custom measurement, selection toolbar positioning, marked-text handling, and deferred focus.
- Common failures: IME composition bugs, wrong toolbar position, selection loops, lost focus, or clipped text after sizing changes.
- Safe modification: Isolate bridge changes, test Chinese IME marked text manually, and keep `sizeThatFits` behavior aligned with panel width.
- Test coverage: No zero-dependency check exercises these AppKit bridges.

**Generated packaging plist:**
- Why fragile: `scripts/package_app.sh:43` writes `Info.plist` from shell variables, then signs the app ad hoc at `scripts/package_app.sh:81`.
- Common failures: Bundle metadata, login item support, entitlements, accessibility trust prompts, or quoting bugs can appear only in packaged app runs.
- Safe modification: Validate package changes with `scripts/package_app.sh`, `plutil -lint`, `codesign --verify`, and a first-launch smoke test.
- Test coverage: `.github/workflows/package-app.yml:31` runs packaging, but no workflow launches the packaged app.

## Scaling Limits

**Local phrase collection JSON:**
- Current capacity: Not measured; the store reads and writes a single `phrases.json` file in Application Support from `Sources/LingobarCore/PhraseStore.swift:16`.
- Limit: Large collections make every save rewrite the whole file and every load decode the full array.
- Symptoms at limit: Slower collection actions, longer startup/load time, and higher risk of visible UI pauses if save/load paths grow.
- Scaling path: Measure with generated phrase counts, then add lazy loading or a small database only when the JSON approach reaches a real limit.

**Concurrent AI requests:**
- Current capacity: One visible result path is guarded by `activeAIRequestID` in `Sources/LingoPeekApp/LingobarViewModel.swift:25`, but older network requests continue in the background.
- Limit: Rapid action switching can create multiple simultaneous provider requests.
- Symptoms at limit: Extra provider cost, higher latency, and possible rate-limit responses.
- Scaling path: Track and cancel the active task, debounce repeated actions, and expose retry after rate-limit responses.

**Single-user local app boundary:**
- Current capacity: Product docs define a local self-use macOS app in `docs/product-brief.md:52`.
- Limit: No account model, sync model, remote storage, or multi-device conflict handling exists.
- Symptoms at limit: Collection and settings remain bound to one macOS user profile.
- Scaling path: Keep local-first boundaries explicit; add sync only as a separate phase with storage, auth, and conflict-resolution design.

## Dependencies at Risk

**OpenAI-compatible JSON mode:**
- Risk: `Sources/LingobarCore/OpenAICompatibleClient.swift:101` requests `response_format: {"type":"json_object"}`, which not every OpenAI-compatible endpoint supports.
- Impact: Custom providers can fail even when token, base URL, and model are syntactically valid.
- Migration plan: Detect provider capability during connection test, offer a no-response-format fallback only if structured JSON extraction remains reliable, or limit supported providers.

**Carbon hotkey APIs:**
- Risk: `Sources/LingoPeekApp/HotKeyManager.swift` uses Carbon `RegisterEventHotKey`, which is mature but older macOS API surface.
- Impact: Future macOS behavior changes or sandboxing/distribution constraints can affect global hotkey reliability.
- Migration plan: Keep the wrapper isolated and evaluate a modern event-monitor or Shortcut-style integration if distribution requirements expand.

**Ad hoc packaging and no notarization:**
- Risk: `README.md:36` documents ad hoc signing and no notarization.
- Impact: Downloaded artifacts can be blocked by Gatekeeper or require manual quarantine removal from `README.md:38`.
- Migration plan: For distribution beyond local self-use, add Developer ID signing, notarization, hardened runtime, and entitlement review.

## Missing Critical Features

**Launch at login integration:**
- Problem: Settings expose and persist launch-at-login state in `Sources/LingoPeekApp/SettingsView.swift:233` and `Sources/LingoPeekApp/AppSettings.swift:176`, but no `ServiceManagement` integration exists in `Sources/`.
- Current workaround: Start the app manually.
- Blocks: The "long-term local utility" experience described in `docs/product-brief.md:52` is weaker when the app does not actually register as a login item.
- Implementation complexity: Medium; use `SMAppService` or a packaging-compatible login item flow and test packaged app behavior.

**Selection floating button and automatic selection trigger:**
- Problem: Settings expose "select text to wake" and "show selection float button" in `Sources/LingoPeekApp/SettingsView.swift:455`, but the app only presents on launch/menu/hotkey paths in `Sources/LingoPeekApp/LingobarController.swift:38`.
- Current workaround: Press the global hotkey after selecting text.
- Blocks: The interaction guide's "selected text plus floating button" path in `docs/interaction-guide.md:25`.
- Implementation complexity: Medium to high; macOS-wide selection observation and non-disruptive floating affordances need careful Accessibility and focus handling.

**Pronunciation playback action:**
- Problem: `Sources/LingoPeekApp/LingobarRootView.swift:569` renders a play icon for pronunciation, but no `AVSpeechSynthesizer`, `NSSpeechSynthesizer`, or button action is wired in `Sources/`.
- Current workaround: The AI result can show pronunciation guidance text.
- Blocks: The product rule in `docs/product-brief.md:103` that pronunciation uses system reading/playback.
- Implementation complexity: Low to medium; add speech playback state and tests around action availability.

**Action-specific contextual "more" behavior:**
- Problem: `LanguageAction.moreActionTitle` exists in `Sources/LingobarCore/LanguageAction.swift:107`, but the result footer in `Sources/LingoPeekApp/LingobarRootView.swift:385` renders only Copy and Collect.
- Current workaround: Users can manually choose another toolbar action.
- Blocks: Contextual follow-up actions such as retry, more examples, more versions, or slow playback from `docs/interaction-guide.md:122`.
- Implementation complexity: Medium; requires typed follow-up actions and UI placement.

## Test Coverage Gaps

**No XCTest or Swift Testing target:**
- What's not tested: AppKit controller behavior, Accessibility selection reading, global hotkey registration, settings window behavior, and packaged app launch.
- Risk: Platform regressions can pass `Sources/LingoPeekCoreChecks/main.swift` because it exercises model and request-factory logic only.
- Priority: High.
- Difficulty to test: Command Line Tools limitations are documented in `README.md:66`; use executable checks, snapshot renders, and manual smoke scripts until full test frameworks are available.

**CI omits grammar UI checks:**
- What's not tested: `.github/workflows/package-app.yml:28` runs `swift run LingoPeekCoreChecks`, but does not run `swift run LingoPeekGrammarUIChecks` from `README.md:70`.
- Risk: Native grammar panel rendering regressions can land even though `Sources/LingoPeekGrammarUIChecks/main.swift` exists.
- Priority: Medium.
- Difficulty to test: The check uses SwiftUI `ImageRenderer`; validate it is stable on `macos-15`, then add it to CI.

**Selection and pasteboard behavior untested:**
- What's not tested: `Sources/LingoPeekApp/SelectionReader.swift` force-cast behavior, global Command-C fallback, pasteboard snapshot restoration, and timeout paths.
- Risk: Accessibility edge cases can crash or corrupt the user's clipboard.
- Priority: High.
- Difficulty to test: Requires macOS UI permissions or injectable wrappers around AX, CGEvent, and NSPasteboard APIs.

**AI error and recovery paths under-tested:**
- What's not tested: Invalid provider selection, unsupported JSON mode, HTTP error body redaction, task cancellation, timeout, and retry/settings actions.
- Risk: Users can get stuck on opaque or non-actionable errors.
- Priority: High.
- Difficulty to test: Needs URLProtocol-backed `URLSession` injection tests and typed UI recovery actions.

**Settings-to-platform integration untested:**
- What's not tested: Launch-at-login, selection trigger, floating button, menu bar visibility, hotkey registration failure, and packaged app metadata.
- Risk: Settings can appear functional while only changing `UserDefaults`.
- Priority: Medium.
- Difficulty to test: Requires packaging-aware smoke tests and platform abstraction around macOS services.

---

*Concerns audit: 2026-06-25*
*Update as issues are fixed or new ones discovered*
