import AppKit
import Carbon.HIToolbox
import LingobarCore
import SwiftUI

enum LingobarHubSection: String, CaseIterable, Identifiable {
    case collection
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collection: "收藏"
        case .history: "历史"
        case .settings: "设置"
        }
    }

    var subtitle: String {
        switch self {
        case .collection: "保存的表达"
        case .history: "近期处理"
        case .settings: "偏好与权限"
        }
    }

    var symbolName: String {
        switch self {
        case .collection: "star.fill"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape.fill"
        }
    }
}

@MainActor
final class LingobarHubState: ObservableObject {
    @Published var selectedSection: LingobarHubSection = .collection
    @Published var collectionItems: [LingobarHubLibraryItem] = []
    @Published var historyItems: [LingobarHubLibraryItem] = []
    @Published var selectedCollectionID: UUID?
    @Published var selectedHistoryID: UUID?
    @Published var collectionQuery = ""
    @Published var historyQuery = ""
    @Published var collectionFilter = LingobarHubItemFilter.all
    @Published var historyFilter = LingobarHubItemFilter.all
    @Published var selectedSettingsSectionID: LingobarSettingsSectionID = LingobarHubState.initialSettingsSectionID()
    @Published var settings = AppSettings.makeSettingsSnapshot()
    @Published var tokenDraft = ""
    @Published var revealToken = false
    @Published var toastMessage: String?

    private let phraseStore: PhraseStore
    private let historyStore: LingobarHistoryStore
    private var toastToken = UUID()

    init(
        phraseStore: PhraseStore = PhraseStore.defaultStore(),
        historyStore: LingobarHistoryStore = LingobarHistoryStore.defaultStore()
    ) {
        self.phraseStore = phraseStore
        self.historyStore = historyStore
        refresh()
    }

    private static func initialSettingsSectionID() -> LingobarSettingsSectionID {
        let rawValue = ProcessInfo.processInfo.environment["LINGOPEEK_OPEN_HUB_SETTINGS_SECTION"] ?? ""
        return LingobarSettingsSectionID(rawValue: rawValue) ?? .general
    }

    var selectedItem: LingobarHubLibraryItem? {
        switch selectedSection {
        case .collection:
            filteredCollectionItems.first { $0.id == selectedCollectionID } ?? filteredCollectionItems.first
        case .history:
            filteredHistoryItems.first { $0.id == selectedHistoryID } ?? filteredHistoryItems.first
        case .settings:
            nil
        }
    }

    var filteredCollectionItems: [LingobarHubLibraryItem] {
        filtered(collectionItems, filter: collectionFilter, query: collectionQuery)
    }

    var filteredHistoryItems: [LingobarHubLibraryItem] {
        filtered(historyItems, filter: historyFilter, query: historyQuery)
    }

    var collectionTypeOptions: [LingobarHubItemFilter] {
        filterOptions(for: collectionItems)
    }

    var historyTypeOptions: [LingobarHubItemFilter] {
        filterOptions(for: historyItems)
    }

    var trimmedTokenDraft: String {
        tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasPendingTokenDraft: Bool {
        !trimmedTokenDraft.isEmpty
    }

    var isSavedTokenConfigured: Bool {
        !settings.apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var tokenFieldPlaceholder: String {
        isSavedTokenConfigured ? "已配置，输入新 API Key 可替换" : "sk-..."
    }

    var tokenStatusTitle: String {
        if hasPendingTokenDraft && isSavedTokenConfigured {
            return "待替换"
        }
        if hasPendingTokenDraft {
            return "待保存"
        }
        return isSavedTokenConfigured ? "已配置" : "未配置"
    }

    func refresh() {
        refreshLibrary()
        refreshSettings()
    }

    func refreshLibrary() {
        do {
            let phrases = try phraseStore.load()
            let records = try historyStore.load()
            collectionItems = LingobarHubLibrary.collectionItems(from: phrases)
                .sorted { $0.createdAt > $1.createdAt }
            historyItems = LingobarHubLibrary.historyItems(from: records)
                .sorted { $0.createdAt > $1.createdAt }
            if selectedCollectionID == nil {
                selectedCollectionID = collectionItems.first?.id
            }
            if selectedHistoryID == nil {
                selectedHistoryID = historyItems.first?.id
            }
        } catch {
            flash("读取资料失败")
        }
    }

    func refreshSettings() {
        settings = AppSettings.makeSettingsSnapshot()
    }

    func select(_ item: LingobarHubLibraryItem) {
        switch item.kind {
        case .collection:
            selectedCollectionID = item.id
        case .history:
            selectedHistoryID = item.id
        }
    }

    func copy(_ item: LingobarHubLibraryItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.copyText.isEmpty ? item.visibleText : item.copyText, forType: .string)
        flash("已复制")
    }

    func delete(_ item: LingobarHubLibraryItem) {
        do {
            switch item.kind {
            case .collection:
                var phrases = try phraseStore.load()
                phrases.removeAll { $0.id == item.id }
                try phraseStore.save(phrases)
                selectedCollectionID = nil
            case .history:
                _ = try historyStore.delete(id: item.id)
                selectedHistoryID = nil
            }
            refreshLibrary()
            flash("已删除")
        } catch {
            flash("删除失败")
        }
    }

    func clearHistory() {
        do {
            try historyStore.clear()
            selectedHistoryID = nil
            refreshLibrary()
            flash("历史已清空")
        } catch {
            flash("清空失败")
        }
    }

    func saveHistoryItemToCollection(_ item: LingobarHubLibraryItem) {
        do {
            var phrases = try phraseStore.load()
            let saved = SavedPhrase(
                id: item.id,
                title: item.visibleText.isEmpty ? item.title : item.visibleText,
                note: item.note,
                createdAt: Date()
            )
            phrases.removeAll { $0.id == saved.id }
            phrases.insert(saved, at: 0)
            try phraseStore.save(phrases)
            refreshLibrary()
            flash("已加入收藏")
        } catch {
            flash("收藏失败")
        }
    }

    func saveLaunchAtLogin(_ value: Bool) {
        settings.launchAtLogin = value
        AppSettings.saveLaunchAtLogin(value)
        refreshSettings()
    }

    func saveShowMenuBarIcon(_ value: Bool) {
        settings.showMenuBarIcon = value
        AppSettings.saveShowMenuBarIcon(value)
        refreshSettings()
    }

    func saveAppearanceScheme(_ scheme: LingobarAppearanceScheme) {
        settings.appearanceScheme = scheme
        AppSettings.saveAppearanceScheme(scheme)
        refreshSettings()
    }

    func saveAIProvider(_ provider: LingobarAIProvider) {
        settings.selectAIProvider(provider)
        AppSettings.saveAIProvider(provider)
        AppSettings.saveModel(settings.model)
        AppSettings.saveBaseURL(settings.baseURLString)
        refreshSettings()
    }

    func saveModel(_ model: String) {
        settings.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        AppSettings.saveModel(settings.model)
        refreshSettings()
    }

    func saveBaseURL(_ baseURL: String) {
        settings.baseURLString = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        AppSettings.saveBaseURL(settings.baseURLString)
        refreshSettings()
    }

    func saveTokenDraft() {
        guard hasPendingTokenDraft else {
            return
        }
        AppSettings.saveAPIToken(trimmedTokenDraft)
        tokenDraft = ""
        refreshSettings()
        flash("API Key 已保存")
    }

    func clearToken() {
        AppSettings.deleteAPIToken()
        tokenDraft = ""
        refreshSettings()
        flash("API Key 已清除")
    }

    func saveTriggerOnSelection(_ value: Bool) {
        settings.triggerOnSelection = value
        AppSettings.saveTriggerOnSelection(value)
        refreshSettings()
    }

    func saveShowSelectionFloatButton(_ value: Bool) {
        settings.showSelectionFloatButton = value
        AppSettings.saveShowSelectionFloatButton(value)
        refreshSettings()
    }

    func resetHotKey() {
        AppSettings.resetHotKey()
        refreshSettings()
        flash("快捷键已重置")
    }

    func saveHotKey(_ hotKey: LingobarHotKey) {
        AppSettings.saveHotKey(hotKey)
        refreshSettings()
        flash("快捷键已保存")
    }

    func moveAction(_ action: LanguageAction, offset: Int) {
        guard let index = settings.actionOrder.firstIndex(of: action) else {
            return
        }
        let newIndex = index + offset
        guard settings.actionOrder.indices.contains(newIndex) else {
            return
        }
        settings.actionOrder.swapAt(index, newIndex)
        AppSettings.saveActionOrder(settings.actionOrder)
        refreshSettings()
    }

    func saveDefaultEnglishAction(_ action: LanguageAction) {
        guard settings.selectDefaultEnglishAction(action) else {
            return
        }
        AppSettings.saveDefaultEnglishAction(action)
        refreshSettings()
    }

    func saveDefaultChineseMixedAction(_ action: LanguageAction) {
        guard settings.selectDefaultChineseMixedAction(action) else {
            return
        }
        AppSettings.saveDefaultChineseMixedAction(action)
        refreshSettings()
    }

    func saveCollectionTarget(_ target: LingobarCollectionTarget) {
        settings.collectionTarget = target
        AppSettings.saveCollectionTarget(target)
        refreshSettings()
    }

    func saveAutoReadClipboard(_ value: Bool) {
        settings.autoReadClipboard = value
        AppSettings.saveAutoReadClipboard(value)
        refreshSettings()
    }

    private func filtered(
        _ items: [LingobarHubLibraryItem],
        filter: LingobarHubItemFilter,
        query: String
    ) -> [LingobarHubLibraryItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items.filter { item in
            let matchesFilter = filter.matches(item)
            guard matchesFilter, !normalizedQuery.isEmpty else {
                return matchesFilter
            }
            return [
                item.title,
                item.visibleText,
                item.note,
                item.itemType,
                item.source,
                item.action?.title ?? ""
            ].contains { $0.lowercased().contains(normalizedQuery) }
        }
    }

    private func filterOptions(for items: [LingobarHubLibraryItem]) -> [LingobarHubItemFilter] {
        let typeOptions = Array(Set(items.map(\.itemType)))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted()
            .map(LingobarHubItemFilter.type)
        return [.all] + typeOptions
    }

    private func flash(_ message: String) {
        let token = UUID()
        toastToken = token
        toastMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if toastToken == token {
                toastMessage = nil
            }
        }
    }
}

enum LingobarHubItemFilter: Equatable, Identifiable {
    case all
    case type(String)

    var id: String {
        switch self {
        case .all: "all"
        case let .type(type): "type-\(type)"
        }
    }

    var title: String {
        switch self {
        case .all: "全部"
        case let .type(type): type
        }
    }

    func matches(_ item: LingobarHubLibraryItem) -> Bool {
        switch self {
        case .all:
            true
        case let .type(type):
            item.itemType == type
        }
    }
}

struct LingobarHubView: View {
    @ObservedObject var state: LingobarHubState
    var onClose: () -> Void
    var onOpenAccessibility: () -> Void
    var onRelaunch: (LingobarHubLibraryItem) -> Void

    private let sidebarWidth: CGFloat = 188
    private let detailWidth: CGFloat = 320

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HubColor.window)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(HubColor.hairline, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.36), radius: 28, x: 0, y: 18)

            HStack(spacing: 0) {
                HubSidebar(
                    selectedSection: $state.selectedSection,
                    collectionCount: state.collectionItems.count,
                    historyCount: state.historyItems.count,
                    isSetupReady: state.settings.settingsSetupGate.isReady,
                    onClose: onClose
                )
                .frame(width: sidebarWidth)

                Rectangle()
                    .fill(HubColor.hairline)
                    .frame(width: 1)
                    .padding(.vertical, 10)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(10)

            if let toastMessage = state.toastMessage {
                Text(toastMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.72))
                    )
                    .padding(.top, 18)
                    .padding(.trailing, 22)
                    .transition(.opacity)
            }
        }
        .frame(width: 920, height: 624)
        .background(Color.clear)
    }

    @ViewBuilder
    private var content: some View {
        switch state.selectedSection {
        case .collection:
            LibraryPane(
                title: "收藏",
                subtitle: "把常用表达沉淀成可复用素材。",
                query: $state.collectionQuery,
                selectedFilter: $state.collectionFilter,
                filters: state.collectionTypeOptions,
                items: state.filteredCollectionItems,
                selectedID: state.selectedCollectionID,
                emptyTitle: "还没有收藏",
                emptySubtitle: "在 Lingobar 里点收藏后会出现在这里。",
                detailWidth: detailWidth,
                onSelect: state.select,
                onCopy: state.copy,
                onDelete: state.delete,
                onRelaunch: onRelaunch,
                onCollect: nil
            )
        case .history:
            LibraryPane(
                title: "历史",
                subtitle: "最近的翻译、改写、语法和例句结果。",
                query: $state.historyQuery,
                selectedFilter: $state.historyFilter,
                filters: state.historyTypeOptions,
                items: state.filteredHistoryItems,
                selectedID: state.selectedHistoryID,
                emptyTitle: "暂无历史",
                emptySubtitle: "完成一次 AI 动作后会自动记录。",
                detailWidth: detailWidth,
                onSelect: state.select,
                onCopy: state.copy,
                onDelete: state.delete,
                onRelaunch: onRelaunch,
                onCollect: state.saveHistoryItemToCollection,
                trailingToolbar: AnyView(Group {
                    if !state.historyItems.isEmpty {
                        HubIconButton(systemName: "trash", help: "清空历史") {
                            state.clearHistory()
                        }
                    }
                })
            )
        case .settings:
            HubSettingsPane(
                state: state,
                onOpenAccessibility: onOpenAccessibility
            )
        }
    }
}

private struct HubSidebar: View {
    @Binding var selectedSection: LingobarHubSection
    var collectionCount: Int
    var historyCount: Int
    var isSetupReady: Bool
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Circle()
                    .fill(HubColor.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("L")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lingobar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text("Hub")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(HubColor.secondaryText)
                }
                .layoutPriority(1)
                Spacer()
                HubIconButton(systemName: "xmark", help: "关闭", action: onClose)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 7) {
                HubSectionLabel("我的内容")
                HubSidebarButton(
                    section: .collection,
                    count: collectionCount,
                    isSelected: selectedSection == .collection
                ) {
                    selectedSection = .collection
                }
                HubSidebarButton(
                    section: .history,
                    count: historyCount,
                    isSelected: selectedSection == .history
                ) {
                    selectedSection = .history
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                HubSectionLabel("应用")
                HubSidebarButton(
                    section: .settings,
                    count: nil,
                    isSelected: selectedSection == .settings
                ) {
                    selectedSection = .settings
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(isSetupReady ? HubColor.ok : HubColor.warn)
                    .frame(width: 8, height: 8)
                Text(isSetupReady ? "已就绪" : "需完成必填项")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HubColor.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
    }
}

private struct HubSidebarButton: View {
    var section: LingobarHubSection
    var count: Int?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? HubColor.accentText : HubColor.secondaryText)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text(section.subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(HubColor.tertiaryText)
                }
                Spacer(minLength: 4)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? HubColor.accentText : HubColor.tertiaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(HubColor.chip))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? HubColor.selectedFill : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
    }
}

private struct LibraryPane: View {
    var title: String
    var subtitle: String
    @Binding var query: String
    @Binding var selectedFilter: LingobarHubItemFilter
    var filters: [LingobarHubItemFilter]
    var items: [LingobarHubLibraryItem]
    var selectedID: UUID?
    var emptyTitle: String
    var emptySubtitle: String
    var detailWidth: CGFloat
    var onSelect: (LingobarHubLibraryItem) -> Void
    var onCopy: (LingobarHubLibraryItem) -> Void
    var onDelete: (LingobarHubLibraryItem) -> Void
    var onRelaunch: (LingobarHubLibraryItem) -> Void
    var onCollect: ((LingobarHubLibraryItem) -> Void)?
    var trailingToolbar: AnyView

    init(
        title: String,
        subtitle: String,
        query: Binding<String>,
        selectedFilter: Binding<LingobarHubItemFilter>,
        filters: [LingobarHubItemFilter],
        items: [LingobarHubLibraryItem],
        selectedID: UUID?,
        emptyTitle: String,
        emptySubtitle: String,
        detailWidth: CGFloat,
        onSelect: @escaping (LingobarHubLibraryItem) -> Void,
        onCopy: @escaping (LingobarHubLibraryItem) -> Void,
        onDelete: @escaping (LingobarHubLibraryItem) -> Void,
        onRelaunch: @escaping (LingobarHubLibraryItem) -> Void,
        onCollect: ((LingobarHubLibraryItem) -> Void)?,
        trailingToolbar: AnyView = AnyView(EmptyView())
    ) {
        self.title = title
        self.subtitle = subtitle
        _query = query
        _selectedFilter = selectedFilter
        self.filters = filters
        self.items = items
        self.selectedID = selectedID
        self.emptyTitle = emptyTitle
        self.emptySubtitle = emptySubtitle
        self.detailWidth = detailWidth
        self.onSelect = onSelect
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onRelaunch = onRelaunch
        self.onCollect = onCollect
        self.trailingToolbar = trailingToolbar
    }

    private var selectedItem: LingobarHubLibraryItem? {
        items.first { $0.id == selectedID } ?? items.first
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(HubColor.primaryText)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HubColor.secondaryText)
                    }
                    Spacer()
                    trailingToolbar
                }
                .padding(.top, 16)
                .padding(.horizontal, 18)

                HubSearchField(text: $query)
                    .padding(.horizontal, 18)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters) { filter in
                            HubFilterChip(
                                title: filter.title,
                                isSelected: filter == selectedFilter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 2)
                }

                if items.isEmpty {
                    HubEmptyState(title: emptyTitle, subtitle: emptySubtitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 9) {
                            ForEach(items) { item in
                                HubLibraryCard(
                                    item: item,
                                    isSelected: selectedItem?.id == item.id
                                ) {
                                    onSelect(item)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(HubColor.hairline)
                .frame(width: 1)
                .padding(.vertical, 12)

            HubItemDetailPane(
                item: selectedItem,
                emptyTitle: emptyTitle,
                width: detailWidth,
                onCopy: onCopy,
                onDelete: onDelete,
                onRelaunch: onRelaunch,
                onCollect: onCollect
            )
        }
    }
}

private struct HubLibraryCard: View {
    var item: LingobarHubLibraryItem
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    HubBadge(title: item.itemType)
                    if let action = item.action {
                        HubBadge(title: action.title, tint: HubColor.accent)
                    }
                    Spacer(minLength: 8)
                    Text(item.createdAt.hubRelativeString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(HubColor.tertiaryText)
                }
                Text(item.title.isEmpty ? item.visibleText : item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(HubColor.primaryText)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .foregroundStyle(HubColor.secondaryText)
                }
                HStack(spacing: 6) {
                    Image(systemName: "app.connected.to.app.below.fill")
                        .font(.system(size: 10))
                    Text(item.source)
                        .lineLimit(1)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HubColor.tertiaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? HubColor.selectedFill : HubColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? HubColor.accent.opacity(0.5) : HubColor.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HubItemDetailPane: View {
    var item: LingobarHubLibraryItem?
    var emptyTitle: String
    var width: CGFloat
    var onCopy: (LingobarHubLibraryItem) -> Void
    var onDelete: (LingobarHubLibraryItem) -> Void
    var onRelaunch: (LingobarHubLibraryItem) -> Void
    var onCollect: ((LingobarHubLibraryItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let item {
                HStack(alignment: .center, spacing: 8) {
                    HubBadge(title: item.kind == .collection ? "收藏" : "历史", tint: HubColor.accent)
                    HubBadge(title: item.itemType)
                    Spacer()
                    HubIconButton(systemName: "doc.on.doc", help: "复制") {
                        onCopy(item)
                    }
                    HubIconButton(systemName: "trash", help: "删除") {
                        onDelete(item)
                    }
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title.isEmpty ? item.visibleText : item.title)
                        .font(.system(size: 19, weight: .bold))
                        .lineLimit(3)
                        .foregroundStyle(HubColor.primaryText)
                    HStack(spacing: 8) {
                        Text(item.source)
                        Text(item.createdAt.hubRelativeString)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HubColor.tertiaryText)
                }

                Divider().overlay(HubColor.hairline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HubDetailBlock(title: "内容", value: item.visibleText)
                        if !item.note.isEmpty {
                            HubDetailBlock(title: "备注", value: item.note)
                        }
                        if !item.sourceText.isEmpty, item.sourceText != item.visibleText {
                            HubDetailBlock(title: "原文", value: item.sourceText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                }

                VStack(spacing: 8) {
                    Button {
                        onRelaunch(item)
                    } label: {
                        Label("继续处理", systemImage: "arrow.up.forward.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HubPrimaryButtonStyle())

                    if let onCollect, item.kind == .history {
                        Button {
                            onCollect(item)
                        } label: {
                            Label("加入收藏", systemImage: "star")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HubSecondaryButtonStyle())
                    }
                }
                .padding(.bottom, 14)
            } else {
                Spacer()
                HubEmptyState(title: emptyTitle, subtitle: "选择左侧条目查看详情。")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(width: width)
        .frame(maxHeight: .infinity)
    }
}

private struct HubSettingsPane: View {
    @ObservedObject var state: LingobarHubState
    var onOpenAccessibility: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("设置")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(HubColor.primaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(LingobarSettingsSectionDescriptor.all) { section in
                            HubSettingsSubnavButton(
                                title: section.title,
                                needsAttention: section.requiresSetupGate && state.settings.settingsSetupGate.sectionIDsNeedingAttention.contains(section.id),
                                isSelected: state.selectedSettingsSectionID == section.id
                            ) {
                                state.selectedSettingsSectionID = section.id
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(HubColor.hairline)
                    .frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    settingsContent
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 26)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch state.selectedSettingsSectionID {
        case .general:
            GeneralSettingsSection(state: state)
        case .ai:
            AISettingsSection(state: state)
        case .permissions:
            PermissionsSettingsSection(state: state, onOpenAccessibility: onOpenAccessibility)
        case .trigger:
            TriggerSettingsSection(state: state)
        case .actions:
            ActionsSettingsSection(state: state)
        case .collection:
            CollectionSettingsSection(state: state)
        case .about:
            AboutSettingsSection()
        }
    }
}

private struct HubSettingsSubnavButton: View {
    var title: String
    var needsAttention: Bool
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? HubColor.accentText : HubColor.secondaryText)
                    .lineLimit(1)
                if needsAttention {
                    Circle()
                        .fill(HubColor.warn)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? HubColor.selectedFill : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GeneralSettingsSection: View {
    @ObservedObject var state: LingobarHubState

    var body: some View {
        HubSettingsGroup(title: "启动") {
            HubToggleRow(
                title: "开机时启动",
                subtitle: "登录 macOS 后自动运行 Lingobar。",
                isOn: Binding(
                    get: { state.settings.launchAtLogin },
                    set: { value in state.saveLaunchAtLogin(value) }
                )
            )
            HubDivider()
            HubToggleRow(
                title: "显示菜单栏图标",
                subtitle: "常驻入口，打开收藏 / 历史 / 设置。",
                isOn: Binding(
                    get: { state.settings.showMenuBarIcon },
                    set: { value in state.saveShowMenuBarIcon(value) }
                )
            )
        }

        HubSettingsGroup(title: "外观") {
            LazyVGrid(columns: Self.schemeGridColumns, spacing: 10) {
                ForEach(LingobarAppearanceScheme.allCases) { scheme in
                    HubChoiceTile(
                        title: scheme.title,
                        subtitle: scheme.subtitle,
                        isSelected: state.settings.appearanceScheme == scheme
                    ) {
                        state.saveAppearanceScheme(scheme)
                    }
                }
            }
        }
    }

    private static let schemeGridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
}

private struct AISettingsSection: View {
    @ObservedObject var state: LingobarHubState

    var body: some View {
        HubSettingsGroup(title: "模型服务") {
            HubAIProviderPickerRow(
                title: "服务商",
                subtitle: "兼容 OpenAI 的服务可自定义 Base URL。",
                selection: Binding(
                    get: { state.settings.aiProvider },
                    set: { value in state.saveAIProvider(value) }
                )
            )
            HubDivider()
            HubTextFieldRow(
                title: "模型",
                subtitle: "例如 deepseek-v4-flash。",
                text: Binding(
                    get: { state.settings.model },
                    set: { value in state.saveModel(value) }
                )
            )
            if state.settings.aiProvider.showsBaseURLField {
                HubDivider()
                HubTextFieldRow(
                    title: "Base URL",
                    subtitle: "兼容 OpenAI 的接口地址。",
                    text: Binding(
                        get: { state.settings.baseURLString },
                        set: { value in state.saveBaseURL(value) }
                    )
                )
            }
        }

        HubSettingsGroup(title: "API Key") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text("密钥仅保存在本地，输入新 Key 后点击保存。")
                        .font(.system(size: 12))
                        .foregroundStyle(HubColor.secondaryText)
                }

                HStack(spacing: 8) {
                    HubTokenInputField(
                        placeholder: state.tokenFieldPlaceholder,
                        text: $state.tokenDraft,
                        revealToken: state.revealToken,
                        onSubmit: state.saveTokenDraft
                    )
                    .frame(maxWidth: .infinity)

                    Button(state.revealToken ? "隐藏" : "显示") {
                        state.revealToken.toggle()
                    }
                    .buttonStyle(HubSecondaryButtonStyle())
                    .fixedSize()

                    Button("保存") {
                        state.saveTokenDraft()
                    }
                    .buttonStyle(HubPrimaryButtonStyle())
                    .disabled(!state.hasPendingTokenDraft)
                    .fixedSize()

                    Button("清除") {
                        state.clearToken()
                    }
                    .buttonStyle(HubSecondaryButtonStyle())
                    .disabled(!state.isSavedTokenConfigured)
                    .fixedSize()
                }

                HStack(spacing: 8) {
                    HubBadge(
                        title: state.tokenStatusTitle,
                        tint: state.hasPendingTokenDraft ? HubColor.warn : (state.isSavedTokenConfigured ? HubColor.ok : HubColor.tertiaryText)
                    )
                    Text(state.settings.setupGateStatus.aiAccessConfigured ? "AI 服务已配置。" : "需要 API Key、Base URL 和模型才能使用 AI 功能。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(state.settings.setupGateStatus.aiAccessConfigured ? HubColor.ok : HubColor.warn)
                }
            }
        }
    }
}

private struct HubTokenInputField: View {
    var placeholder: String
    @Binding var text: String
    var revealToken: Bool
    var onSubmit: () -> Void

    var body: some View {
        Group {
            if revealToken {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit(onSubmit)
            } else {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit(onSubmit)
            }
        }
        .font(.system(size: 13, design: .monospaced))
        .foregroundStyle(HubColor.primaryText)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HubColor.strongHairline, lineWidth: 1)
        )
    }
}

private struct PermissionsSettingsSection: View {
    @ObservedObject var state: LingobarHubState
    var onOpenAccessibility: () -> Void

    var body: some View {
        HubSettingsGroup(title: "系统权限") {
            HStack(spacing: 12) {
                Image(systemName: state.settings.accessibilityPermissionGranted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(state.settings.accessibilityPermissionGranted ? HubColor.ok : HubColor.warn)
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.settings.accessibilityPermissionGranted ? "辅助功能已授权" : "需要辅助功能授权")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text("授权后，Lingobar 才能从前台 App 读取选中文本。")
                        .font(.system(size: 12))
                        .foregroundStyle(HubColor.secondaryText)
                }
                Spacer()
                Button("打开系统设置", action: onOpenAccessibility)
                    .buttonStyle(HubSecondaryButtonStyle())
            }
        }
    }
}

private struct TriggerSettingsSection: View {
    @ObservedObject var state: LingobarHubState

    var body: some View {
        HubSettingsGroup(title: "划词唤起") {
            HubToggleRow(
                title: "划词后自动触发",
                subtitle: "选中文本后自动准备动作面板。",
                isOn: Binding(
                    get: { state.settings.triggerOnSelection },
                    set: { value in state.saveTriggerOnSelection(value) }
                )
            )
            HubDivider()
            HubToggleRow(
                title: "显示悬浮按钮",
                subtitle: "在选区旁显示一个轻量入口。",
                isOn: Binding(
                    get: { state.settings.showSelectionFloatButton },
                    set: { value in state.saveShowSelectionFloatButton(value) }
                )
            )
        }

        HubSettingsGroup(title: "输入模式") {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("呼出快捷键")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text("无选区时唤起输入模式，把想法改写成自然英文。")
                        .font(.system(size: 12))
                        .foregroundStyle(HubColor.secondaryText)
                }
                Spacer()
                HubHotKeyRecorder(
                    hotKey: Binding(
                        get: { AppSettings.hotKey },
                        set: { hotKey in state.saveHotKey(hotKey) }
                    )
                )
                .frame(width: 168, height: 30)
                Button("重置") {
                    state.resetHotKey()
                }
                .buttonStyle(HubSecondaryButtonStyle())
            }
        }
    }
}

private struct ActionsSettingsSection: View {
    @ObservedObject var state: LingobarHubState

    var body: some View {
        HubSettingsGroup(title: "动作顺序") {
            VStack(spacing: 8) {
                ForEach(state.settings.actionOrder) { action in
                    HStack(spacing: 10) {
                        Image(systemName: action.symbol)
                            .frame(width: 18)
                            .foregroundStyle(HubColor.accentText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(HubColor.primaryText)
                            Text(LanguageAction.shortcut(for: action, in: state.settings.actionOrder))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(HubColor.tertiaryText)
                        }
                        Spacer()
                        HubIconButton(systemName: "chevron.up", help: "上移") {
                            state.moveAction(action, offset: -1)
                        }
                        HubIconButton(systemName: "chevron.down", help: "下移") {
                            state.moveAction(action, offset: 1)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HubColor.card)
                    )
                }
            }
        }

        HubSettingsGroup(title: "默认动作") {
            HubSegmentedActionRow(
                title: "英文选区",
                actions: LingobarSettingsSnapshot.englishDefaultActions,
                selectedAction: state.settings.defaultEnglishAction,
                onSelect: state.saveDefaultEnglishAction
            )
            HubDivider()
            HubSegmentedActionRow(
                title: "中英混合",
                actions: LingobarSettingsSnapshot.chineseMixedDefaultActions,
                selectedAction: state.settings.defaultChineseMixedAction,
                onSelect: state.saveDefaultChineseMixedAction
            )
        }
    }
}

private struct CollectionSettingsSection: View {
    @ObservedObject var state: LingobarHubState

    var body: some View {
        HubSettingsGroup(title: "收藏内容") {
            VStack(spacing: 8) {
                ForEach(LingobarCollectionTarget.allCases) { target in
                    HubChoiceTile(
                        title: target.title,
                        subtitle: target.description,
                        isSelected: state.settings.collectionTarget == target
                    ) {
                        state.saveCollectionTarget(target)
                    }
                }
            }
            HubDivider()
            HubToggleRow(
                title: "自动读取剪贴板兜底",
                subtitle: "选区读取失败时尝试读取剪贴板。",
                isOn: Binding(
                    get: { state.settings.autoReadClipboard },
                    set: { value in state.saveAutoReadClipboard(value) }
                )
            )
        }
    }
}

private struct AboutSettingsSection: View {
    var body: some View {
        HubSettingsGroup(title: "关于") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(HubColor.accent)
                        .frame(width: 46, height: 46)
                        .overlay(
                            Text("L")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Lingobar Hub")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(HubColor.primaryText)
                        Text("收藏、历史与设置")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HubColor.secondaryText)
                    }
                }
                Text("面向划词优先工作流的 macOS 原生 Hub。")
                    .font(.system(size: 12))
                    .foregroundStyle(HubColor.secondaryText)
            }
        }
    }
}

private struct HubSegmentedActionRow: View {
    var title: String
    var actions: [LanguageAction]
    var selectedAction: LanguageAction
    var onSelect: (LanguageAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HubColor.primaryText)
                .frame(width: 86, alignment: .leading)
            HStack(spacing: 6) {
                ForEach(actions) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        Text(action.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedAction == action ? HubColor.accentText : HubColor.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedAction == action ? HubColor.selectedFill : HubColor.chip)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct HubHotKeyRecorder: NSViewRepresentable {
    @Binding var hotKey: LingobarHotKey

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> HubHotKeyRecorderButton {
        let button = HubHotKeyRecorderButton()
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        button.target = context.coordinator
        button.action = #selector(Coordinator.startRecording(_:))
        button.onKeyDown = { [weak coordinator = context.coordinator] event in
            coordinator?.handleKeyDown(event) ?? false
        }
        context.coordinator.updateAppearance(button)
        return button
    }

    func updateNSView(_ button: HubHotKeyRecorderButton, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateTitle(button)
        context.coordinator.updateAppearance(button)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: HubHotKeyRecorder
        private var isRecording = false
        private weak var activeButton: HubHotKeyRecorderButton?
        private var keyMonitor: Any?

        init(_ parent: HubHotKeyRecorder) {
            self.parent = parent
        }

        @objc func startRecording(_ sender: HubHotKeyRecorderButton) {
            isRecording = true
            activeButton = sender
            installKeyMonitor()
            updateTitle(sender)
            updateAppearance(sender)
            sender.window?.makeFirstResponder(sender)
        }

        func handleKeyDown(_ event: NSEvent) -> Bool {
            guard isRecording else {
                return false
            }

            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return true
            }

            guard let nextHotKey = LingobarHotKey(event: event) else {
                return true
            }

            parent.hotKey = nextHotKey
            stopRecording()
            return true
        }

        func updateTitle(_ button: HubHotKeyRecorderButton) {
            button.title = isRecording ? "按下快捷键..." : parent.hotKey.displayString
        }

        func updateAppearance(_ button: HubHotKeyRecorderButton) {
            button.wantsLayer = true
            button.layer?.cornerRadius = 8
            button.layer?.borderWidth = 1
            button.layer?.borderColor = NSColor.white.withAlphaComponent(isRecording ? 0.32 : 0.15).cgColor
            button.layer?.backgroundColor = isRecording
                ? NSColor(calibratedRed: 0.431, green: 0.545, blue: 1.0, alpha: 0.18).cgColor
                : NSColor.white.withAlphaComponent(0.11).cgColor
            button.contentTintColor = NSColor.white.withAlphaComponent(0.92)
        }

        private func installKeyMonitor() {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                let handled: Bool = MainActor.assumeIsolated {
                    guard let self else {
                        return false
                    }
                    return self.handleKeyDown(event)
                }
                return handled ? nil : event
            }
        }

        private func stopRecording() {
            isRecording = false
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            activeButton.map {
                updateTitle($0)
                updateAppearance($0)
            }
        }
    }
}

@MainActor
private final class HubHotKeyRecorderButton: NSButton {
    var onKeyDown: (@MainActor (NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if onKeyDown?(event) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if onKeyDown?(event) == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

private struct HubSettingsHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(HubColor.primaryText)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HubColor.secondaryText)
        }
    }
}

private struct HubSettingsGroup<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HubColor.tertiaryText)
                    .textCase(.uppercase)
            }
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(HubColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(HubColor.hairline, lineWidth: 1)
            )
        }
    }
}

private struct HubToggleRow: View {
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HubColor.primaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(HubColor.secondaryText)
            }
        }
        .toggleStyle(.switch)
    }
}

private struct HubAIProviderPickerRow: View {
    var title: String
    var subtitle: String
    @Binding var selection: LingobarAIProvider

    init(
        title: String,
        subtitle: String,
        selection: Binding<LingobarAIProvider>
    ) {
        self.title = title
        self.subtitle = subtitle
        _selection = selection
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HubColor.primaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(HubColor.secondaryText)
            }
            Spacer()
            Picker("", selection: $selection) {
                ForEach(LingobarAIProvider.allCases) { provider in
                    Text(provider.title).tag(provider)
                }
            }
            .labelsHidden()
            .frame(width: 210)
        }
    }
}

private struct HubTextFieldRow: View {
    var title: String
    var subtitle: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(HubColor.secondaryText)
                }
                Spacer()
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(HubColor.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(HubColor.strongHairline, lineWidth: 1)
                )
        }
    }
}

private struct HubChoiceTile: View {
    var title: String
    var subtitle: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? HubColor.accentText : HubColor.tertiaryText)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HubColor.primaryText)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(HubColor.secondaryText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? HubColor.selectedFill : HubColor.chip)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? HubColor.accent.opacity(0.5) : HubColor.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HubSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HubColor.tertiaryText)
            TextField("搜索", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(HubColor.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(HubColor.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(HubColor.hairline, lineWidth: 1)
        )
    }
}

private struct HubFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? HubColor.accentText : HubColor.secondaryText)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? HubColor.selectedFill : HubColor.chip)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? HubColor.accent.opacity(0.5) : HubColor.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HubBadge: View {
    var title: String
    var tint: Color = HubColor.secondaryText

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(HubColor.chip))
    }
}

private struct HubIconButton: View {
    var systemName: String
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HubColor.secondaryText)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(HubColor.chip)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct HubDetailBlock: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(HubColor.tertiaryText)
                .textCase(.uppercase)
            Text(value.isEmpty ? "无内容" : value)
                .font(.system(size: 13))
                .lineSpacing(3)
                .textSelection(.enabled)
                .foregroundStyle(HubColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct HubEmptyState: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(HubColor.tertiaryText)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HubColor.primaryText)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(HubColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
        }
    }
}

private struct HubSectionLabel: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(HubColor.tertiaryText)
            .textCase(.uppercase)
            .padding(.horizontal, 12)
    }
}

private struct HubDivider: View {
    var body: some View {
        Rectangle()
            .fill(HubColor.hairline)
            .frame(height: 1)
    }
}

private struct HubPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HubColor.accent.opacity(configuration.isPressed ? 0.75 : 1))
            )
    }
}

private struct HubSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(HubColor.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(HubColor.chip.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(HubColor.hairline, lineWidth: 1)
            )
    }
}

private enum HubColor {
    static let window = Color(red: 0.055, green: 0.059, blue: 0.075).opacity(0.96)
    static let card = Color.white.opacity(0.055)
    static let chip = Color.white.opacity(0.07)
    static let selectedFill = Color(red: 0.431, green: 0.545, blue: 1.0).opacity(0.16)
    static let hairline = Color.white.opacity(0.09)
    static let strongHairline = Color.white.opacity(0.15)
    static let accent = Color(red: 0.431, green: 0.545, blue: 1.0)
    static let accentText = Color(red: 0.667, green: 0.714, blue: 1.0)
    static let ok = Color(red: 0.31, green: 0.816, blue: 0.627)
    static let warn = Color(red: 0.878, green: 0.569, blue: 0.361)
    static let primaryText = Color.white.opacity(0.94)
    static let secondaryText = Color.white.opacity(0.66)
    static let tertiaryText = Color.white.opacity(0.42)
    static let chipHover = Color.white.opacity(0.11)
}

private extension Date {
    var hubRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
