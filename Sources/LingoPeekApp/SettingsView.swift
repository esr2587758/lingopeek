import AppKit
import Carbon.HIToolbox
import LingobarCore
import SwiftUI

struct SettingsView: View {
    @State private var selectedSection: LingobarSettingsSectionID = Self.initialSection
    @State private var settings = AppSettings.makeSettingsSnapshot()
    @State private var tokenInput = ""
    @State private var revealToken = false
    @State private var toastMessage: String?
    @State private var actionDropTarget: LanguageAction?
    @State private var aiConnectionTestState = AIConnectionTestState.idle
    @State private var aiConnectionTestID = UUID()
    private let permissionRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static var initialSection: LingobarSettingsSectionID {
        let rawValue = ProcessInfo.processInfo.environment["LINGOPEEK_RENDER_SETTINGS_SECTION"] ?? ""
        return LingobarSettingsSectionID(rawValue: rawValue) ?? .general
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                sidebar
                mainContent
            }
            .frame(width: 760, height: 680)
            .background {
                ZStack {
                    SettingsColor.windowGradient
                    RadialGradient(
                        colors: [
                            Color(red: 85 / 255, green: 103 / 255, blue: 160 / 255).opacity(0.08),
                            Color.clear
                        ],
                        center: .trailing,
                        startRadius: 80,
                        endRadius: 560
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SettingsColor.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 35, x: 0, y: 24)

            if let toastMessage {
                toast(toastMessage)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 760, height: 680)
        .background(Color.clear)
        .onAppear(perform: refreshSettings)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshSettings()
        }
        .onReceive(permissionRefreshTimer) { _ in
            guard selectedSection == .permissions else {
                return
            }
            refreshSettings()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                Text("设置")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .frame(height: 28)
            .foregroundStyle(SettingsColor.text)
            .padding(.top, 2)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)

            ForEach(LingobarSettingsSectionDescriptor.all) { section in
                sidebarButton(section)
            }

            Spacer(minLength: 12)

            if !settings.settingsSetupGate.isReady {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(settings.settingsSetupGate.footerTitle)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(SettingsColor.warn)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    SettingsColor.warn.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                .padding(.bottom, 2)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(width: 212)
        .background(SettingsColor.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(SettingsColor.hairline)
                .frame(width: 1)
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionContent
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 26)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        let section = LingobarSettingsSectionDescriptor.all.first { $0.id == selectedSection }
            ?? LingobarSettingsSectionDescriptor.all[0]

        return VStack(alignment: .leading, spacing: 2) {
            Text(section.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SettingsColor.text)
            Text(section.subtitle)
                .font(.system(size: 12.5))
                .foregroundStyle(SettingsColor.text3)
        }
        .padding(.top, 18)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SettingsColor.hairline)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .general:
            generalSection
        case .ai:
            aiSection
        case .permissions:
            permissionsSection
        case .trigger:
            triggerSection
        case .actions:
            actionsSection
        case .collection:
            collectionSection
        case .about:
            aboutSection
        }
    }

    private var setupGateBannerText: String {
        let status = settings.setupGateStatus
        return switch (status.aiAccessConfigured, status.accessibilityPermissionGranted) {
        case (false, false):
            "配置 AI 服务并授予辅助功能权限后，Lingobar 才能正常使用。"
        case (false, true):
            "配置 AI 服务后，Lingobar 才能正常使用。"
        case (true, false):
            "授予辅助功能权限后，Lingobar 才能读取选区。"
        case (true, true):
            ""
        }
    }

    private var trimmedTokenInput: String {
        tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasPendingTokenInput: Bool {
        !trimmedTokenInput.isEmpty
    }

    private var isSavedTokenConfigured: Bool {
        !settings.apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var tokenFieldPlaceholder: String {
        isSavedTokenConfigured ? "已配置，输入新 API Key 可替换" : "sk-..."
    }

    private var tokenStatusTitle: String {
        if hasPendingTokenInput && isSavedTokenConfigured {
            return "待替换"
        }
        if hasPendingTokenInput {
            return "待保存"
        }
        if isSavedTokenConfigured {
            return "已配置"
        }
        return "未配置"
    }

    private var tokenStatusKind: SettingsBadgeKind {
        if hasPendingTokenInput {
            return .warn
        }
        return isSavedTokenConfigured ? .ok : .muted
    }

    private var draftAIConfiguration: AIProviderConfiguration {
        AIProviderConfiguration(
            apiToken: hasPendingTokenInput ? trimmedTokenInput : settings.apiToken,
            baseURLString: settings.baseURLString,
            model: settings.model
        )
    }

    private var canTestAIConnection: Bool {
        draftAIConfiguration.isUsable && !aiConnectionTestState.isTesting
    }

    private var generalSection: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "启动") {
                SettingsRow(title: "开机时启动", description: "登录 macOS 后自动运行 Lingobar") {
                    SettingsSwitch(isOn: binding(
                        get: \.launchAtLogin,
                        set: { AppSettings.saveLaunchAtLogin($0) }
                    ))
                }
                SettingsRow(title: "显示菜单栏图标", description: "在系统菜单栏常驻入口") {
                    SettingsSwitch(isOn: binding(
                        get: \.showMenuBarIcon,
                        set: { AppSettings.saveShowMenuBarIcon($0) }
                    ))
                }
            }

            SettingsGroup(title: "外观") {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 9),
                        GridItem(.flexible(), spacing: 9)
                    ],
                    spacing: 9
                ) {
                    ForEach(LingobarAppearanceScheme.allCases) { scheme in
                        AppearanceSchemeCard(
                            scheme: scheme,
                            isSelected: settings.appearanceScheme == scheme
                        ) {
                            settings.appearanceScheme = scheme
                            AppSettings.saveAppearanceScheme(scheme)
                        }
                    }
                }
                .padding(12)
            }
        }
    }

    private var aiSection: some View {
        VStack(spacing: 22) {
            if !settings.settingsSetupGate.isReady {
                GateBanner(text: setupGateBannerText)
            }

            SettingsGroup(title: "模型服务") {
                SettingsRow(title: "服务商", description: "选择 AI 接入来源") {
                    SettingsMenu(
                        selection: Binding(
                            get: { settings.aiProvider },
                            set: { provider in
                                settings.selectAIProvider(provider)
                                AppSettings.saveAIProvider(provider)
                                AppSettings.saveModel(settings.model)
                                AppSettings.saveBaseURL(settings.baseURLString)
                                resetAIConnectionTest()
                            }
                        ),
                        options: LingobarAIProvider.allCases,
                        title: \.title
                    )
                    .frame(width: 220)
                }

                SettingsRow(title: "模型") {
                    HStack(spacing: 8) {
                        SettingsTextField(
                            placeholder: settings.aiProvider.defaultModel,
                            text: Binding(
                                get: { settings.model },
                                set: { model in
                                    settings.model = model
                                    AppSettings.saveModel(model)
                                    resetAIConnectionTest()
                                }
                            )
                        )
                        .frame(width: 220)

                        Menu {
                            ForEach(settings.aiProvider.modelOptions, id: \.self) { option in
                                Button(option) {
                                    settings.model = option
                                    AppSettings.saveModel(option)
                                    resetAIConnectionTest()
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("预设")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                        }
                        .buttonStyle(SettingsInlineButtonStyle())
                    }
                }

                SettingsRow(title: "API Key", description: "密钥仅保存在本地，不上传", required: true) {
                    HStack(spacing: 8) {
                        Group {
                            if revealToken {
                                TextField(tokenFieldPlaceholder, text: $tokenInput)
                            } else {
                                SecureField(tokenFieldPlaceholder, text: $tokenInput)
                            }
                        }
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(SettingsColor.text)
                        .padding(.vertical, 8)
                        .padding(.leading, 11)
                        .onSubmit(saveTokenInput)
                        .onChange(of: tokenInput) { _, _ in
                            resetAIConnectionTest()
                        }

                        Button(revealToken ? "隐藏" : "显示") {
                            revealToken.toggle()
                        }
                        .buttonStyle(SettingsInlineButtonStyle())

                        Button("保存", action: saveTokenInput)
                        .buttonStyle(SettingsPrimaryButtonStyle())
                        .disabled(!hasPendingTokenInput)
                    }
                    .frame(width: 326)
                    .background(SettingsColor.chipHover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SettingsColor.hairline, lineWidth: 1)
                    }
                }

                SettingsRow(title: "Token 状态") {
                    HStack(spacing: 8) {
                        SettingsBadge(
                            kind: tokenStatusKind,
                            title: tokenStatusTitle,
                            systemName: isSavedTokenConfigured && !hasPendingTokenInput ? "checkmark" : nil
                        )
                        Button("清除", action: clearSavedToken)
                        .buttonStyle(SettingsInlineButtonStyle())
                        .disabled(!isSavedTokenConfigured)
                    }
                }

                if settings.aiProvider.showsBaseURLField {
                    SettingsRow(title: "Base URL", description: "兼容 OpenAI 协议的接口地址") {
                        SettingsTextField(
                            placeholder: "https://.../v1",
                            text: Binding(
                                get: { settings.baseURLString },
                                set: { value in
                                    settings.baseURLString = value
                                    AppSettings.saveBaseURL(value)
                                    resetAIConnectionTest()
                                }
                            )
                        )
                        .frame(width: 260)
                    }
                }

                SettingsRow(title: "连接测试", description: "使用当前 API Key、Base URL 和模型发送轻量 ping") {
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            SettingsBadge(
                                kind: aiConnectionTestState.badgeKind,
                                title: aiConnectionTestState.title,
                                systemName: aiConnectionTestState.systemName
                            )
                            Button(aiConnectionTestState.isTesting ? "测试中" : "测试") {
                                testAIConnection()
                            }
                            .buttonStyle(SettingsPrimaryButtonStyle())
                            .disabled(!canTestAIConnection)
                        }

                        if let message = aiConnectionTestState.message {
                            Text(message)
                                .font(.system(size: 11.5))
                                .foregroundStyle(SettingsColor.text3)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 326, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private var permissionsSection: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "系统权限") {
                SettingsRow(title: "辅助功能 (Accessibility)", description: "读取其它 App 中的选中文本所必需", required: true) {
                    if settings.accessibilityPermissionGranted {
                        SettingsBadge(kind: .ok, title: "已授权", systemName: "checkmark")
                    } else {
                        Button("去授权") {
                            openAccessibilitySettings()
                            refreshSettings()
                            flash("已打开系统设置")
                        }
                        .buttonStyle(SettingsPrimaryButtonStyle())
                    }
                }
                SettingsRow(title: "麦克风", description: "语音输入暂未启用（MVP 不申请该权限）") {
                    SettingsBadge(kind: .muted, title: "未启用", systemName: nil)
                }
            }

            Text("Lingobar 仅在你划词或主动唤起时读取当前选区，不会在后台持续监听。")
                .font(.system(size: 11.5))
                .foregroundStyle(SettingsColor.text3)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

            if !AppSettings.accessibilityRuntimeIdentityNote.isEmpty {
                Text(AppSettings.accessibilityRuntimeIdentityNote)
                    .font(.system(size: 11.5))
                    .foregroundStyle(SettingsColor.warn)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
        }
    }

    private var triggerSection: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "划词唤起") {
                SettingsRow(title: "选中文本后唤起", description: "在任意 App 选中文字即显示 Lingobar（选区优先）") {
                    SettingsSwitch(isOn: binding(
                        get: \.triggerOnSelection,
                        set: { AppSettings.saveTriggerOnSelection($0) }
                    ))
                }
                SettingsRow(title: "显示划词浮标", description: "先冒出小按钮，点击再展开，避免打扰") {
                    SettingsSwitch(isOn: binding(
                        get: \.showSelectionFloatButton,
                        set: { AppSettings.saveShowSelectionFloatButton($0) }
                    ))
                }
            }

            SettingsGroup(title: "输入模式") {
                SettingsRow(title: "呼出快捷键", description: "无选区时唤起输入模式，把想法改写成自然英文") {
                    HStack(spacing: 8) {
                        HotKeyRecorder(hotKey: hotKeyBinding)
                            .frame(width: 168, height: 28)
                        Button {
                            AppSettings.resetHotKey()
                            refreshSettings()
                            flash("快捷键已恢复默认")
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(SettingsIconButtonStyle())
                        .help("恢复默认")
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "动作顺序") {
                Text("拖动调整 Lingobar 工具条里语言动作的排列优先级。")
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsColor.text3)
                    .padding(.horizontal, 14)
                    .padding(.top, 11)
                    .padding(.bottom, 2)
                VStack(spacing: 5) {
                    ForEach(settings.actionOrder) { action in
                        actionPriorityRow(action)
                            .draggable(action.rawValue)
                            .dropDestination(for: String.self) { items, _ in
                                guard let rawValue = items.first,
                                      let movingAction = LanguageAction(rawValue: rawValue) else {
                                    return false
                                }
                                moveAction(movingAction, before: action)
                                actionDropTarget = nil
                                return true
                            } isTargeted: { isTargeted in
                                actionDropTarget = isTargeted ? action : nil
                            }
                    }
                }
                .padding(8)
            }

            SettingsGroup(title: "默认动作") {
                SettingsRow(title: "选中英文时", description: "打开 Lingobar 的默认动作") {
                    ActionSegmentedControl(
                        actions: LingobarSettingsSnapshot.englishDefaultActions,
                        selection: Binding(
                            get: { settings.defaultEnglishAction },
                            set: { action in
                                if settings.selectDefaultEnglishAction(action) {
                                    AppSettings.saveDefaultEnglishAction(action)
                                }
                            }
                        )
                    )
                }
                SettingsRow(title: "选中中文 / 混合时", description: "中文或混合语言默认动作") {
                    ActionSegmentedControl(
                        actions: LingobarSettingsSnapshot.chineseMixedDefaultActions,
                        selection: Binding(
                            get: { settings.defaultChineseMixedAction },
                            set: { action in
                                if settings.selectDefaultChineseMixedAction(action) {
                                    AppSettings.saveDefaultChineseMixedAction(action)
                                }
                            }
                        )
                    )
                }
            }
        }
    }

    private var collectionSection: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "收藏行为") {
                Text("按下「收藏」时，默认收藏的内容。")
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsColor.text3)
                    .padding(.horizontal, 14)
                    .padding(.top, 11)
                    .padding(.bottom, 2)

                ForEach(LingobarCollectionTarget.allCases) { target in
                    RadioCard(
                        title: target.title,
                        description: target.description,
                        isSelected: settings.collectionTarget == target
                    ) {
                        settings.collectionTarget = target
                        AppSettings.saveCollectionTarget(target)
                    }
                }
            }

            SettingsGroup(title: "其它") {
                SettingsRow(title: "自动读取剪贴板", description: "打开输入模式时，自动填入剪贴板内容") {
                    SettingsSwitch(isOn: binding(
                        get: \.autoReadClipboard,
                        set: { AppSettings.saveAutoReadClipboard($0) }
                    ))
                }
            }
        }
    }

    private var aboutSection: some View {
        SettingsGroup {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SettingsColor.accentWeak)
                    Image(systemName: "gearshape")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(SettingsColor.accentText)
                }
                .frame(width: 56, height: 56)
                .padding(.bottom, 6)

                Text("Lingobar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SettingsColor.text)
                Text("版本 0.1.0 (MVP 原型)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(SettingsColor.text3)
                Text("选区优先的英语阅读、表达与记忆工具。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(SettingsColor.text2)
                    .padding(.top, 6)

                HStack(spacing: 18) {
                    LinkLabel(title: "帮助")
                    LinkLabel(title: "反馈")
                }
                .padding(.top, 14)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
    }

    private func sidebarButton(_ section: LingobarSettingsSectionDescriptor) -> some View {
        let isSelected = selectedSection == section.id
        let needsAttention = settings.settingsSetupGate.sectionIDsNeedingAttention.contains(section.id)

        return Button {
            selectedSection = section.id
            refreshSettings()
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? SettingsColor.accent.opacity(0.2) : SettingsColor.chip)
                    Image(systemName: section.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(section.title)
                            .font(.system(size: 13.5, weight: .semibold))
                        if needsAttention {
                            Circle()
                                .fill(SettingsColor.warn)
                                .frame(width: 6, height: 6)
                        }
                    }
                    Text(section.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? SettingsColor.accentText.opacity(0.7) : SettingsColor.text3)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? SettingsColor.accentText : SettingsColor.text2)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(isSelected ? SettingsColor.accentWeak : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func actionPriorityRow(_ action: LanguageAction) -> some View {
        let index = settings.actionOrder.firstIndex(of: action) ?? 0
        let isDropTarget = actionDropTarget == action

        return HStack(spacing: 11) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SettingsColor.text3)
            Text("\(index + 1)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(SettingsColor.text3)
                .frame(width: 14)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(SettingsColor.chip)
                Image(systemName: action.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsColor.accentText)
            }
            .frame(width: 24, height: 24)
            Text(action.title)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(SettingsColor.text)
            actionNote(for: action)
            Spacer()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(isDropTarget ? SettingsColor.accentWeak : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isDropTarget ? SettingsColor.accent : Color.clear, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func actionNote(for action: LanguageAction) -> some View {
        switch action {
        case .translate:
            ActionNote("英文默认")
        case .grammar:
            ActionNote("仅英文")
        case .rewrite:
            ActionNote("中文默认")
        default:
            EmptyView()
        }
    }

    private func moveAction(_ action: LanguageAction, before target: LanguageAction) {
        guard action != target,
              let fromIndex = settings.actionOrder.firstIndex(of: action),
              let toIndex = settings.actionOrder.firstIndex(of: target) else {
            return
        }

        let moving = settings.actionOrder.remove(at: fromIndex)
        let adjustedIndex = fromIndex < toIndex ? toIndex - 1 : toIndex
        settings.actionOrder.insert(moving, at: adjustedIndex)
        AppSettings.saveActionOrder(settings.actionOrder)
    }

    private func binding(
        get keyPath: WritableKeyPath<LingobarSettingsSnapshot, Bool>,
        set persist: @escaping (Bool) -> Void
    ) -> Binding<Bool> {
        Binding {
            settings[keyPath: keyPath]
        } set: { value in
            settings[keyPath: keyPath] = value
            persist(value)
        }
    }

    private var hotKeyBinding: Binding<LingobarHotKey> {
        Binding {
            AppSettings.hotKey
        } set: { hotKey in
            AppSettings.saveHotKey(hotKey)
            refreshSettings()
        }
    }

    private func refreshSettings() {
        settings = AppSettings.makeSettingsSnapshot()
    }

    private func saveTokenInput() {
        guard !trimmedTokenInput.isEmpty else {
            return
        }
        AppSettings.saveAPIToken(trimmedTokenInput)
        tokenInput = ""
        refreshSettings()
        flash("API Key 已保存")
    }

    private func clearSavedToken() {
        AppSettings.deleteAPIToken()
        tokenInput = ""
        refreshSettings()
        resetAIConnectionTest()
        flash("API Key 已清除")
    }

    private func testAIConnection() {
        let configuration = draftAIConfiguration
        guard configuration.isUsable else {
            aiConnectionTestState = .failure("请先填写 API Key、Base URL 和模型。")
            return
        }

        let testID = UUID()
        aiConnectionTestID = testID
        aiConnectionTestState = .testing

        Task { @MainActor in
            do {
                let response = try await OpenAICompatibleClient(configuration: configuration).testConnection()
                guard aiConnectionTestID == testID else {
                    return
                }
                aiConnectionTestState = .success(Self.compactAIConnectionMessage(response))
                refreshSettings()
            } catch {
                guard aiConnectionTestID == testID else {
                    return
                }
                aiConnectionTestState = .failure(Self.compactAIConnectionError(error))
            }
        }
    }

    private func resetAIConnectionTest() {
        aiConnectionTestID = UUID()
        aiConnectionTestState = .idle
    }

    private static func compactAIConnectionMessage(_ response: String) -> String {
        let compact = response
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compact.isEmpty else {
            return "模型已响应。"
        }
        return "模型返回：\(String(compact.prefix(80)))"
    }

    private static func compactAIConnectionError(_ error: Error) -> String {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let compact = message
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(compact.prefix(140))
    }

    private func flash(_ message: String) {
        withAnimation(.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.18)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.18)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    private func toast(_ message: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
            Text(message)
                .font(.system(size: 12.5, weight: .semibold))
        }
        .foregroundStyle(Color(red: 26 / 255, green: 26 / 255, blue: 31 / 255))
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 15, x: 0, y: 8)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

private enum SettingsColor {
    static let accent = Color(red: 110 / 255, green: 139 / 255, blue: 255 / 255)
    static let accentText = Color(red: 170 / 255, green: 182 / 255, blue: 255 / 255)
    static let accentWeak = Color(red: 110 / 255, green: 139 / 255, blue: 255 / 255).opacity(0.16)
    static let text = Color.white.opacity(0.95)
    static let text2 = Color.white.opacity(0.60)
    static let text3 = Color.white.opacity(0.38)
    static let windowGradient = LinearGradient(
        colors: [
            Color(red: 18 / 255, green: 22 / 255, blue: 34 / 255),
            Color(red: 21 / 255, green: 25 / 255, blue: 38 / 255),
            Color(red: 24 / 255, green: 27 / 255, blue: 40 / 255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let sidebar = Color.black.opacity(0.18)
    static let hairline = Color.white.opacity(0.09)
    static let chip = Color.white.opacity(0.06)
    static let chipHover = Color.white.opacity(0.11)
    static let blackField = Color.black.opacity(0.22)
    static let ok = Color(red: 79 / 255, green: 208 / 255, blue: 160 / 255)
    static let warn = Color(red: 224 / 255, green: 145 / 255, blue: 92 / 255)
}

private struct SettingsGroup<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(SettingsColor.text3)
                    .padding(.leading, 2)
            }
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SettingsColor.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct SettingsRow<Content: View>: View {
    var title: String
    var description: String?
    var required: Bool
    @ViewBuilder var content: Content

    init(
        title: String,
        description: String? = nil,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.required = required
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(SettingsColor.text)
                    if required {
                        Circle()
                            .fill(SettingsColor.warn)
                            .frame(width: 5, height: 5)
                    }
                }
                if let description {
                    Text(description)
                        .font(.system(size: 11.5))
                        .foregroundStyle(SettingsColor.text3)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SettingsColor.hairline)
                .frame(height: 1)
                .padding(.leading, 15)
        }
    }
}

private struct SettingsSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.18)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isOn ? SettingsColor.accent : SettingsColor.chipHover)
                    .frame(width: 42, height: 25)
                Circle()
                    .fill(Color.white)
                    .frame(width: 19, height: 19)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityValue(isOn ? "开启" : "关闭")
    }
}

private struct SettingsMenu<Option: Hashable>: View {
    @Binding var selection: Option
    var options: [Option]
    var title: (Option) -> String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(title(option)) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title(selection))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SettingsColor.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SettingsColor.text3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(SettingsColor.chipHover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(SettingsColor.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(SettingsColor.text)
            .padding(.vertical, 8)
            .padding(.horizontal, 11)
            .background(SettingsColor.chipHover, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(SettingsColor.hairline, lineWidth: 1)
            }
    }
}

private enum SettingsBadgeKind {
    case ok
    case warn
    case muted
}

private enum AIConnectionTestState: Equatable {
    case idle
    case testing
    case success(String)
    case failure(String)

    var isTesting: Bool {
        self == .testing
    }

    var title: String {
        switch self {
        case .idle:
            "未测试"
        case .testing:
            "测试中"
        case .success:
            "联通"
        case .failure:
            "失败"
        }
    }

    var message: String? {
        switch self {
        case .success(let message), .failure(let message):
            message
        case .idle, .testing:
            nil
        }
    }

    var badgeKind: SettingsBadgeKind {
        switch self {
        case .success:
            .ok
        case .failure:
            .warn
        case .idle, .testing:
            .muted
        }
    }

    var systemName: String? {
        switch self {
        case .success:
            "checkmark"
        case .failure:
            "exclamationmark.triangle.fill"
        case .idle, .testing:
            nil
        }
    }
}

private struct SettingsBadge: View {
    var kind: SettingsBadgeKind
    var title: String
    var systemName: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var foregroundColor: Color {
        switch kind {
        case .ok:
            SettingsColor.ok
        case .warn:
            SettingsColor.warn
        case .muted:
            SettingsColor.text3
        }
    }

    private var backgroundColor: Color {
        switch kind {
        case .ok:
            SettingsColor.ok.opacity(0.16)
        case .warn:
            SettingsColor.warn.opacity(0.14)
        case .muted:
            SettingsColor.chipHover
        }
    }
}

private struct SettingsPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(isEnabled ? .white : SettingsColor.text3)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(buttonFill(configuration), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func buttonFill(_ configuration: Configuration) -> Color {
        guard isEnabled else {
            return SettingsColor.chipHover
        }
        return SettingsColor.accent.opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct SettingsInlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isEnabled ? SettingsColor.text3 : SettingsColor.text3.opacity(0.45))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? SettingsColor.chip : Color.clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct SettingsIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isEnabled ? SettingsColor.text2 : SettingsColor.text3.opacity(0.45))
            .frame(width: 24, height: 24)
            .background(configuration.isPressed ? SettingsColor.chipHover : SettingsColor.chip, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct GateBanner: View {
    var text: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(size: 12.5))
        }
        .foregroundStyle(SettingsColor.warn)
        .lineSpacing(3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(SettingsColor.warn.opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(SettingsColor.warn.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct ActionSegmentedControl: View {
    var actions: [LanguageAction]
    @Binding var selection: LanguageAction

    var body: some View {
        HStack(spacing: 2) {
            ForEach(actions) { action in
                Button(action.title) {
                    selection = action
                }
                .buttonStyle(.plain)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(selection == action ? .white : SettingsColor.text2)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(selection == action ? SettingsColor.accent : Color.clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
        .padding(3)
        .background(SettingsColor.blackField, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct ActionNote: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 11))
            .foregroundStyle(SettingsColor.text3)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(SettingsColor.chip, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct AppearanceSchemeCard: View {
    var scheme: LingobarAppearanceScheme
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 7) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(scheme.previewFill)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(scheme.accentFill)
                        .frame(width: 36, height: 8)
                        .padding(.leading, 10)
                        .padding(.bottom, 10)
                }
                .frame(height: 46)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                }

                HStack(spacing: 6) {
                    Text(scheme.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SettingsColor.text)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SettingsColor.accentText)
                    }
                }

                Text(scheme.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(SettingsColor.text3)
            }
            .padding(10)
            .background(isSelected ? SettingsColor.accentWeak : Color.clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(isSelected ? SettingsColor.accent : SettingsColor.hairline, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension LingobarAppearanceScheme {
    var previewFill: Color {
        switch self {
        case .glass: Color(red: 244 / 255, green: 246 / 255, blue: 249 / 255)
        case .tool: Color(red: 28 / 255, green: 29 / 255, blue: 36 / 255)
        case .reader: Color(red: 250 / 255, green: 246 / 255, blue: 239 / 255)
        case .brand: Color(red: 26 / 255, green: 19 / 255, blue: 32 / 255)
        }
    }

    var accentFill: Color {
        switch self {
        case .glass: Color(red: 10 / 255, green: 132 / 255, blue: 255 / 255)
        case .tool: Color(red: 139 / 255, green: 155 / 255, blue: 255 / 255)
        case .reader: Color(red: 192 / 255, green: 103 / 255, blue: 60 / 255)
        case .brand: Color(red: 255 / 255, green: 122 / 255, blue: 89 / 255)
        }
    }
}

private struct RadioCard: View {
    var title: String
    var description: String
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? SettingsColor.accent : SettingsColor.text3, lineWidth: 2)
                    if isSelected {
                        Circle()
                            .fill(SettingsColor.accent)
                            .padding(3)
                    }
                }
                .frame(width: 17, height: 17)
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(SettingsColor.text)
                    Text(description)
                        .font(.system(size: 11.5))
                        .foregroundStyle(SettingsColor.text3)
                        .lineSpacing(3)
                }
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(isSelected ? SettingsColor.accentWeak : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SettingsColor.hairline)
                .frame(height: 1)
                .padding(.leading, 15)
        }
    }
}

private struct LinkLabel: View {
    var title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "link")
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 12.5))
        }
        .foregroundStyle(SettingsColor.accentText)
    }
}

private struct HotKeyRecorder: NSViewRepresentable {
    @Binding var hotKey: LingobarHotKey

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> HotKeyRecorderButton {
        let button = HotKeyRecorderButton()
        button.bezelStyle = .rounded
        button.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        button.target = context.coordinator
        button.action = #selector(Coordinator.startRecording(_:))
        button.onKeyDown = { [weak coordinator = context.coordinator] event in
            coordinator?.handleKeyDown(event) ?? false
        }
        return button
    }

    func updateNSView(_ button: HotKeyRecorderButton, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateTitle(button)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: HotKeyRecorder
        private var isRecording = false
        private weak var activeButton: HotKeyRecorderButton?
        private var keyMonitor: Any?

        init(_ parent: HotKeyRecorder) {
            self.parent = parent
        }

        @objc func startRecording(_ sender: HotKeyRecorderButton) {
            isRecording = true
            activeButton = sender
            installKeyMonitor()
            updateTitle(sender)
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

        func updateTitle(_ button: HotKeyRecorderButton) {
            button.title = isRecording ? "按下快捷键..." : parent.hotKey.displayString
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
            activeButton.map(updateTitle)
        }
    }
}

@MainActor
private final class HotKeyRecorderButton: NSButton {
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
