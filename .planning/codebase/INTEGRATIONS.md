# External Integrations

**Analysis Date:** 2026-06-25

## APIs & External Services

**External AI:**
- OpenAI-compatible chat completions - Main runtime AI integration for translation, grammar, rewrite, examples, and pronunciation.
  - Integration method: Raw HTTP through `URLSession` in `Sources/LingobarCore/OpenAICompatibleClient.swift`.
  - Request factory: `Sources/LingobarCore/OpenAICompatibleClient.swift` builds `POST` requests to `<baseURL>/chat/completions`.
  - Auth: Bearer token in the `Authorization` header from `AI_API_TOKEN`, `DEEPSEEK_API_KEY`, or local `UserDefaults` token via `Sources/LingoPeekApp/AppSettings.swift` and `Sources/LingoPeekApp/LocalTokenStore.swift`.
  - Payload: JSON body with `model`, `messages`, `temperature`, optional `max_tokens`, optional `response_format`, and `stream: false` from `Sources/LingobarCore/OpenAICompatibleClient.swift`.
  - Structured output: Normal completions request `response_format: {"type":"json_object"}` and `max_tokens: 4096`; validated by `Sources/LingoPeekCoreChecks/main.swift`.
  - Connectivity test: `Sources/LingobarCore/OpenAICompatibleClient.swift` sends a small ping prompt with `max_tokens: 8`, no JSON response format, and a 30-second timeout.
  - Runtime caller: `Sources/LingoPeekApp/LingobarViewModel.swift` calls `OpenAICompatibleClient.complete`, extracts a JSON object through `Sources/LingobarCore/StructuredJSONExtractor.swift`, and decodes either `StructuredLingobarResult` or `GrammarResult`.
  - Rate limits: Not encoded in the repository.

- DeepSeek - Default OpenAI-compatible provider and explicit probe target.
  - Default base URL: `https://api.deepseek.com` in `Sources/LingobarCore/LingobarSettings.swift`.
  - Default model: `deepseek-chat` for app settings in `Sources/LingobarCore/LingobarSettings.swift`.
  - Legacy/probe client: `Sources/LingobarCore/DeepSeekClient.swift` wraps the OpenAI-compatible request factory.
  - Probe executable: `Sources/LingoPeekAIProbe/main.swift` reads `DEEPSEEK_API_KEY`, `DEEPSEEK_MODEL`, and `DEEPSEEK_BASE_URL`.
  - README command: `README.md` documents running `LingoPeekAIProbe` with `DEEPSEEK_API_KEY` and `DEEPSEEK_MODEL`.

- Provider presets - UI settings expose multiple provider choices.
  - Presets live in `Sources/LingobarCore/LingobarSettings.swift`.
  - OpenAI preset uses `https://api.openai.com/v1` and models `gpt-4o` / `gpt-4o-mini`.
  - Custom OpenAI-compatible preset uses `https://api.deepseek.com` and models `deepseek-chat` / `deepseek-reasoner`.
  - Claude/Anthropic preset uses `https://api.anthropic.com/v1` and Claude model names, but no Anthropic SDK, Anthropic-specific HTTP headers, or Anthropic message schema were detected; the active client path still sends OpenAI-compatible chat-completions requests from `Sources/LingobarCore/OpenAICompatibleClient.swift`.

**Payment Processing:**
- Not detected. No Stripe, billing SDK, checkout endpoint, or payment webhook code was found under `Sources/`, `Package.swift`, or `.github/workflows/package-app.yml`.

**Email/SMS:**
- Not detected. No transactional email or SMS provider code was found under `Sources/`.

**Design-only Web Assets:**
- Google Fonts - Some prototype HTML files under `designs/` preconnect to and load fonts from `fonts.googleapis.com`.
  - Example paths: `designs/lingobar-fresh/Lingobar Prototype.html`, `designs/lingobar-interactions/Lingobar Interactions.html`, and `designs/lingobar-grammar/Lingobar Grammar.html`.
  - Runtime impact: Not part of the native Swift app build in `Package.swift`.

## Data Storage

**Databases:**
- Not detected. There is no external database client, ORM, migration directory, or database connection string usage in `Package.swift` or `Sources/`.

**Local File Storage:**
- Application Support JSON store - `Sources/LingobarCore/PhraseStore.swift` persists saved phrases to `phrases.json` under the user's Application Support `LingoPeek` directory.
  - Client: Foundation `FileManager`, `Data(contentsOf:)`, and atomic JSON writes.
  - Format: Pretty-printed, sorted-key JSON with ISO-8601 dates.
  - Runtime caller: `Sources/LingoPeekApp/LingobarViewModel.swift` loads and saves phrases through `PhraseStore`.

**Local Preferences:**
- `UserDefaults` - `Sources/LingoPeekApp/AppSettings.swift` stores model, base URL, provider, launch/menu preferences, appearance, trigger behavior, action order, collection target, clipboard behavior, and hotkey settings.
- Local AI token - `Sources/LingoPeekApp/LocalTokenStore.swift` stores the API token under `aiAPIToken` in `UserDefaults`.
- Keychain: Not detected. `Package.swift` links `Security`, but no Keychain-backed token store was found in `Sources/`.

**File Storage Services:**
- Not detected. No S3, Supabase Storage, CloudKit storage, or remote file upload integration was found.

**Caching:**
- Not detected. No Redis, in-memory response cache, or persistent AI response cache was found.

## Authentication & Identity

**Application User Auth:**
- Not detected. The app has no user account, session, OAuth sign-in, JWT, or backend identity provider code in `Sources/`.

**AI Service Auth:**
- Token source precedence - `Sources/LingoPeekApp/AppSettings.swift` reads `AI_API_TOKEN`, `DEEPSEEK_API_KEY`, then `Sources/LingoPeekApp/LocalTokenStore.swift`.
- Token transport - `Sources/LingobarCore/OpenAICompatibleClient.swift` sends `Authorization: Bearer <token>`.
- Token validation - `Sources/LingobarCore/AIProviderConfiguration.swift` requires non-empty token, valid `http`/`https` base URL, and non-empty model before a client can be created.
- Settings UI - `Sources/LingoPeekApp/SettingsView.swift` saves, clears, and tests API tokens through `AppSettings` and `OpenAICompatibleClient.testConnection`.

**macOS Trust Boundary:**
- Accessibility permission - `Sources/LingoPeekApp/AppSettings.swift` checks `AXIsProcessTrusted()` and includes permission state in `SetupGateStatus`.
- Setup gate - `Sources/LingobarCore/SetupGate.swift` requires both AI access and Accessibility permission before normal Lingobar use.
- Permission settings link - `Sources/LingoPeekApp/SettingsView.swift` and `Sources/LingoPeekApp/LingobarController.swift` open `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
- Selected text access - `Sources/LingoPeekApp/SelectionReader.swift` uses `AXUIElementCreateSystemWide`, focused-element attributes, `kAXSelectedTextAttribute`, and `kAXSelectedTextRangeAttribute`.
- Copy fallback - `Sources/LingoPeekApp/SelectionReader.swift` posts Command-C through `CGEvent` and restores `NSPasteboard` contents after reading selection text.

**OAuth Integrations:**
- Not detected. No Google, GitHub, Apple, or other OAuth client credentials/scopes were found in runtime code.

## Monitoring & Observability

**Error Tracking:**
- Not detected. No Sentry, Crashlytics, Datadog, or similar SDK is declared in `Package.swift` or imported under `Sources/`.

**Analytics:**
- Not detected. No product analytics SDK or event pipeline was found.

**Logs:**
- Local stdout/stderr only - `Sources/LingoPeekAIProbe/main.swift` prints DeepSeek probe results and failures; `Sources/LingoPeekApp/AppDelegate.swift` writes snapshot-render failures to stderr.
- GitHub Actions logs - `.github/workflows/package-app.yml` logs Swift toolchain info, check output, packaging, and upload steps.

## CI/CD & Deployment

**Hosting:**
- Not applicable. The repository builds a native macOS app, not a hosted web service.

**Distribution:**
- Local zip artifact - `scripts/package_app.sh` writes `dist/LingoPeek.app` and `dist/LingoPeek.zip`.
- Signing - `scripts/package_app.sh` uses `codesign --force --deep --sign "$SIGN_IDENTITY"` with default `SIGN_IDENTITY=-` for ad-hoc signing.
- Notarization - Not detected. `README.md` states the package is not Apple Developer ID signed or notarized.

**CI Pipeline:**
- GitHub Actions - `.github/workflows/package-app.yml` runs on every push and on manual `workflow_dispatch`.
- Runner: `macos-15` in `.github/workflows/package-app.yml`.
- Steps: checkout, show toolchain, run `swift run LingoPeekCoreChecks`, run `scripts/package_app.sh`, and upload `dist/LingoPeek.zip`.
- Secrets: None required by the checked-in workflow for default packaging. DeepSeek connectivity requires user-provided environment variables and is not part of `.github/workflows/package-app.yml`.

**Issue Tracker:**
- GitHub Issues - `docs/agents/issue-tracker.md` declares issues and PRDs live in `esr2587758/lingopeek` and should be managed with the `gh` CLI.
- Git remote - The repository remote is `https://github.com/esr2587758/lingopeek.git`.

## Environment Configuration

**Development:**
- Required for basic local build/checks: No secrets. Use `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks` from `README.md`.
- Required for AI-backed runtime results: `AI_API_TOKEN` or `DEEPSEEK_API_KEY`; optional `AI_BASE_URL` / `DEEPSEEK_BASE_URL`; optional `AI_MODEL` / `DEEPSEEK_MODEL`; read in `Sources/LingoPeekApp/AppSettings.swift`.
- Required for `LingoPeekAIProbe`: `DEEPSEEK_API_KEY`; optional `DEEPSEEK_MODEL` and `DEEPSEEK_BASE_URL`; read in `Sources/LingoPeekAIProbe/main.swift`.
- Secrets location: Environment variables or local `UserDefaults` via `Sources/LingoPeekApp/LocalTokenStore.swift`.
- Secret-bearing files: `.gitignore` ignores `.env` and `.env.*` while allowing `!.env.example`; no `.env` files were detected at analysis time.
- Fixture mode: `LINGOPEEK_GRAMMAR_FIXTURE=1` and `LINGOPEEK_GRAMMAR_FIXTURE_ID=<id>` in `Sources/LingoPeekApp/AppSettings.swift`.

**Staging:**
- Not detected. No staging-specific base URL, workflow, bundle identifier, or deployment config was found.

**Production:**
- User-local app configuration through Settings and `UserDefaults` in `Sources/LingoPeekApp/AppSettings.swift`.
- App bundle metadata is generated by `scripts/package_app.sh` from `APP_NAME`, `PRODUCT_NAME`, `BUNDLE_IDENTIFIER`, `APP_VERSION`, `BUILD_NUMBER`, `CONFIGURATION`, and `SIGN_IDENTITY`.
- External AI availability depends on the configured OpenAI-compatible provider and token.

## Webhooks & Callbacks

**Incoming:**
- Not detected. There is no HTTP server, webhook route, or callback endpoint in this native macOS package.

**Outgoing:**
- Not detected. The app sends direct AI completion requests through `Sources/LingobarCore/OpenAICompatibleClient.swift`; no outgoing webhook subscriptions or retry queues were found.

---

*Integration audit: 2026-06-25*
*Update when adding/removing providers, storage services, telemetry, CI release paths, or auth mechanisms*
