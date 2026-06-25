# Codebase Structure

**Analysis Date:** 2026-06-25

## Directory Layout

```text
LingoPeek/
├── AGENTS.md                         # Repository-specific agent instructions
├── CONTEXT.md                        # Product/domain vocabulary and boundaries
├── Package.swift                     # SwiftPM manifest, products, targets, framework links
├── README.md                         # Build, run, package, verification, and preview guide
├── TODO.md                           # Local task notes
├── Sources/                          # SwiftPM source targets
│   ├── LingoPeekApp/                 # Main macOS app executable target
│   ├── LingobarCore/                 # Foundation-only core/domain target
│   ├── LingobarUI/                   # Reusable SwiftUI UI library target
│   ├── LingoPeekCoreChecks/          # Zero-dependency core check executable
│   ├── LingoPeekGrammarUIChecks/     # Grammar UI render check executable
│   └── LingoPeekAIProbe/             # Optional live AI connectivity probe
├── Tests/                            # Empty SwiftPM test directory
├── docs/                             # Product specs, ADRs, and agent docs
│   ├── adr/                          # Architecture decision records
│   └── agents/                       # Repo instructions for issue/triage/domain tracking
├── designs/                          # HTML/JSX prototype artifacts and previews
├── scripts/                          # Local packaging scripts
├── .github/workflows/                # GitHub Actions packaging workflow
├── .planning/codebase/               # GSD-generated codebase mapping docs
├── .claude/                          # Local editor/agent launch config
├── .omx/                             # Ignored local OMX runtime state
├── .build/                           # Ignored SwiftPM build output
├── .swiftpm/                         # Ignored SwiftPM local metadata
└── dist/                             # Ignored packaged app artifacts
```

## Directory Purposes

**`Sources/LingoPeekApp/`:**
- Purpose: Main native macOS app target and all AppKit-specific orchestration.
- Contains: app entry, delegate, controllers, view model, settings facade, selection reader, hotkey manager, SwiftUI app views, AppKit bridges, and snapshot renderer.
- Key files: `Sources/LingoPeekApp/LingoPeekApp.swift`, `Sources/LingoPeekApp/AppDelegate.swift`, `Sources/LingoPeekApp/LingobarController.swift`, `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekApp/LingobarRootView.swift`, `Sources/LingoPeekApp/SettingsView.swift`, `Sources/LingoPeekApp/AppSettings.swift`.
- Subdirectories: None; target files are flat.
- Add app-shell code here when it depends on AppKit, ApplicationServices, Carbon, SwiftUI hosting, `UserDefaults`, pasteboard, or macOS windows.

**`Sources/LingobarCore/`:**
- Purpose: Dependency-light domain model and AI contract target.
- Contains: core enums, result structs, grammar result schema, settings snapshot, setup gate, OpenAI-compatible client/request factory, DeepSeek compatibility wrapper, JSON extraction, fixture data, local fallback content, and JSON phrase storage.
- Key files: `Sources/LingobarCore/LanguageAction.swift`, `Sources/LingobarCore/LingobarResult.swift`, `Sources/LingobarCore/GrammarResult.swift`, `Sources/LingobarCore/LingobarSettings.swift`, `Sources/LingobarCore/OpenAICompatibleClient.swift`, `Sources/LingobarCore/AIProviderConfiguration.swift`, `Sources/LingobarCore/PhraseStore.swift`.
- Subdirectories: None; target files are flat.
- Add reusable business rules and Codable contracts here when they can compile with `Foundation` only.

**`Sources/LingobarUI/`:**
- Purpose: Reusable UI library shared by the app and UI check executables.
- Contains: native grammar visualization panel and shared Lingobar color/style primitives.
- Key files: `Sources/LingobarUI/GrammarResultPanel.swift`, `Sources/LingobarUI/Style.swift`.
- Subdirectories: None.
- Add UI here only when it should be reusable outside `LingoPeekApp`, especially grammar visualization components backed by `LingobarCore`.

**`Sources/LingoPeekCoreChecks/`:**
- Purpose: Zero-dependency executable check suite for core behavior.
- Contains: `Sources/LingoPeekCoreChecks/main.swift`.
- Key files: `Sources/LingoPeekCoreChecks/main.swift`.
- Subdirectories: None.
- Add non-UI behavioral checks here for actions, settings, AI request payloads, parsing, grammar contracts, and persistence.

**`Sources/LingoPeekGrammarUIChecks/`:**
- Purpose: Render-based grammar UI verification executable.
- Contains: `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Key files: `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Subdirectories: None.
- Add grammar UI render assertions here when `GrammarResultPanel` or `GrammarVizView` changes.

**`Sources/LingoPeekAIProbe/`:**
- Purpose: Optional live provider connectivity probe.
- Contains: `Sources/LingoPeekAIProbe/main.swift`.
- Key files: `Sources/LingoPeekAIProbe/main.swift`.
- Subdirectories: None.
- Keep this probe secret-free by reading provider credentials from environment variables only.

**`Tests/`:**
- Purpose: Placeholder SwiftPM test tree.
- Contains: No files.
- Key files: Not applicable.
- Subdirectories: `Tests/LingoPeekAppUITests/` and `Tests/LingobarCoreTests/` directories are present but empty.
- Use executable check targets under `Sources/` unless the repo adds XCTest or Swift Testing support.

**`docs/`:**
- Purpose: Product, interaction, settings, grammar, and agent documentation.
- Contains: product briefs/specs plus ADR and agent subdirectories.
- Key files: `docs/product-brief.md`, `docs/interaction-guide.md`, `docs/lingobar-settings-spec.md`, `docs/lingobar-grammar-spec.md`, `docs/lingobar-interactions-spec.md`.
- Subdirectories: `docs/adr/` for decision records and `docs/agents/` for repo agent guidance.
- Read `CONTEXT.md` and relevant docs before changing user-facing copy or product behavior.

**`docs/adr/`:**
- Purpose: Architecture decision records.
- Contains: Markdown ADRs with four-digit numeric prefixes.
- Key files: `docs/adr/0001-ai-required-language-results.md`, `docs/adr/0002-openai-compatible-ai-settings.md`, `docs/adr/0003-structured-ai-results.md`, `docs/adr/0004-grammar-specific-structured-results.md`, `docs/adr/0005-native-grammar-visualization.md`.
- Subdirectories: None.
- Add ADRs here for product or architecture decisions that future agents should not rediscover.

**`docs/agents/`:**
- Purpose: Repo-specific support docs for agent workflows.
- Contains: issue tracker, triage labels, and domain pointers.
- Key files: `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, `docs/agents/domain.md`.
- Subdirectories: None.
- Update these only when agent workflow contracts change.

**`designs/`:**
- Purpose: Prototype and visual reference artifacts.
- Contains: HTML pages, JSX component/data files, JSON metadata, and preview images for Lingobar product, grammar, settings, collection, navigation, interactions, and related explorations.
- Key files: `designs/lingobar-product/Lingobar Prototype.html`, `designs/lingobar-grammar/Lingobar Grammar.html`, `designs/lingobar-settings/Lingobar Settings.html`, `designs/lingobar-grammar-viz/Lingobar Grammar Viz.html`.
- Subdirectories: Feature/prototype folders such as `designs/lingobar-product/`, `designs/lingobar-grammar/`, `designs/lingobar-settings/`, and `designs/lingobar-collection/`.
- Treat these as references for native UI work, not as app runtime code.

**`scripts/`:**
- Purpose: Local automation scripts.
- Contains: `scripts/package_app.sh`.
- Key files: `scripts/package_app.sh`.
- Subdirectories: None.
- Add scripts here only for repo-local workflows that should be runnable from the root.

**`.github/workflows/`:**
- Purpose: CI automation.
- Contains: packaging workflow.
- Key files: `.github/workflows/package-app.yml`.
- Subdirectories: None.
- Update this when build/check/package commands or artifact behavior changes.

**`.planning/codebase/`:**
- Purpose: GSD codebase mapping artifacts for future planning/execution agents.
- Contains: `ARCHITECTURE.md` and `STRUCTURE.md` from this mapping task, plus other mapper outputs when produced.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.
- Subdirectories: None.
- Keep these docs current when architecture or directory layout changes.

**Ignored/local directories:**
- Purpose: Machine-specific runtime, build, and distribution output.
- Contains: `.omx/`, `.build/`, `.swiftpm/`, `dist/`, `DerivedData/`, and `xcuserdata/` paths.
- Key files: `.gitignore`.
- Subdirectories: Generated by tools.
- Do not commit generated artifacts or runtime state from these directories.

## Key File Locations

**Entry Points:**
- `Sources/LingoPeekApp/LingoPeekApp.swift` - SwiftUI `@main` app entry and settings scene.
- `Sources/LingoPeekApp/AppDelegate.swift` - macOS lifecycle, environment test modes, activation policy, and controller startup.
- `Sources/LingoPeekCoreChecks/main.swift` - core behavior check executable entry.
- `Sources/LingoPeekGrammarUIChecks/main.swift` - grammar UI render check executable entry.
- `Sources/LingoPeekAIProbe/main.swift` - live DeepSeek-compatible probe entry.

**Configuration:**
- `Package.swift` - Swift tools version, macOS platform, products, targets, target dependencies, and linked frameworks.
- `.gitignore` - ignored build, runtime, env, Xcode, and distribution artifacts.
- `.github/workflows/package-app.yml` - macOS CI workflow that runs `swift run LingoPeekCoreChecks` and `scripts/package_app.sh`.
- `AGENTS.md` - repo-specific coding and verification instructions.
- `CONTEXT.md` - domain vocabulary and product boundaries.

**App Shell and macOS Integration:**
- `Sources/LingoPeekApp/LingobarController.swift` - floating panel lifecycle, setup routing, selection routing, menu bar item, hotkey observation, panel placement, and shortcut handling.
- `Sources/LingoPeekApp/SettingsWindowController.swift` - custom borderless settings window and drag/close key handling.
- `Sources/LingoPeekApp/HotKeyManager.swift` - Carbon global hotkey registration and callback bridge.
- `Sources/LingoPeekApp/LingobarHotKey.swift` - hotkey representation and display string mapping.
- `Sources/LingoPeekApp/SelectionReader.swift` - Accessibility selected text reader and pasteboard-copy fallback.
- `Sources/LingoPeekApp/WindowDragHandle.swift` - AppKit drag handle for the floating panel.

**State and Persistence:**
- `Sources/LingoPeekApp/LingobarViewModel.swift` - Lingobar observable state, mode/action workflows, AI prompting/parsing, copy/collect actions, and status handling.
- `Sources/LingoPeekApp/AppSettings.swift` - app settings facade over environment variables, `UserDefaults`, Accessibility status, AI client creation, and notifications.
- `Sources/LingoPeekApp/LocalTokenStore.swift` - local API token read/write/delete using `UserDefaults`.
- `Sources/LingobarCore/PhraseStore.swift` - JSON phrase persistence in Application Support with atomic writes.

**Core Logic and Contracts:**
- `Sources/LingobarCore/LanguageAction.swift` - action identity, titles, symbols, shortcuts, default action, and action availability.
- `Sources/LingobarCore/LingobarResult.swift` - generic result rows, collection item, and saved phrase models.
- `Sources/LingobarCore/StructuredLingobarResult.swift` - generic structured AI JSON result bridge.
- `Sources/LingobarCore/GrammarResult.swift` - grammar-specific result schema and Lingobar bridge.
- `Sources/LingobarCore/LingobarSettings.swift` - settings sections, setup gate view model, AI provider options, appearance schemes, action order, and default action rules.
- `Sources/LingobarCore/SetupGate.swift` - setup gate status and required action.
- `Sources/LingobarCore/LocalLanguageEngine.swift` - deterministic fallback/prototype result content used by checks and fixtures.
- `Sources/LingobarCore/GrammarUITestFixtures.swift` - long-sentence grammar fixtures for render checks and fixture mode.

**AI Integration:**
- `Sources/LingobarCore/AIProviderConfiguration.swift` - token/base URL/model normalization and validity.
- `Sources/LingobarCore/OpenAICompatibleClient.swift` - OpenAI-compatible client, request factory, request DTOs, response DTOs, and connectivity test request.
- `Sources/LingobarCore/DeepSeekClient.swift` - DeepSeek compatibility wrapper over the OpenAI-compatible request factory.
- `Sources/LingobarCore/StructuredJSONExtractor.swift` - tolerant extraction of the first JSON object from raw AI text.

**SwiftUI Views:**
- `Sources/LingoPeekApp/LingobarRootView.swift` - floating Lingobar panel UI, action bar, result panels, input mode, setup panel, selectable result text, and AppKit text bridges.
- `Sources/LingoPeekApp/SettingsView.swift` - settings sidebar, sections, controls, hotkey recorder, connection test UI, and local settings snapshot editing.
- `Sources/LingoPeekApp/FlowLayout.swift` - simple wrapping layout helper for app views.
- `Sources/LingobarUI/GrammarResultPanel.swift` - reusable native grammar visualization panel.
- `Sources/LingobarUI/Style.swift` - shared Lingobar colors and button styles.

**Verification:**
- `Sources/LingoPeekCoreChecks/main.swift` - non-UI checks for core contracts and persistence.
- `Sources/LingoPeekGrammarUIChecks/main.swift` - render checks for grammar visualization tabs.
- `Sources/LingoPeekAIProbe/main.swift` - optional real AI connectivity check.
- `README.md` - command documentation for build, run, checks, fixture launch, and design preview.

**Documentation and Design:**
- `docs/adr/0001-ai-required-language-results.md` - AI-required language result decision.
- `docs/adr/0002-openai-compatible-ai-settings.md` - OpenAI-compatible settings decision.
- `docs/adr/0003-structured-ai-results.md` - structured JSON result decision.
- `docs/adr/0004-grammar-specific-structured-results.md` - grammar-specific result shape decision.
- `docs/adr/0005-native-grammar-visualization.md` - native grammar rendering decision.
- `designs/lingobar-product/Lingobar Prototype.html` - product prototype reference.
- `designs/lingobar-grammar/Lingobar Grammar.html` - grammar prototype reference.
- `designs/lingobar-settings/Lingobar Settings.html` - settings prototype reference.

## Naming Conventions

**Files:**
- Use PascalCase `.swift` filenames for primary Swift types, as in `LingobarViewModel.swift`, `OpenAICompatibleClient.swift`, and `GrammarResultPanel.swift`.
- Use `main.swift` for executable utility/check targets, as in `Sources/LingoPeekCoreChecks/main.swift`.
- Use one primary public/internal type per Swift file when adding core or app services; small private helper types may stay co-located in large view/controller files.
- Use `Lingobar...` prefixes for product/domain types and `LingoPeek...` prefixes for app/package executable names.
- Use `Grammar...` prefixes for grammar-specific contracts and UI components.
- Use `OpenAI...`, `DeepSeek...`, or `AI...` prefixes for provider/configuration contracts.
- Use kebab-case Markdown names under `docs/`, as in `docs/product-brief.md` and `docs/lingobar-settings-spec.md`.
- Use four-digit numeric ADR prefixes under `docs/adr/`, as in `docs/adr/0005-native-grammar-visualization.md`.
- Use UPPERCASE Markdown for root/project and GSD mapping docs, as in `README.md`, `AGENTS.md`, `.planning/codebase/ARCHITECTURE.md`.

**Directories:**
- Use SwiftPM target names under `Sources/` with PascalCase, matching target/product names in `Package.swift`.
- Keep SwiftPM target source files flat within each target unless a target becomes too large to navigate.
- Use kebab-case feature folders under `designs/`.
- Use lowercase documentation grouping directories such as `docs/adr/` and `docs/agents/`.

**Special Patterns:**
- `AppSettings.save...` methods persist settings and post notifications; pair new stored settings with snapshot fields in `LingobarSettingsSnapshot`.
- `LingobarSettingsSnapshot` owns typed settings behavior that should be testable without AppKit.
- `LanguageAction` owns action labels, symbols, keyboard shortcuts, availability, and contextual more-action titles.
- `Structured...Result` names indicate AI JSON contracts that bridge into UI-facing result models.
- Check targets use local `check` helper functions and throw `CheckFailure` rather than XCTest assertions.
- Environment-driven app modes use `LINGOPEEK_...` variables in `AppDelegate`, `AppSettings`, and `SettingsView`.

## Where to Add New Code

**New Language Action:**
- Core definition: `Sources/LingobarCore/LanguageAction.swift`.
- Generic result contract changes: `Sources/LingobarCore/LingobarResult.swift` or `Sources/LingobarCore/StructuredLingobarResult.swift`.
- Prompt/workflow behavior: `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Panel rendering: `Sources/LingoPeekApp/LingobarRootView.swift`.
- Settings defaults/order: `Sources/LingobarCore/LingobarSettings.swift` and `Sources/LingoPeekApp/AppSettings.swift`.
- Verification: `Sources/LingoPeekCoreChecks/main.swift`.
- Product copy guidance: `CONTEXT.md` and relevant docs under `docs/`.

**New Grammar Capability:**
- Data contract: `Sources/LingobarCore/GrammarResult.swift`.
- Fixtures: `Sources/LingobarCore/GrammarUITestFixtures.swift`.
- Native rendering: `Sources/LingobarUI/GrammarResultPanel.swift`.
- App integration: `Sources/LingoPeekApp/LingobarRootView.swift` and `Sources/LingoPeekApp/LingobarViewModel.swift`.
- Verification: `Sources/LingoPeekCoreChecks/main.swift` and `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Decision/spec updates: `docs/lingobar-grammar-spec.md` or a new ADR in `docs/adr/`.

**New AI Provider or Request Behavior:**
- Provider configuration model: `Sources/LingobarCore/AIProviderConfiguration.swift` and `Sources/LingobarCore/LingobarSettings.swift`.
- Request factory/client code: `Sources/LingobarCore/OpenAICompatibleClient.swift` or a new file under `Sources/LingobarCore/`.
- App settings bridge: `Sources/LingoPeekApp/AppSettings.swift`.
- Settings UI: `Sources/LingoPeekApp/SettingsView.swift`.
- Probe support: `Sources/LingoPeekAIProbe/main.swift`.
- Verification: `Sources/LingoPeekCoreChecks/main.swift`.

**New App Window, Panel Behavior, or macOS Integration:**
- AppKit controller code: `Sources/LingoPeekApp/LingobarController.swift` or `Sources/LingoPeekApp/SettingsWindowController.swift`.
- Event/hotkey code: `Sources/LingoPeekApp/HotKeyManager.swift` and `Sources/LingoPeekApp/LingobarHotKey.swift`.
- Selection/pasteboard integration: `Sources/LingoPeekApp/SelectionReader.swift`.
- SwiftUI surface: `Sources/LingoPeekApp/LingobarRootView.swift` or `Sources/LingoPeekApp/SettingsView.swift`.
- Verification: Add core checks when behavior has pure rules; use manual app verification for windowing behavior.

**New Settings Preference:**
- Typed setting and defaults: `Sources/LingobarCore/LingobarSettings.swift`.
- Persistence, environment override, and notification: `Sources/LingoPeekApp/AppSettings.swift`.
- UI control: `Sources/LingoPeekApp/SettingsView.swift`.
- Snapshot rendering support if needed: `Sources/LingoPeekApp/SettingsSnapshotRenderer.swift`.
- Verification: `Sources/LingoPeekCoreChecks/main.swift`.

**New Persistence Feature:**
- Core JSON file store or model: `Sources/LingobarCore/PhraseStore.swift` or a new file under `Sources/LingobarCore/`.
- App settings/preferences: `Sources/LingoPeekApp/AppSettings.swift`.
- UI and workflow integration: `Sources/LingoPeekApp/LingobarViewModel.swift`, `Sources/LingoPeekApp/SettingsView.swift`, or `Sources/LingoPeekApp/LingobarRootView.swift`.
- Verification: `Sources/LingoPeekCoreChecks/main.swift`.
- Keep secrets out of committed files and do not read `.env` files.

**New Reusable UI Component:**
- Shared Lingobar/grammar UI: `Sources/LingobarUI/`.
- App-only UI: `Sources/LingoPeekApp/`.
- Shared colors/styles: `Sources/LingobarUI/Style.swift` for Lingobar panel styling; app-local settings styles stay in `Sources/LingoPeekApp/SettingsView.swift`.
- Verification: `Sources/LingoPeekGrammarUIChecks/main.swift` for grammar UI or app snapshot tooling for settings.

**New Verification Check:**
- Core logic: `Sources/LingoPeekCoreChecks/main.swift`.
- Grammar rendering: `Sources/LingoPeekGrammarUIChecks/main.swift`.
- Live provider check: `Sources/LingoPeekAIProbe/main.swift`, with secrets supplied through environment variables.
- SwiftPM manifest: add products/targets in `Package.swift` if creating a new executable check.
- CI: update `.github/workflows/package-app.yml` when new checks must run in CI.

**New Documentation or Decision Record:**
- Domain vocabulary: `CONTEXT.md`.
- User/developer guide: `README.md`.
- Product/interaction specs: `docs/`.
- Architecture decision: `docs/adr/{NNNN}-{slug}.md`.
- Agent workflow docs: `docs/agents/`.
- Codebase maps: `.planning/codebase/`.

## Special Directories

**`designs/`:**
- Purpose: Prototype source and visual references for app UI.
- Source: Created as standalone HTML/JSX design artifacts.
- Committed: Yes.
- Guidance: Use these for visual intent; implement production UI natively in `Sources/LingoPeekApp/` or `Sources/LingobarUI/`.

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents consumed by planning and execution workflows.
- Source: Generated/updated by mapper agents.
- Committed: Project-dependent; treat as planning source when present.
- Guidance: Update `ARCHITECTURE.md` and `STRUCTURE.md` when target boundaries or directory layout change.

**`.omx/`:**
- Purpose: Local OMX runtime state, logs, metrics, and session files.
- Source: Local agent runtime.
- Committed: No; ignored by `.gitignore`.
- Guidance: Do not modify for ordinary codebase work and do not commit.

**`.build/` and `.swiftpm/`:**
- Purpose: SwiftPM build output and local package metadata.
- Source: `swift build`, `swift run`, and SwiftPM tooling.
- Committed: No; ignored by `.gitignore`.
- Guidance: Do not read as source and do not commit.

**`dist/`:**
- Purpose: Packaged app output such as `dist/LingoPeek.app` and `dist/LingoPeek.zip`.
- Source: `scripts/package_app.sh`.
- Committed: No; ignored by `.gitignore`.
- Guidance: Regenerate with the packaging script instead of editing by hand.

**`Tests/`:**
- Purpose: Reserved SwiftPM test tree.
- Source: Empty directories only.
- Committed: Directories may exist; no test files are present.
- Guidance: Use `Sources/LingoPeekCoreChecks/` and `Sources/LingoPeekGrammarUIChecks/` for the current check pattern.

**`.claude/`:**
- Purpose: Local launch/config files for agent/editor tooling.
- Source: Local workspace configuration.
- Committed: Present in the working tree as `.claude/launch.json`.
- Guidance: Avoid changing this unless the task explicitly concerns local agent/tool launch behavior.

---

*Structure analysis: 2026-06-25*
*Update when directory structure changes*
