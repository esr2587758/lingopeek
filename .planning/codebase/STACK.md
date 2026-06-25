# Technology Stack

**Analysis Date:** 2026-06-25

## Languages

**Primary:**
- Swift - All native app, core domain, UI, and check-suite code under `Sources/`.
- Swift package tools version 6.0 - Declared by `Package.swift`.

**Secondary:**
- Bash - App bundle packaging in `scripts/package_app.sh`.
- YAML - GitHub Actions packaging workflow in `.github/workflows/package-app.yml`.
- HTML/CSS/JavaScript/JSX - Design prototypes and preview assets under `designs/`; these are not compiled into the native app product.

## Runtime

**Environment:**
- Native macOS app - `Package.swift` targets macOS 14 with `.macOS(.v14)`.
- Generated app bundle minimum OS - `scripts/package_app.sh` writes `LSMinimumSystemVersion` as `14.0`.
- SwiftUI app entry - `Sources/LingoPeekApp/LingoPeekApp.swift`.
- AppKit lifecycle bridge - `Sources/LingoPeekApp/AppDelegate.swift`.
- Menu-bar/accessory-style app packaging - `scripts/package_app.sh` writes `LSUIElement` into the generated `Info.plist`.
- Local inspection toolchain - `swift --version` reported Apple Swift 6.3.2 targeting `arm64-apple-macosx26.0`.

**Package Manager:**
- Swift Package Manager - `Package.swift`.
- Lockfile: Not detected. There is no `Package.resolved`, and `Package.swift` declares no external Swift package dependencies.

## Products

**Executables:**
- `LingoPeek` - Main macOS app target from `Sources/LingoPeekApp/`.
- `LingoPeekAIProbe` - DeepSeek connectivity probe from `Sources/LingoPeekAIProbe/main.swift`.
- `LingoPeekCoreChecks` - Zero-dependency core check suite from `Sources/LingoPeekCoreChecks/main.swift`.
- `LingoPeekGrammarUIChecks` - Grammar UI rendering check executable from `Sources/LingoPeekGrammarUIChecks/main.swift`.

**Libraries:**
- `LingobarCore` - Domain models, settings, local storage, AI clients, parsing, and fixtures in `Sources/LingobarCore/`.
- `LingobarUI` - Shared SwiftUI grammar panel UI in `Sources/LingobarUI/`.

## Frameworks

**Core:**
- SwiftUI - App entry, settings UI, Lingobar root view, and shared UI styling in `Sources/LingoPeekApp/LingoPeekApp.swift`, `Sources/LingoPeekApp/SettingsView.swift`, `Sources/LingoPeekApp/LingobarRootView.swift`, and `Sources/LingobarUI/`.
- AppKit - Menu-bar app lifecycle, windows, pasteboard, events, and workspace links in `Sources/LingoPeekApp/AppDelegate.swift`, `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/LingobarViewModel.swift`, and `Sources/LingoPeekApp/SettingsView.swift`.
- Foundation - HTTP, JSON encoding/decoding, file IO, dates, environment variables, and `UserDefaults` across `Sources/LingobarCore/` and `Sources/LingoPeekApp/`.
- ApplicationServices - Accessibility permission and selected-text reading in `Sources/LingoPeekApp/AppSettings.swift` and `Sources/LingoPeekApp/SelectionReader.swift`.
- Carbon.HIToolbox - Global hotkey registration and keyboard-event constants in `Sources/LingoPeekApp/HotKeyManager.swift`, `Sources/LingoPeekApp/LingobarHotKey.swift`, and `Sources/LingoPeekApp/SelectionReader.swift`.
- Security - Linked in `Package.swift`; no direct `import Security` or Keychain implementation is present in `Sources/`.

**Testing:**
- Custom executable checks - `Sources/LingoPeekCoreChecks/main.swift` validates request factories, settings behavior, setup gates, parsing, fixtures, and local phrase storage without XCTest.
- Custom UI check executable - `Sources/LingoPeekGrammarUIChecks/main.swift` renders grammar UI fixtures without XCTest.
- XCTest/Swift Testing: Not detected. `README.md` states the repository uses zero-dependency Swift executable checks.

**Build/Dev:**
- SwiftPM build/run - `README.md` documents `swift build --product LingoPeek`, `swift run LingoPeek`, `swift run LingoPeekCoreChecks`, and `swift run LingoPeekGrammarUIChecks`.
- App bundle packaging - `scripts/package_app.sh` builds release output, creates `dist/LingoPeek.app`, generates `Info.plist`, ad-hoc signs with `codesign`, verifies signing, and zips `dist/LingoPeek.zip`.
- GitHub Actions packaging - `.github/workflows/package-app.yml` runs `swift run LingoPeekCoreChecks`, packages the app, and uploads `dist/LingoPeek.zip`.
- Local design preview - `README.md` documents serving `designs/` with `python3 -m http.server`.

## Key Dependencies

**Critical:**
- Apple Swift standard libraries and Foundation - Required by every Swift target in `Package.swift`.
- SwiftUI/AppKit - The primary UI stack for `Sources/LingoPeekApp/` and `Sources/LingobarUI/`.
- ApplicationServices Accessibility APIs - Required for setup gating and selected text extraction in `Sources/LingoPeekApp/AppSettings.swift` and `Sources/LingoPeekApp/SelectionReader.swift`.
- Carbon hotkey APIs - Required for global Lingobar shortcut registration in `Sources/LingoPeekApp/HotKeyManager.swift`.
- URLSession - Required for OpenAI-compatible and DeepSeek HTTP calls in `Sources/LingobarCore/OpenAICompatibleClient.swift` and `Sources/LingobarCore/DeepSeekClient.swift`.
- JSONEncoder/JSONDecoder - Required for AI request/response payloads and local phrase persistence in `Sources/LingobarCore/OpenAICompatibleClient.swift`, `Sources/LingobarCore/GrammarResult.swift`, `Sources/LingobarCore/StructuredLingobarResult.swift`, and `Sources/LingobarCore/PhraseStore.swift`.

**Infrastructure:**
- `plutil`, `codesign`, `xattr`, and `ditto` - Used by `scripts/package_app.sh` to validate, sign, scrub, and zip the app bundle.
- GitHub Actions hosted macOS runner - `.github/workflows/package-app.yml` uses `macos-15`.
- `actions/checkout@v4` and `actions/upload-artifact@v4` - CI workflow dependencies in `.github/workflows/package-app.yml`.

## Configuration

**Environment:**
- AI token precedence - `Sources/LingoPeekApp/AppSettings.swift` reads `AI_API_TOKEN`, then `DEEPSEEK_API_KEY`, then the local token from `Sources/LingoPeekApp/LocalTokenStore.swift`.
- AI base URL precedence - `Sources/LingoPeekApp/AppSettings.swift` reads `AI_BASE_URL`, then `DEEPSEEK_BASE_URL`, then `UserDefaults`, then the default from `Sources/LingobarCore/LingobarSettings.swift`.
- AI model precedence - `Sources/LingoPeekApp/AppSettings.swift` reads `AI_MODEL`, then `DEEPSEEK_MODEL`, then `UserDefaults`, then the default from `Sources/LingobarCore/LingobarSettings.swift`.
- DeepSeek probe variables - `Sources/LingoPeekAIProbe/main.swift` reads `DEEPSEEK_API_KEY`, `DEEPSEEK_MODEL`, and `DEEPSEEK_BASE_URL`.
- Fixture/test variables - `Sources/LingoPeekApp/AppSettings.swift` reads `LINGOPEEK_GRAMMAR_FIXTURE` and `LINGOPEEK_GRAMMAR_FIXTURE_ID`; `Sources/LingoPeekApp/AppDelegate.swift` reads `LINGOPEEK_UI_TEST_RESET_SETTINGS`, `LINGOPEEK_RENDER_SETTINGS_SNAPSHOT`, `LINGOPEEK_OPEN_SETTINGS`, and `LINGOPEEK_UI_TEST_MODE`.
- `.env` handling - `.gitignore` ignores `.env` and `.env.*` while allowing `!.env.example`; no `.env` files were detected at analysis time.

**Local Preferences:**
- `UserDefaults` settings - `Sources/LingoPeekApp/AppSettings.swift` persists AI provider, model, base URL, launch/menu preferences, appearance, trigger behavior, default actions, collection target, clipboard behavior, and hotkey settings.
- Local API token storage - `Sources/LingoPeekApp/LocalTokenStore.swift` stores `aiAPIToken` in `UserDefaults`, not Keychain.
- Local phrase storage - `Sources/LingobarCore/PhraseStore.swift` writes `phrases.json` under the user's Application Support `LingoPeek` directory.

**Build:**
- Main manifest - `Package.swift`.
- Packaging script - `scripts/package_app.sh`.
- CI workflow - `.github/workflows/package-app.yml`.
- Generated distribution output - `dist/` is ignored by `.gitignore`.
- SwiftPM build output - `.build/` and `.swiftpm/` are ignored by `.gitignore`.

## Platform Requirements

**Development:**
- macOS with Swift Package Manager.
- Command Line Tools are enough for the documented local SwiftPM commands in `README.md`; `xcodebuild -version` was not available in the local Command Line Tools-only environment during analysis.
- No external package install step is required because `Package.swift` has no third-party dependencies.
- DeepSeek connectivity checks require user-provided secrets through environment variables as documented in `README.md`.

**Production:**
- Distributed as a local macOS `.app` zip produced by `scripts/package_app.sh`.
- Ad-hoc signed by default through `SIGN_IDENTITY=-` in `scripts/package_app.sh`.
- Not Apple Developer ID signed or notarized according to `README.md`.
- Requires macOS Accessibility permission for selected-text workflows, checked in `Sources/LingoPeekApp/AppSettings.swift`.

---

*Stack analysis: 2026-06-25*
*Update after major dependency, platform, packaging, or provider changes*
