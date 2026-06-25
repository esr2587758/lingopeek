# Phase 1: Hub Data Foundations - Pattern Map

**Mapped:** 2026-06-26  
**Files analyzed:** 6 proposed new/modified files  
**Analogs found:** 6 / 6

## Scope Source

Phase 1 is defined in `.planning/ROADMAP.md` lines 21-33: add Foundation-only local history persistence, record completed language actions without storing provider secrets, adapt saved phrases into Hub collection items, and cover the new persistence/transformation behavior in core checks.

Relevant requirements from `.planning/REQUIREMENTS.md`:
- `HIST-01`: record completed language actions into a local bounded history store.
- `COLL-01`: view locally saved phrases from `PhraseStore` in the Hub collection list.
- `COLL-05`: copy a collection item from the Hub.
- `HIST-02`: expose recent history records with action badge, item type, source, and relative time inputs.
- `HIST-06`: copy, delete, and clear history records.

Planning/research alignment:
- `.planning/research/SUMMARY.md` line 5 recommends reusing `AppSettings`, `LingobarSettingsSnapshot`, `PhraseStore`, and SwiftPM checks while adding a small Foundation history store.
- `.planning/research/ARCHITECTURE.md` recommends `LingobarHistoryRecord`, `LingobarHistoryStore`, and a Hub library item model/adaptor for collection and history.

## Existing Pattern Inventory

### Foundation-Only Stores

**Primary source:** `Sources/LingobarCore/PhraseStore.swift`

Pattern:
- Core store imports only `Foundation`.
- Reference type is `public final class ...: @unchecked Sendable`.
- Store owns `fileURL`, encoder/decoder, and `NSLock`.
- Default path uses Application Support plus `LingoPeek`.
- Missing file returns `[]`.
- Writes create the directory and use atomic JSON writes.

Code to copy from `Sources/LingobarCore/PhraseStore.swift` lines 1-14:

```swift
import Foundation

public final class PhraseStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
```

Default path pattern from `Sources/LingobarCore/PhraseStore.swift` lines 16-20:

```swift
public static func defaultStore() -> PhraseStore {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directory = base.appending(path: "LingoPeek", directoryHint: .isDirectory)
    return PhraseStore(fileURL: directory.appending(path: "phrases.json"))
}
```

Load/save pattern from `Sources/LingobarCore/PhraseStore.swift` lines 22-40:

```swift
public func load() throws -> [SavedPhrase] {
    lock.lock()
    defer { lock.unlock() }

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return []
    }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode([SavedPhrase].self, from: data)
}

public func save(_ phrases: [SavedPhrase]) throws {
    lock.lock()
    defer { lock.unlock() }

    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try encoder.encode(phrases)
    try data.write(to: fileURL, options: [.atomic])
}
```

### Codable Value Models

**Primary sources:** `Sources/LingobarCore/LingobarResult.swift`, `Sources/LingobarCore/StructuredLingobarResult.swift`, `Sources/LingobarCore/GrammarResult.swift`

Use `Equatable` and `Sendable` on core value types. Add `Codable` only when a type crosses a JSON/persistence boundary.

Existing compact persisted value from `Sources/LingobarCore/LingobarResult.swift` lines 59-71:

```swift
public struct SavedPhrase: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var note: String
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, note: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.note = note
        self.createdAt = createdAt
    }
}
```

UI-ready bridge pattern from `Sources/LingobarCore/StructuredLingobarResult.swift` lines 25-35:

```swift
public func lingobarResult(shortcut: String) -> LingobarResult {
    LingobarResult(
        title: title,
        shortcut: shortcut,
        summary: summary,
        rows: rows,
        sideTitle: "后续动作",
        chips: chips,
        moreActionTitle: moreActionTitle,
        defaultCollectionItem: defaultCollectionItem
    )
}
```

Tolerant Codable defaulting pattern from `Sources/LingobarCore/GrammarResult.swift` lines 109-132:

```swift
public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let pattern = try container.decodeIfPresent(GrammarPattern.self, forKey: .pattern)
        ?? GrammarPattern(en: "", zh: "")
    self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "语法解析"
    self.sourceSentence = try container.decode(String.self, forKey: .sourceSentence)
    self.chineseMeaning = try container.decode(String.self, forKey: .chineseMeaning)
    self.analysisScopeNote = try container.decodeIfPresent(String.self, forKey: .analysisScopeNote) ?? ""
    self.chunks = try container.decodeIfPresent([GrammarChunk].self, forKey: .chunks) ?? []
    self.dependencies = try container.decodeIfPresent([GrammarDependency].self, forKey: .dependencies) ?? []
    self.tree = try container.decodeIfPresent(GrammarTreeNode.self, forKey: .tree)
        ?? GrammarTreeNode(label: "主句", role: .predicate, text: sourceSentence)
    self.trunk = try container.decodeIfPresent(GrammarTrunk.self, forKey: .trunk)
        ?? GrammarTrunk(core: [], dropped: [], coreZh: "")
    self.tenseVoice = try container.decodeIfPresent([GrammarTenseClause].self, forKey: .tenseVoice) ?? []
    self.wordOrder = try container.decodeIfPresent(GrammarWordOrder.self, forKey: .wordOrder)
        ?? GrammarWordOrder(en: [], zhOrder: [], zhText: [], note: "")
    self.pattern = pattern
    self.collocations = try container.decodeIfPresent([GrammarCollocation].self, forKey: .collocations) ?? []
    self.phrases = try container.decodeIfPresent([GrammarPhrase].self, forKey: .phrases) ?? []
    self.grammarPoints = try container.decodeIfPresent([GrammarPoint].self, forKey: .grammarPoints) ?? []
    self.defaultCollectionItem = try container.decodeIfPresent(DefaultCollectionItem.self, forKey: .defaultCollectionItem)
        ?? DefaultCollectionItem(title: pattern.en, note: pattern.zh, type: "句型")
}
```

### Core/App Layering

Core boundary from `.planning/codebase/ARCHITECTURE.md` lines 27-33:
- `Sources/LingobarCore/` is for domain models, result contracts, settings snapshots, and local data shapes.
- It depends on `Foundation`.
- It is consumed by app, UI, and check targets.
- Put behavior here when it should be testable without a macOS window.

App boundary from `.planning/codebase/ARCHITECTURE.md` lines 43-49:
- `Sources/LingoPeekApp/` owns AppKit lifecycle, selection capture, pasteboard, windows, UserDefaults, and SwiftUI hosting.
- It depends on platform frameworks plus `LingobarCore`.
- Keep direct AppKit/UserDefaults out of `LingobarCore`.

SwiftPM target pattern from `Package.swift` lines 19-38:

```swift
.target(name: "LingobarCore"),
.executableTarget(
    name: "LingoPeekApp",
    dependencies: ["LingobarCore", "LingobarUI"],
    linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("ApplicationServices"),
        .linkedFramework("Carbon"),
        .linkedFramework("Security"),
        .linkedFramework("SwiftUI")
    ]
),
.executableTarget(
    name: "LingoPeekCoreChecks",
    dependencies: ["LingobarCore"]
),
```

For Phase 1, new Swift files under `Sources/LingobarCore/` do not require a `Package.swift` change because they are part of the existing target.

### Settings Snapshots

Use snapshot-style core models for Hub-facing data contracts: values are explicit fields, initialized with defaults, `Equatable`, `Sendable`, and behavior is pure.

Snapshot pattern from `Sources/LingobarCore/LingobarSettings.swift` lines 167-228:

```swift
public struct LingobarSettingsSnapshot: Equatable, Sendable {
    public var launchAtLogin: Bool
    public var showMenuBarIcon: Bool
    public var appearanceScheme: LingobarAppearanceScheme
    public var aiProvider: LingobarAIProvider
    public var model: String
    public var baseURLString: String
    public var apiToken: String
    public var accessibilityPermissionGranted: Bool
    public var triggerOnSelection: Bool
    public var showSelectionFloatButton: Bool
    public var inputHotKeyDisplay: [String]
    public var actionOrder: [LanguageAction]
    public var defaultEnglishAction: LanguageAction
    public var defaultChineseMixedAction: LanguageAction
    public var collectionTarget: LingobarCollectionTarget
    public var autoReadClipboard: Bool

    public static let defaultActionOrder: [LanguageAction] = [
        .grammar,
        .translate,
        .rewrite,
        .examples,
        .collect,
        .pronounce
    ]

    public init(
        launchAtLogin: Bool = true,
        showMenuBarIcon: Bool = true,
        appearanceScheme: LingobarAppearanceScheme = .glass,
        aiProvider: LingobarAIProvider = .openAICompatible,
        model: String = LingobarAIProvider.openAICompatible.defaultModel,
        baseURLString: String = LingobarAIProvider.openAICompatible.defaultBaseURLString,
        apiToken: String = "",
        accessibilityPermissionGranted: Bool = false,
        triggerOnSelection: Bool = true,
        showSelectionFloatButton: Bool = true,
        inputHotKeyDisplay: [String] = ["⌥", "Space"],
        actionOrder: [LanguageAction] = LingobarSettingsSnapshot.defaultActionOrder,
        defaultEnglishAction: LanguageAction = .translate,
        defaultChineseMixedAction: LanguageAction = .rewrite,
        collectionTarget: LingobarCollectionTarget = .followCurrentPanel,
        autoReadClipboard: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.appearanceScheme = appearanceScheme
        self.aiProvider = aiProvider
        self.model = model
        self.baseURLString = baseURLString
        self.apiToken = apiToken
        self.accessibilityPermissionGranted = accessibilityPermissionGranted
        self.triggerOnSelection = triggerOnSelection
        self.showSelectionFloatButton = showSelectionFloatButton
        self.inputHotKeyDisplay = inputHotKeyDisplay
        self.actionOrder = actionOrder
        self.defaultEnglishAction = defaultEnglishAction
        self.defaultChineseMixedAction = defaultChineseMixedAction
        self.collectionTarget = collectionTarget
        self.autoReadClipboard = autoReadClipboard
    }
```

App facade snapshot creation from `Sources/LingoPeekApp/AppSettings.swift` lines 155-174:

```swift
static func makeSettingsSnapshot() -> LingobarSettingsSnapshot {
    LingobarSettingsSnapshot(
        launchAtLogin: launchAtLogin,
        showMenuBarIcon: showMenuBarIcon,
        appearanceScheme: appearanceScheme,
        aiProvider: aiProvider,
        model: model,
        baseURLString: baseURLString,
        apiToken: apiToken,
        accessibilityPermissionGranted: isAccessibilityPermissionGranted,
        triggerOnSelection: triggerOnSelection,
        showSelectionFloatButton: showSelectionFloatButton,
        inputHotKeyDisplay: [hotKey.displayString],
        actionOrder: actionOrder,
        defaultEnglishAction: defaultEnglishAction,
        defaultChineseMixedAction: defaultChineseMixedAction,
        collectionTarget: collectionTarget,
        autoReadClipboard: autoReadClipboard
    )
}
```

### Core Checks

The repo uses executable check targets, not XCTest. Add Phase 1 checks to `Sources/LingoPeekCoreChecks/main.swift`.

Check helper from `Sources/LingoPeekCoreChecks/main.swift` lines 4-18:

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

Persistence check pattern from `Sources/LingoPeekCoreChecks/main.swift` lines 530-544:

```swift
func checkPhraseStore() throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "LingoPeekChecks-\(UUID().uuidString)", directoryHint: .isDirectory)
    let fileURL = directory.appending(path: "phrases.json")
    let store = PhraseStore(fileURL: fileURL)
    let phrases = [
        SavedPhrase(title: "selection-first", note: "以选区为入口。"),
        SavedPhrase(title: "learning object", note: "可拆解、可复用。")
    ]

    try store.save(phrases)
    let loaded = try store.load()
    try check(loaded.map(\.title) == phrases.map(\.title), "phrase titles should persist")
    try check(loaded.map(\.note) == phrases.map(\.note), "phrase notes should persist")
}
```

Entrypoint pattern from `Sources/LingoPeekCoreChecks/main.swift` lines 546-564:

```swift
do {
    try checkLocalLanguageEngine()
    try checkLanguageActionKeyboardShortcuts()
    try checkDeepSeekRequestFactory()
    try checkOpenAICompatibleRequestFactory()
    try checkSetupGate()
    try checkLingobarSettingsNavigationModel()
    try checkLingobarSettingsSnapshotBehavior()
    try checkAIProviderConfiguration()
    try checkStructuredAIResultParsing()
    try checkGrammarResultFixture()
    try checkGrammarUITestFixtures()
    try checkGrammarAIResponseTolerance()
    try checkPhraseStore()
    print("LingoPeekCoreChecks passed")
} catch {
    fputs("LingoPeekCoreChecks failed: \(error)\n", stderr)
    exit(1)
}
```

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Sources/LingobarCore/LanguageAction.swift` | model | transform + serialization | `Sources/LingobarCore/LingobarSettings.swift` | exact for Codable enum shape |
| `Sources/LingobarCore/LingobarHistoryStore.swift` | service/store + model | CRUD + file-I/O | `Sources/LingobarCore/PhraseStore.swift` | role-match |
| `Sources/LingobarCore/LingobarHubLibrary.swift` | model + utility | transform | `Sources/LingobarCore/StructuredLingobarResult.swift` | role-match |
| `Sources/LingoPeekApp/LingobarViewModel.swift` | provider/store integration | event-driven + request-response + file-I/O | `Sources/LingoPeekApp/LingobarViewModel.swift` | exact in-place pattern |
| `Sources/LingoPeekCoreChecks/main.swift` | test/check | batch | `Sources/LingoPeekCoreChecks/main.swift` | exact in-place pattern |
| `Package.swift` | config | build graph | `Package.swift` | no change expected |

## Pattern Assignments

### `Sources/LingobarCore/LanguageAction.swift` (model, transform + serialization)

**Analog:** `Sources/LingobarCore/LingobarSettings.swift`

**Purpose in Phase 1:** If history records persist `LanguageAction`, add `Codable` to `LanguageAction`. Prefer this over persisting display labels such as `"翻译"` because `LanguageAction.rawValue` is already stable and used in checks.

**Existing enum pattern** from `Sources/LingobarCore/LanguageAction.swift` lines 9-17:

```swift
public enum LanguageAction: String, CaseIterable, Identifiable, Sendable {
    case copy
    case translate
    case grammar
    case rewrite
    case examples
    case collect
    case pronounce
```

**Codable enum analog** from `Sources/LingobarCore/LingobarSettings.swift` lines 3-12:

```swift
public enum LingobarSettingsSectionID: String, CaseIterable, Identifiable, Codable, Sendable {
    case general
    case ai
    case permissions
    case trigger
    case actions
    case collection
    case about

    public var id: String { rawValue }
}
```

**Action metadata to reuse** from `Sources/LingobarCore/LanguageAction.swift` lines 42-63:

```swift
public var title: String {
    switch self {
    case .copy: "复制"
    case .translate: "翻译"
    case .grammar: "语法"
    case .rewrite: "改写"
    case .examples: "例句"
    case .collect: "收藏"
    case .pronounce: "发音"
    }
}

public var symbol: String {
    switch self {
    case .copy: "doc.on.doc"
    case .translate: "character.book.closed"
    case .grammar: "point.3.connected.trianglepath.dotted"
    case .rewrite: "pencil"
    case .examples: "quote.opening"
    case .collect: "star"
    case .pronounce: "speaker.wave.2"
    }
}
```

**Recommendation:**
- Change declaration to `public enum LanguageAction: String, CaseIterable, Identifiable, Codable, Sendable`.
- Do not add a second history-specific action enum.
- Persist action raw values through `Codable`; render action badges through `action.title`.

### `Sources/LingobarCore/LingobarHistoryStore.swift` (service/store + model, CRUD + file-I/O)

**Analog:** `Sources/LingobarCore/PhraseStore.swift`

**Purpose in Phase 1:** Add bounded local history persistence for completed Lingobar language actions. This should remain Foundation-only and live in `LingobarCore`.

**Imports/store shell pattern** from `Sources/LingobarCore/PhraseStore.swift` lines 1-14:

```swift
import Foundation

public final class PhraseStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
```

**Default path pattern** from `Sources/LingobarCore/PhraseStore.swift` lines 16-20:

```swift
public static func defaultStore() -> PhraseStore {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directory = base.appending(path: "LingoPeek", directoryHint: .isDirectory)
    return PhraseStore(fileURL: directory.appending(path: "phrases.json"))
}
```

**Load/save pattern** from `Sources/LingobarCore/PhraseStore.swift` lines 22-40:

```swift
public func load() throws -> [SavedPhrase] {
    lock.lock()
    defer { lock.unlock() }

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return []
    }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode([SavedPhrase].self, from: data)
}

public func save(_ phrases: [SavedPhrase]) throws {
    lock.lock()
    defer { lock.unlock() }

    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try encoder.encode(phrases)
    try data.write(to: fileURL, options: [.atomic])
}
```

**Recommended API shape:**

```swift
public struct LingobarHistoryRecord: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var action: LanguageAction
    public var sourceText: String
    public var resultTitle: String
    public var resultSummary: String
    public var itemTitle: String
    public var itemNote: String
    public var itemType: String
    public var sourceAppName: String
    public var createdAt: Date
}

public final class LingobarHistoryStore: @unchecked Sendable {
    public init(fileURL: URL, limit: Int = 200)
    public static func defaultStore() -> LingobarHistoryStore
    public func load() throws -> [LingobarHistoryRecord]
    public func save(_ records: [LingobarHistoryRecord]) throws
    @discardableResult public func append(_ record: LingobarHistoryRecord) throws -> [LingobarHistoryRecord]
    @discardableResult public func delete(id: UUID) throws -> [LingobarHistoryRecord]
    public func clear() throws
}
```

**Implementation recommendations:**
- Use `history.json` under the same `Application Support/LingoPeek` directory as `phrases.json`.
- Keep newest records first, because Hub list and checks expect recent history.
- Enforce `limit` on append and save boundaries. A default of `200` is enough unless planning chooses another bounded value.
- Keep delete/clear implemented through `load` + filtered `save` or `save([])` so all mutations reuse the same atomic write path.
- Missing file should return `[]`.
- Corrupt JSON should throw; do not silently overwrite with `[]`, because that would destroy user history without surfacing the data problem.

### `Sources/LingobarCore/LingobarHubLibrary.swift` (model + utility, transform)

**Analogs:** `Sources/LingobarCore/StructuredLingobarResult.swift`, `Sources/LingobarCore/LingobarSettings.swift`, `Sources/LingobarCore/LingobarResult.swift`

**Purpose in Phase 1:** Define Hub-facing collection/history item contracts without adding UI. This gives Phase 2/3 SwiftUI views stable local data to render.

**Value model pattern** from `Sources/LingobarCore/LingobarResult.swift` lines 47-57:

```swift
public struct DefaultCollectionItem: Codable, Equatable, Sendable {
    public var title: String
    public var note: String
    public var type: String

    public init(title: String, note: String, type: String) {
        self.title = title
        self.note = note
        self.type = type
    }
}
```

**Adapter/bridge pattern** from `Sources/LingobarCore/StructuredLingobarResult.swift` lines 25-35:

```swift
public func lingobarResult(shortcut: String) -> LingobarResult {
    LingobarResult(
        title: title,
        shortcut: shortcut,
        summary: summary,
        rows: rows,
        sideTitle: "后续动作",
        chips: chips,
        moreActionTitle: moreActionTitle,
        defaultCollectionItem: defaultCollectionItem
    )
}
```

**Recommended API shape:**

```swift
public enum LingobarHubLibraryKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case collection
    case history

    public var id: String { rawValue }
}

public struct LingobarHubLibraryItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: LingobarHubLibraryKind
    public var title: String
    public var note: String
    public var itemType: String
    public var source: String
    public var createdAt: Date
    public var action: LanguageAction?
    public var copyText: String
    public var sourceText: String?
}

public enum LingobarHubLibrary {
    public static func collectionItems(from phrases: [SavedPhrase]) -> [LingobarHubLibraryItem]
    public static func historyItems(from records: [LingobarHistoryRecord]) -> [LingobarHubLibraryItem]
}
```

**Naming recommendations:**
- Prefer `LingobarHubLibraryItem` over unprefixed `HubLibraryItem`, because `.planning/codebase/STRUCTURE.md` lines 214-220 recommend `Lingobar...` prefixes for product/domain types.
- Keep `copyText` as a plain string so Phase 1 can satisfy copy-ready contracts without importing `AppKit` or touching `NSPasteboard` in core.
- Do not change `SavedPhrase` just to add type metadata in Phase 1. The adapter can supply a default `itemType`, such as `"短语"` or `"收藏"`, avoiding a persisted JSON migration.
- Keep relative time formatting out of core unless it is pure and explicitly needed. Store `createdAt`; let UI render relative time later.

### `Sources/LingoPeekApp/LingobarViewModel.swift` (provider/store integration, event-driven + request-response + file-I/O)

**Analog:** existing `Sources/LingoPeekApp/LingobarViewModel.swift`

**Purpose in Phase 1:** Inject and use `LingobarHistoryStore` so completed AI language actions append compact records. This is the app boundary because it has the active action, source app, selected/input text, and AI completion event.

**Existing injected store pattern** from `Sources/LingoPeekApp/LingobarViewModel.swift` lines 23-34:

```swift
@Published var actions: [LanguageAction] = AppSettings.actionOrder
private let store: PhraseStore
private var activeAIRequestID = UUID()

init(store: PhraseStore = .defaultStore()) {
    self.store = store
    self.savedPhrases = (try? store.load()) ?? [
        SavedPhrase(title: "selection-first", note: "以选区为入口，而不是先打开 App。")
    ]

    self.result = LingobarViewModel.pendingResult(for: .translate)
}
```

**Existing collection persistence pattern** from `Sources/LingoPeekApp/LingobarViewModel.swift` lines 136-149:

```swift
func saveCurrentPhrase() {
    let collectionTitle: String
    let note: String
    if AppSettings.collectionTarget == .originalSelection {
        collectionTitle = activeText
        note = "来自原文"
    } else {
        collectionTitle = result.defaultCollectionItem?.title ?? (result.defaultCollectionTitle.isEmpty ? activeText : result.defaultCollectionTitle)
        note = result.defaultCollectionItem?.note ?? result.summary
    }
    let phrase = SavedPhrase(title: phraseTitle(from: collectionTitle), note: note)
    savedPhrases.insert(phrase, at: 0)
    try? store.save(savedPhrases)
}
```

**Existing pasteboard boundary pattern** from `Sources/LingoPeekApp/LingobarViewModel.swift` lines 151-155:

```swift
func copyResult() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(result.summary, forType: .string)
    status = "已复制"
}
```

**Existing async stale-response pattern** from `Sources/LingoPeekApp/LingobarViewModel.swift` lines 223-274:

```swift
let requestID = UUID()
activeAIRequestID = requestID
isLoading = true
loadingStartedAt = Date()
status = "AI 生成中"
onLayoutChanged?()
Task {
    do {
        let completion = try await aiClient.complete(
            system: systemPrompt(for: action),
            user: text
        )
        let json = try StructuredJSONExtractor.extractObject(from: completion)
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "AI response is not UTF-8"))
        }
        guard self.activeAIRequestID == requestID else {
            return
        }
        if action == .grammar {
            let grammar = try JSONDecoder().decode(GrammarResult.self, from: data)
            self.grammarResult = grammar
            self.result = grammar.lingobarResult(shortcut: action.shortcut)
        } else {
            let structured = try JSONDecoder().decode(StructuredLingobarResult.self, from: data)
            self.grammarResult = nil
            self.result = structured.lingobarResult(shortcut: action.shortcut)
        }
        self.status = "AI 完成"
    } catch is DecodingError {
        guard self.activeAIRequestID == requestID else {
            return
        }
        self.grammarResult = nil
        self.result = self.errorResult(message: "AI 返回结构不符合语法面板，请重试。")
        self.status = "格式错误"
    } catch {
        guard self.activeAIRequestID == requestID else {
            return
        }
        self.grammarResult = nil
        self.result = self.errorResult(message: self.userFacingAIErrorMessage(error))
        self.status = "AI 不可用"
    }
    guard self.activeAIRequestID == requestID else {
        return
    }
    self.isLoading = false
    self.loadingStartedAt = nil
    self.onLayoutChanged?()
}
```

**Integration recommendations:**
- Add `private let historyStore: LingobarHistoryStore` and update init to `init(store: PhraseStore = .defaultStore(), historyStore: LingobarHistoryStore = .defaultStore())`.
- Record only successful completed language actions after the stale-response guard and after `self.result` has been set.
- Do not record `.copy` or `.collect` as language-action history unless product requirements explicitly expand; Phase 1 says completed language actions, and the action list for history is translate/grammar/rewrite/examples/pronounce.
- Keep history write failures non-fatal like collection persistence (`try?`) unless the planner wants status copy for history failures. Do not let history persistence break AI result display.
- Build `LingobarHistoryRecord` from user-visible fields only: `action`, `activeText`, `result.title`, `result.summary`, `defaultCollectionItem` title/note/type, `selectionSource`, and `Date()`.
- Do not store API token, base URL, model, provider, system prompt, raw provider response, or request body.

### `Sources/LingoPeekCoreChecks/main.swift` (test/check, batch)

**Analog:** existing `Sources/LingoPeekCoreChecks/main.swift`

**Purpose in Phase 1:** Add deterministic checks for history persistence, bounded retention, delete/clear, LanguageAction serialization, and Hub library item transforms.

**Check helper pattern** from `Sources/LingoPeekCoreChecks/main.swift` lines 14-18:

```swift
func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw CheckFailure.failed(message)
    }
}
```

**Temporary store pattern** from `Sources/LingoPeekCoreChecks/main.swift` lines 530-544:

```swift
let directory = FileManager.default.temporaryDirectory
    .appending(path: "LingoPeekChecks-\(UUID().uuidString)", directoryHint: .isDirectory)
let fileURL = directory.appending(path: "phrases.json")
let store = PhraseStore(fileURL: fileURL)
```

**Recommended new checks:**
- `checkLanguageActionCodable()`:
  - Encode/decode `.translate`, `.grammar`, `.rewrite`, `.examples`, `.pronounce`.
  - Assert raw values remain `["translate", "grammar", "rewrite", "examples", "pronounce"]` for persisted history compatibility.
- `checkLingobarHistoryStore()`:
  - Create temp `history.json` with `LingobarHistoryStore(fileURL:limit: 2)`.
  - Assert missing file loads as `[]`.
  - Append three records and assert only two newest remain.
  - Reload from disk and assert IDs/order/action/source fields persist.
  - Delete one ID and assert it is gone.
  - Clear and assert load returns `[]`.
- `checkLingobarHistoryPrivacy()`:
  - Encode a representative record and assert the JSON does not contain sample token/base URL/model/provider strings used only in the check.
  - Keep this as a guard against accidentally adding provider configuration to history records.
- `checkLingobarHubLibraryItems()`:
  - Convert `[SavedPhrase]` to collection items and assert `copyText == title`, note is preserved, `kind == .collection`, and default source/type are stable.
  - Convert `[LingobarHistoryRecord]` to history items and assert action, type, source, createdAt, and `copyText` come from the record.

**Entrypoint recommendation:** Add the new functions near related persistence/model checks, then call them before `checkPhraseStore()` or immediately after it in the final `do` block.

### `Package.swift` (config, build graph)

**Analog:** `Package.swift`

**Purpose in Phase 1:** No change expected. SwiftPM includes new files placed inside `Sources/LingobarCore/` automatically.

Current core/check target dependencies from `Package.swift` lines 19-38:

```swift
.target(name: "LingobarCore"),
.executableTarget(
    name: "LingoPeekApp",
    dependencies: ["LingobarCore", "LingobarUI"],
    linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("ApplicationServices"),
        .linkedFramework("Carbon"),
        .linkedFramework("Security"),
        .linkedFramework("SwiftUI")
    ]
),
.executableTarget(
    name: "LingoPeekCoreChecks",
    dependencies: ["LingobarCore"]
),
```

Do not add a new target for Phase 1 checks; extend `LingoPeekCoreChecks`.

## Shared Patterns

### Import Boundaries

**Source:** `.planning/codebase/CONVENTIONS.md` lines 44-55

Apply to all Phase 1 files:
- Core files import only `Foundation`.
- App integration imports platform frameworks only where needed.
- Internal modules are imported by target name, not path alias.

Recommended imports:

```swift
// Sources/LingobarCore/LingobarHistoryStore.swift
import Foundation

// Sources/LingobarCore/LingobarHubLibrary.swift
import Foundation

// Sources/LingoPeekApp/LingobarViewModel.swift already imports:
import AppKit
import Foundation
import LingobarCore
```

### Access Control

**Source:** `.planning/codebase/CONVENTIONS.md` lines 56-67

Apply to new core APIs consumed by app/check targets:
- Mark cross-target models and store APIs `public`.
- Keep private helpers private.
- Favor structs/enums for core data and a final class only for lock-protected file store state.

### Error Handling

**Sources:** `PhraseStore.swift`, `LingobarViewModel.swift`, `LingoPeekCoreChecks/main.swift`

Apply this split:
- Store APIs throw (`load`, `save`, `append`, `delete`, `clear`).
- ViewModel integration can use `try? historyStore.append(...)` so history write failures do not hide AI results, matching existing phrase save behavior at `LingobarViewModel.swift` lines 148 and 200.
- Checks should throw `CheckFailure.failed(...)` with contract-focused messages.

### Persistence

**Source:** `Sources/LingobarCore/PhraseStore.swift`

Apply to `LingobarHistoryStore`:
- `JSONEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]`
- `dateEncodingStrategy = .iso8601`
- `dateDecodingStrategy = .iso8601`
- `Data(contentsOf:)` and `JSONDecoder.decode`
- `FileManager.default.createDirectory(..., withIntermediateDirectories: true)`
- `data.write(to: fileURL, options: [.atomic])`
- `NSLock` around all file reads/writes

### Codable Migration/Corruption

**Sources:** `GrammarResult.swift`, `PhraseStore.swift`

Apply to history:
- New fields that may become optional later should use `decodeIfPresent` defaults, following `GrammarResult.swift` lines 109-132.
- Required fields for current history records should remain required to catch corruption.
- Missing history file returns `[]`; invalid JSON throws.
- Avoid changing `SavedPhrase` schema in Phase 1. If a later phase adds fields to `SavedPhrase`, use custom decoding defaults to preserve existing `phrases.json`.

### MainActor Integration

**Source:** `Sources/LingoPeekApp/LingobarViewModel.swift`

Apply to history recording:
- Keep ViewModel `@MainActor`.
- Record after checking `activeAIRequestID == requestID`.
- Never let stale AI completions append history.
- Do not introduce background queues or new cancellation abstractions in Phase 1.

## Naming And API-Shape Recommendations

Use these names unless the planner has a strong reason to deviate:

| Concept | Recommended Name | Rationale |
|---|---|---|
| History file store | `LingobarHistoryStore` | Matches `PhraseStore`; uses product prefix. |
| Persisted history record | `LingobarHistoryRecord` | Explicit persistence/domain contract. |
| Hub list item adapter | `LingobarHubLibraryItem` | Hub-facing but core-safe; product prefix matches repo conventions. |
| Hub item kind | `LingobarHubLibraryKind` | Avoids raw strings in checks/UI. |
| Record timestamp | `createdAt` | Matches `SavedPhrase.createdAt`. |
| Source app field | `sourceAppName` | Matches ViewModel `present(selection:sourceAppName:)`. |
| Copy-ready field | `copyText` | Explicitly supports COLL-05/HIST-06 without importing AppKit. |
| Store cap parameter | `limit` | Simple, check-injectable bounded storage. |

Recommended API style:
- Public initializers with default `UUID()` and `Date()` where appropriate, matching `SavedPhrase`.
- Use labeled parameters.
- Use `@discardableResult` only for mutation APIs that return updated records (`append`, `delete`) and may be intentionally ignored.
- Keep display labels derived from existing model metadata (`LanguageAction.title`, `DefaultCollectionItem.type`), not duplicated in persisted JSON.

## Testing Recommendations For `LingoPeekCoreChecks`

Add checks in this order:

1. `checkLanguageActionCodable()`
2. `checkLingobarHistoryStore()`
3. `checkLingobarHistoryPrivacy()`
4. `checkLingobarHubLibraryItems()`

Follow existing check style:
- Use one temp directory per store check: `LingoPeekChecks-\(UUID().uuidString)`.
- Use production APIs for persistence; do not manually write JSON except for an explicit corruption/migration check.
- Keep checks synchronous.
- Use direct equality and collection predicates.
- Add all new checks to the final `do` block so `swift run LingoPeekCoreChecks` remains the single Phase 1 verification command.

Recommended verification after implementation:

```bash
swift build --product LingoPeek
swift run LingoPeekCoreChecks
```

Do not run AI probes for Phase 1; history/privacy checks must not require secrets.

## Risk Notes

### Thread Safety

`PhraseStore` uses `NSLock` and `@unchecked Sendable`. `LingobarHistoryStore` should copy this exactly. Do not expose mutable arrays from the store; return value arrays and require callers to save/append/delete through the store.

### Async MainActor Integration

History should be appended only after the current AI request passes the existing stale-response guard. Recording before the guard risks writing history for an old selection after the user has triggered a newer one.

### JSON Migration And Corruption

Missing history file should be empty. Corrupt JSON should throw and be covered by checks if implemented. Do not silently clear corrupt history during load. Avoid changing `SavedPhrase` in this phase; adapt it into `LingobarHubLibraryItem` instead.

### Privacy

History records must contain compact user-visible data only. Do not store:
- API token
- base URL
- model
- provider
- system prompt
- raw request body
- raw provider response JSON

Allowed fields are action, visible source/input text, visible result summary/title/default collection metadata, source app display name, and timestamp.

### Avoiding UI Scope

Phase 1 has `UI hint: no`. Do not create `LingobarHubView`, `LingobarHubWindowController`, SwiftUI cards, filters, toasts, detail panes, or AppKit window behavior in this phase. The Hub visual surface belongs to Phase 2/3. Phase 1 should provide stable data contracts and checks that later UI phases can consume.

## No Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Bounded append/delete/clear history store behavior | service/store | CRUD + file-I/O | `PhraseStore` is the closest store analog but only has load/save. Implement append/delete/clear by composing load/save and keep the same lock/atomic-write pattern. |

## Metadata

**Analog search scope:** `Sources/LingobarCore`, `Sources/LingoPeekApp`, `Sources/LingoPeekCoreChecks`, `Package.swift`, `.planning/codebase`, `.planning/research`  
**Required files read:** 15  
**Additional analog files read:** `AppSettings.swift`, `StructuredLingobarResult.swift`, `AIProviderConfiguration.swift`, `OpenAICompatibleClient.swift`, `GrammarResult.swift`, `.planning/research/SUMMARY.md`, `.planning/research/ARCHITECTURE.md`  
**Pattern extraction date:** 2026-06-26

## PATTERNS COMPLETE
