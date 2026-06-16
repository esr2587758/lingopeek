import AppKit
import LingobarCore
import SwiftUI

struct LingobarRootView: View {
    @ObservedObject var viewModel: LingobarViewModel
    @State private var inputHasMarkedText = false
    @State private var activeResultTextSelection: ResultTextSelection?
    var onClose: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onOpenAccessibility: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.mode == .setup {
                setupPanel
            } else if viewModel.mode == .selection {
                selectionPill
                resultPanel(showActionBar: true)
            } else {
                inputPill
                if viewModel.isLoading || viewModel.showsResult {
                    inputResultPanel
                }
            }
        }
        .frame(
            width: 720,
            height: rootHeight,
            alignment: .top
        )
        .onExitCommand(perform: onClose)
        .onChange(of: viewModel.mode) { _, _ in
            activeResultTextSelection = nil
        }
        .onChange(of: viewModel.action) { _, _ in
            activeResultTextSelection = nil
        }
        .onChange(of: viewModel.result) { _, _ in
            activeResultTextSelection = nil
        }
    }

    private var setupPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.lingoAccentText)
                    .frame(width: 34, height: 34)
                    .background(Color.lingoAccent.opacity(0.16), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("完成 Lingobar 设置")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.lingoText)
                    Text("需要 AI 设置和辅助功能权限后才能使用语言功能。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.lingoMuted)
                }
                Spacer()
                inputCloseButton {
                    onClose()
                }
            }

            VStack(spacing: 10) {
                setupRequirementRow(
                    title: "AI 设置",
                    detail: "配置 API token、base URL 和 model",
                    isComplete: viewModel.setupGateStatus.aiAccessConfigured
                )
                setupRequirementRow(
                    title: "辅助功能权限",
                    detail: "允许 Lingobar 稳定读取选区",
                    isComplete: viewModel.setupGateStatus.accessibilityPermissionGranted
                )
            }

            HStack(spacing: 8) {
                footerButton("打开 AI 设置", systemName: "gearshape", prominent: true) {
                    onOpenSettings()
                }
                footerButton("打开辅助功能设置", systemName: "accessibility") {
                    onOpenAccessibility()
                }
                Spacer()
            }

            Text("设置完成后，再次按快捷键进入正常工作流。")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.lingoSubtle)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(surfaceBackground)
        .clipShape(surfaceShape)
        .overlay(surfaceBorder)
        .lingobarShadow()
    }

    private var selectionPill: some View {
        ZStack {
            HStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    WindowDragHandle()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        HStack(spacing: 6) {
                            Text(selectionSourceLabel)
                            Circle()
                                .fill(Color.lingoSubtle)
                                .frame(width: 3, height: 3)
                            Text(selectionDocumentLabel)
                        }
                        .lineLimit(1)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.lingoSubtle)
                        .fixedSize(horizontal: true, vertical: false)

                        Text(viewModel.selectedText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.lingoMuted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                HStack(spacing: 2) {
                    dragIcon

                    iconButton(
                        systemName: "pin",
                        help: viewModel.isPinned ? "已固定" : "固定",
                        foreground: viewModel.isPinned ? Color.lingoAccentText : Color.lingoSubtle
                    ) {
                        viewModel.togglePinned()
                    }

                    iconButton(systemName: "xmark", help: "关闭") {
                        onClose()
                    }
                }
                .padding(2)
                .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.leading, 15)
            .padding(.trailing, 8)
            .padding(.vertical, 7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(pillBackground)
        .overlay(pillBorder)
        .lingobarShadow(pinned: viewModel.isPinned)
    }

    private var inputPill: some View {
        HStack(alignment: .center, spacing: 8) {
            ZStack(alignment: .leading) {
                LingobarInputTextView(
                    text: $viewModel.inputText,
                    onMarkedTextChanged: { inputHasMarkedText = $0 }
                ) {
                    viewModel.submitInput()
                }
                .frame(height: 46)

                if viewModel.inputText.isEmpty && !inputHasMarkedText {
                    Text(inputPlaceholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.lingoPlaceholder)
                        .lineLimit(2)
                        .lineSpacing(3)
                        .frame(height: 46, alignment: .center)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: inputFieldWidth, height: 46, alignment: .topLeading)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                inputIconButton(systemName: "mic", highlighted: false, dimmed: false, help: "语音输入") {
                    viewModel.status = "语音输入暂未启用"
                }

                inputIconButton(
                    systemName: "arrow.right",
                    highlighted: true,
                    dimmed: viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    help: "改写"
                ) {
                    viewModel.submitInput()
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                inputCloseButton {
                    onClose()
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.leading, 17)
        .padding(.trailing, 11)
        .padding(.vertical, 10)
        .frame(height: 72)
        .background {
            ZStack {
                pillBackground
                dragSurface()
            }
        }
        .overlay(pillBorder)
        .lingobarShadow()
    }

    private var inputPlaceholder: String {
        "输入中文 / 英文 / 粗糙想法，按 ↩ 改写成自然英文"
    }

    private var inputFieldWidth: CGFloat {
        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = text.isEmpty ? inputPlaceholder : text
        let measuredWidth = (displayText as NSString).boundingRect(
            with: NSSize(width: 540, height: 80),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: NSFont.systemFont(ofSize: 15)]
        ).width
        return min(max(ceil(measuredWidth) + 8, 160), 540)
    }

    private var inputResultPanel: some View {
        VStack(spacing: 0) {
            panelTitle("改写 · 自然英文", shortcut: viewModel.action.shortcut)
            panelBody(height: 176)

            if !viewModel.isLoading {
                footer
            }
        }
        .background(surfaceBackground)
        .clipShape(surfaceShape)
        .overlay(surfaceBorder)
        .lingobarShadow(pinned: viewModel.isPinned)
        .frame(maxWidth: .infinity)
    }
    private func resultPanel(showActionBar: Bool) -> some View {
        VStack(spacing: 0) {
            if showActionBar {
                actionBar
            }

            panelTitle(viewModel.result.title, shortcut: viewModel.action.shortcut)
            panelBody(height: viewModel.mode == .selection ? 300 : 176)

            if !viewModel.isLoading {
                footer
            }
        }
        .background(surfaceBackground)
        .clipShape(surfaceShape)
        .overlay(surfaceBorder)
        .lingobarShadow(pinned: viewModel.isPinned)
        .frame(maxWidth: .infinity)
    }

    private var actionBar: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.actions) { action in
                let available = viewModel.isAvailable(action)
                Button {
                    viewModel.perform(action)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: action.symbol)
                            .font(.system(size: 13, weight: .semibold))
                        Text(action.title)
                            .font(.system(size: 13, weight: viewModel.action == action ? .semibold : .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundStyle(actionForeground(action, available: available))
                    .hoverChrome(
                        fill: actionFill(action, available: available),
                        hoverFill: actionHoverFill(action, available: available),
                        stroke: actionStroke(action, available: available),
                        hoverStroke: actionHoverStroke(action, available: available),
                        cornerRadius: 9
                    )
                }
                .buttonStyle(.plain)
                .disabled(!available)
                .help(available ? action.title : "\(action.title)仅支持英文内容")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dragSurface())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func panelTitle(_ title: String, shortcut: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.lingoAccent)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.lingoMuted)
            Spacer()
            Text(shortcut)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.lingoSubtle)
        }
        .padding(.top, 13)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
        .textSelection(.enabled)
    }

    private func panelBody(height: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.isLoading {
                    loadingRow("正在生成…")
                } else {
                    resultBody
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 14)
            .textSelection(.enabled)
        }
        .frame(minHeight: 176)
        .frame(height: height)
    }

    private var footer: some View {
        HStack(spacing: 5) {
            footerButton("复制", systemName: "doc.on.doc") {
                viewModel.copyResult()
            }
            footerButton("收藏", systemName: "star") {
                viewModel.perform(.collect)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dragSurface())
    }

    private var firstChip: String {
        viewModel.result.chips.first ?? viewModel.result.title
    }

    private func selectableText(
        _ text: String,
        id: String,
        size: CGFloat,
        weight: NSFont.Weight = .regular,
        color: NSColor,
        lineSpacing: CGFloat = 0
    ) -> some View {
        SelectableResultText(
            sourceID: "\(viewModel.action.rawValue)-\(id)",
            text: text,
            font: .systemFont(ofSize: size, weight: weight),
            textColor: color,
            lineSpacing: lineSpacing,
            activeSelection: $activeResultTextSelection,
            onCopy: { selectedText in
                viewModel.copyInlineSelection(selectedText)
                activeResultTextSelection = nil
            },
            onWake: { selectedText in
                viewModel.reopenInlineSelection(selectedText)
                activeResultTextSelection = nil
            },
            onCollect: { selectedText in
                viewModel.collectInlineSelection(selectedText)
                activeResultTextSelection = nil
            }
        )
    }

    private var rootHeight: CGFloat {
        switch viewModel.mode {
        case .setup:
            360
        case .selection:
            viewModel.isLoading ? 441 : 480
        case .input:
            if viewModel.isLoading {
                287
            } else {
                viewModel.showsResult ? 377 : 72
            }
        }
    }

    private var selectionSourceLabel: String {
        viewModel.selectionSource
    }

    private var selectionDocumentLabel: String {
        "选区"
    }

    private var translationVariantRows: [LingobarRow] {
        let preferredLabels = ["通用", "书面", "意译"]
        let preferredRows = preferredLabels.compactMap { label in
            viewModel.result.rows.first { $0.label == label }
        }
        if !preferredRows.isEmpty {
            return preferredRows
        }
        return viewModel.result.rows.filter { row in
            !["原文", "重点", "语感", "说明", "备注"].contains(row.label)
        }
    }

    private var translationNoteRows: [LingobarRow] {
        viewModel.result.rows.filter { row in
            ["重点", "语感", "说明", "备注"].contains(row.label)
        }
    }

    @ViewBuilder
    private var resultBody: some View {
        switch viewModel.action {
        case .translate:
            VStack(spacing: 0) {
                if translationVariantRows.isEmpty {
                    selectableText(
                        viewModel.result.summary,
                        id: "translate-summary",
                        size: 16,
                        color: .lingoTextColor,
                        lineSpacing: 4
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(translationVariantRows, id: \.label) { row in
                        translationVariant(row)
                    }
                }
            }
            if !translationNoteRows.isEmpty {
                VStack(spacing: 0) {
                    ForEach(translationNoteRows, id: \.label) { row in
                        resultRow(row)
                    }
                }
            }
        case .grammar:
            VStack(spacing: 0) {
                ForEach(viewModel.result.rows, id: \.label) { row in
                    grammarBlock(row)
                }
            }
            keyCard(title: viewModel.result.defaultCollectionTitle, detail: "可复用句型")
                .background(Color.lingoAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .rewrite:
            selectableText(
                viewModel.result.summary,
                id: "rewrite-summary",
                size: 16,
                weight: .medium,
                color: .lingoTextColor,
                lineSpacing: 4
            )
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.lingoAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.lingoHairline, lineWidth: 1)
                )
            VStack(spacing: 0) {
                ForEach(viewModel.result.rows, id: \.label) { row in
                    rewriteVariant(row)
                }
            }
        case .examples:
            Text(viewModel.result.sideTitle)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.lingoSubtle)
            VStack(spacing: 0) {
                if !viewModel.result.summary.isEmpty {
                    exampleItem(index: 1, text: viewModel.result.summary, id: "examples-summary")
                }
                ForEach(Array(viewModel.result.rows.enumerated()), id: \.element.label) { index, row in
                    exampleItem(index: index + 2, text: row.value, id: "examples-\(index)-\(row.label)")
                }
            }
        case .pronounce:
            HStack(spacing: 14) {
                Image(systemName: "play.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.lingoAccent, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    selectableText(
                        viewModel.result.defaultCollectionTitle.isEmpty ? firstChip : viewModel.result.defaultCollectionTitle,
                        id: "pronounce-title",
                        size: 19,
                        weight: .semibold,
                        color: .lingoTextColor
                    )
                    selectableText(
                        viewModel.result.summary,
                        id: "pronounce-summary",
                        size: 14,
                        color: .lingoAccentTextColor
                    )
                }
            }
            VStack(spacing: 0) {
                ForEach(viewModel.result.rows, id: \.label) { row in
                    resultRow(row)
                }
            }
        case .copy, .collect:
            selectableText(
                viewModel.result.summary,
                id: "utility-summary",
                size: 15,
                color: .lingoTextColor,
                lineSpacing: 3
            )
        }
    }

    private func resultRow(_ row: LingobarRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(row.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
                .frame(width: 68, alignment: .leading)
            selectableText(
                row.value,
                id: "row-\(row.label)",
                size: 12,
                color: .lingoMutedColor,
                lineSpacing: 2
            )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func keyCard(title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            selectableText(
                title,
                id: "key-card-title",
                size: 14,
                weight: .semibold,
                color: .lingoAccentTextColor
            )
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Color.lingoMuted)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func grammarBlock(_ row: LingobarRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(row.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                selectableText(
                    row.value,
                    id: "grammar-\(row.label)",
                    size: 13.5,
                    weight: .medium,
                    color: .lingoTextColor
                )
                Text("语法结构")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.lingoSubtle)
            }
        }
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func rewriteVariant(_ row: LingobarRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(row.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            selectableText(
                row.value,
                id: "rewrite-\(row.label)",
                size: 14,
                color: .lingoMutedColor,
                lineSpacing: 2
            )
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func translationVariant(_ row: LingobarRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(row.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.lingoAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            selectableText(
                row.value,
                id: "translate-\(row.label)",
                size: 15,
                color: .lingoTextColor,
                lineSpacing: 3
            )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func exampleItem(index: Int, text: String, id: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(index)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.lingoSubtle)
                .frame(width: 18, height: 18)
                .background(Color.lingoChip, in: Circle())
            selectableText(
                text,
                id: id,
                size: 14,
                color: .lingoTextColor,
                lineSpacing: 2
            )
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private func loadingRow(_ text: String) -> some View {
        HStack(spacing: 9) {
            LingobarSpinner()
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.lingoSubtle)
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
    }

    private func setupRequirementRow(title: String, detail: String, isComplete: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isComplete ? Color.green.opacity(0.82) : Color.lingoAccentText)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.lingoText)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lingoMuted)
            }
            Spacer()
            Text(isComplete ? "已完成" : "待设置")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isComplete ? Color.green.opacity(0.82) : Color.lingoAccentText)
        }
        .padding(12)
        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var surfaceBackground: some View {
        glassBackground(cornerRadius: 16)
    }

    private var surfaceBorder: some View {
        glassBorder(cornerRadius: 16, pinned: viewModel.isPinned)
    }

    private var surfaceShape: some Shape {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    private var pillBackground: some View {
        glassBackground(cornerRadius: 13)
    }

    private var pillBorder: some View {
        glassBorder(cornerRadius: 13, pinned: viewModel.isPinned)
    }

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.lingoGlass)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func glassBorder(cornerRadius: CGFloat, pinned: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(pinned ? Color.lingoAccent : Color.lingoHairline, lineWidth: 1)
    }

    private func dragSurface(fill: Color = Color.clear) -> some View {
        ZStack {
            fill
            WindowDragHandle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func actionForeground(_ action: LanguageAction, available: Bool) -> Color {
        guard available else {
            return Color.lingoSubtle.opacity(0.55)
        }
        return viewModel.action == action ? Color.lingoAccentText : Color.lingoMuted
    }

    private func actionFill(_ action: LanguageAction, available: Bool) -> Color {
        guard available else {
            return Color.clear
        }
        return viewModel.action == action ? Color.lingoAccentWeak : Color.clear
    }

    private func actionHoverFill(_ action: LanguageAction, available: Bool) -> Color {
        guard available else {
            return Color.clear
        }
        return viewModel.action == action ? Color.lingoAccentWeak : Color.lingoChip
    }

    private func actionStroke(_ action: LanguageAction, available: Bool) -> Color {
        viewModel.action == action || !available ? Color.clear : Color.lingoHairline
    }

    private func actionHoverStroke(_ action: LanguageAction, available: Bool) -> Color {
        viewModel.action == action || !available ? Color.clear : Color.lingoHairline
    }

    private func iconButton(
        systemName: String,
        help: String,
        foreground: Color = Color.lingoSubtle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .hoverChrome(
                    fill: Color.clear,
                    hoverFill: Color.lingoChipHover,
                    cornerRadius: 7
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .help(help)
    }

    private var dragIcon: some View {
        ZStack {
            WindowDragHandle()
            HStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.lingoSubtle)
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
                .allowsHitTesting(false)
        }
        .frame(width: 24, height: 24)
        .hoverChrome(fill: Color.clear, hoverFill: Color.lingoChipHover, cornerRadius: 7)
        .help("拖动")
    }

    private func inputIconButton(
        systemName: String,
        highlighted: Bool,
        dimmed: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(highlighted ? Color.white : Color.lingoMuted)
        .hoverChrome(
            fill: highlighted ? Color.lingoAccent : Color.lingoChip,
            hoverFill: highlighted ? Color.lingoAccent.opacity(0.92) : Color.lingoChipHover,
            stroke: Color.clear,
            hoverStroke: highlighted ? Color.clear : Color.white.opacity(0.12),
            cornerRadius: 9
        )
        .opacity(dimmed ? 0.38 : 1)
        .help(help)
    }

    private func inputCloseButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.lingoMuted)
        .hoverChrome(
            fill: Color.clear,
            hoverFill: Color.lingoChipHover,
            cornerRadius: 9
        )
        .help("关闭")
    }

    private func footerButton(
        _ title: String,
        systemName: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .frame(height: 30)
            .padding(.horizontal, prominent ? 13 : 11)
            .foregroundStyle(prominent ? Color.white : Color.lingoMuted)
            .hoverChrome(
                fill: prominent ? Color.lingoAccent : Color.lingoChip,
                hoverFill: prominent ? Color.lingoAccent.opacity(0.92) : Color.lingoChipHover,
                stroke: Color.clear,
                hoverStroke: prominent ? Color.clear : Color.white.opacity(0.12),
                cornerRadius: 8
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func lingobarShadow(radius: CGFloat = 35, y: CGFloat = 30, pinned: Bool = false) -> some View {
        self
            .shadow(
                color: pinned ? Color.black.opacity(0.70) : Color.lingoShadow,
                radius: pinned ? 30 : radius,
                x: 0,
                y: pinned ? 24 : y
            )
    }

    func hoverChrome(
        fill: Color,
        hoverFill: Color,
        stroke: Color = Color.clear,
        hoverStroke: Color? = nil,
        cornerRadius: CGFloat
    ) -> some View {
        modifier(
            HoverChrome(
                fill: fill,
                hoverFill: hoverFill,
                stroke: stroke,
                hoverStroke: hoverStroke ?? stroke,
                cornerRadius: cornerRadius
            )
        )
    }
}

private struct HoverChrome: ViewModifier {
    @State private var isHovered = false

    var fill: Color
    var hoverFill: Color
    var stroke: Color
    var hoverStroke: Color
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? hoverFill : fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isHovered ? hoverStroke : stroke, lineWidth: 1)
            )
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.14), value: isHovered)
    }
}

private struct LingobarSpinner: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lingoChipHover, lineWidth: 2)
            Circle()
                .trim(from: 0.12, to: 0.78)
                .stroke(
                    Color.lingoAccent,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
        }
        .frame(width: 15, height: 15)
        .onAppear {
            withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}

private struct ResultTextSelection: Equatable {
    var sourceID: String
    var text: String
    var anchor: CGPoint
}

private struct SelectableResultText: View {
    var sourceID: String
    var text: String
    var font: NSFont
    var textColor: NSColor
    var lineSpacing: CGFloat
    @Binding var activeSelection: ResultTextSelection?
    var onCopy: (String) -> Void
    var onWake: (String) -> Void
    var onCollect: (String) -> Void

    private var selectedText: String? {
        guard activeSelection?.sourceID == sourceID else {
            return nil
        }
        return activeSelection?.text
    }

    private var selectionAnchor: CGPoint? {
        guard activeSelection?.sourceID == sourceID else {
            return nil
        }
        return activeSelection?.anchor
    }

    var body: some View {
        SelectableTextView(
            text: text,
            font: font,
            textColor: textColor,
            lineSpacing: lineSpacing
        ) { selection, anchor in
            if selection.isEmpty {
                if activeSelection?.sourceID == sourceID {
                    activeSelection = nil
                }
            } else {
                activeSelection = ResultTextSelection(sourceID: sourceID, text: selection, anchor: anchor)
            }
        }
        .overlay(alignment: .topLeading) {
            GeometryReader { proxy in
                if let selectedText, let selectionAnchor {
                    InlineSelectionToolbar(
                        selectedText: selectedText,
                        onCopy: onCopy,
                        onWake: onWake,
                        onCollect: onCollect
                    )
                    .position(toolbarPosition(for: selectionAnchor, in: proxy.size))
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .animation(.easeOut(duration: 0.14), value: selectedText)
    }

    private func toolbarPosition(for anchor: CGPoint, in size: CGSize) -> CGPoint {
        let toolbarWidth: CGFloat = 86
        let toolbarHeight: CGFloat = 30
        let preferredX = anchor.x + toolbarWidth / 2 + 8
        let preferredY = anchor.y
        return CGPoint(
            x: min(max(preferredX, toolbarWidth / 2), max(toolbarWidth / 2, size.width - toolbarWidth / 2)),
            y: min(max(preferredY, toolbarHeight / 2), max(toolbarHeight / 2, size.height - toolbarHeight / 2))
        )
    }
}

private struct InlineSelectionToolbar: View {
    var selectedText: String
    var onCopy: (String) -> Void
    var onWake: (String) -> Void
    var onCollect: (String) -> Void

    var body: some View {
        HStack(spacing: 2) {
            toolbarButton(systemName: "doc.on.doc", help: "复制") {
                onCopy(selectedText)
            }
            toolbarButton(systemName: "sparkles", help: "用选中文本唤醒 Lingobar", foreground: Color.lingoAccentText) {
                onWake(selectedText)
            }
            toolbarButton(systemName: "star", help: "收藏") {
                onCollect(selectedText)
            }
        }
        .padding(2)
        .background(Color.lingoGlass2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.20), radius: 8, y: 4)
    }

    private func toolbarButton(
        systemName: String,
        help: String,
        foreground: Color = Color.lingoMuted,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12.5, weight: .semibold))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
                .hoverChrome(
                    fill: Color.clear,
                    hoverFill: Color.lingoChipHover,
                    cornerRadius: 6
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .help(help)
    }
}

private struct SelectableTextView: NSViewRepresentable {
    var text: String
    var font: NSFont
    var textColor: NSColor
    var lineSpacing: CGFloat
    var onSelectionChanged: (String, CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> LingobarSelectableNSTextView {
        let textView = LingobarSelectableNSTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(calibratedRed: 0.43, green: 0.55, blue: 1.0, alpha: 0.34),
            .foregroundColor: NSColor.white
        ]
        context.coordinator.applyContent(to: textView)
        return textView
    }

    func updateNSView(_ textView: LingobarSelectableNSTextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyContent(to: textView)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView textView: LingobarSelectableNSTextView,
        context: Context
    ) -> CGSize? {
        context.coordinator.parent = self
        context.coordinator.applyContent(to: textView)
        let width = max(proposal.width ?? textView.fittingSize.width, 1)
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return CGSize(width: width, height: ceil(font.ascender - font.descender + font.leading))
        }
        textContainer.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = layoutManager.usedRect(for: textContainer).height
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        return CGSize(width: width, height: max(ceil(usedHeight), lineHeight))
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SelectableTextView

        init(_ parent: SelectableTextView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0,
                  selectedRange.location != NSNotFound,
                  NSMaxRange(selectedRange) <= (textView.string as NSString).length else {
                parent.onSelectionChanged("", .zero)
                return
            }
            let selectedText = (textView.string as NSString)
                .substring(with: selectedRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            parent.onSelectionChanged(selectedText, selectionAnchor(in: textView, selectedRange: selectedRange))
        }

        private func selectionAnchor(in textView: NSTextView, selectedRange: NSRange) -> CGPoint {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return CGPoint(x: textView.bounds.midX, y: textView.bounds.midY)
            }

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: selectedRange,
                actualCharacterRange: nil
            )
            layoutManager.ensureLayout(for: textContainer)
            var selectionRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            selectionRect.origin.x += textView.textContainerOrigin.x
            selectionRect.origin.y += textView.textContainerOrigin.y

            let y = textView.isFlipped ? selectionRect.midY : textView.bounds.height - selectionRect.midY
            return CGPoint(x: selectionRect.maxX, y: y)
        }

        func applyContent(to textView: NSTextView) {
            guard textView.string != parent.text else {
                return
            }
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = parent.lineSpacing
            let attributedText = NSAttributedString(
                string: parent.text,
                attributes: [
                    .font: parent.font,
                    .foregroundColor: parent.textColor,
                    .paragraphStyle: paragraph
                ]
            )
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
}

private final class LingobarSelectableNSTextView: NSTextView {
    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

private struct LingobarInputTextView: NSViewRepresentable {
    @Binding var text: String
    var onMarkedTextChanged: (Bool) -> Void
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        let textView = LingobarInputNSTextView(frame: .zero, textContainer: textContainer)
        scrollView.documentView = textView

        textView.delegate = context.coordinator
        textView.onMarkedTextChanged = { [weak coordinator = context.coordinator] isMarked in
            coordinator?.setMarkedTextActive(isMarked)
        }
        textView.string = text
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = NSColor(calibratedRed: 0.88, green: 0.88, blue: 0.90, alpha: 1)
        textView.insertionPointColor = NSColor(calibratedRed: 0.55, green: 0.61, blue: 1.0, alpha: 1)
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 12)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 46)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if context.coordinator.shouldApplyExternalText(text, to: textView) {
            textView.string = text
            context.coordinator.didApplyExternalText(text)
        }
        context.coordinator.updateMarkedTextState(textView)
        context.coordinator.centerText(in: textView)

        if !context.coordinator.didFocus {
            context.coordinator.focus(textView)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LingobarInputTextView
        var didFocus = false
        private var markedTextActive = false
        private var isCenteringText = false
        private var lastTextFromTextView: String

        init(_ parent: LingobarInputTextView) {
            self.parent = parent
            self.lastTextFromTextView = parent.text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            syncTextFromTextView(textView)
            centerText(in: textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            updateMarkedTextState(textView)
            centerText(in: textView)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else {
                return false
            }
            let flags = NSApp.currentEvent?.modifierFlags ?? []
            if flags.contains(.shift) || flags.contains(.option) {
                textView.insertText("\n", replacementRange: textView.selectedRange())
                syncTextFromTextView(textView)
                centerText(in: textView)
                return true
            }
            syncTextFromTextView(textView)
            parent.onSubmit()
            return true
        }

        func setMarkedTextActive(_ isActive: Bool) {
            setMarkedTextActive(isActive, forceNotify: true)
        }

        func updateMarkedTextState(_ textView: NSTextView) {
            setMarkedTextActive(textView.hasMarkedText(), forceNotify: textView.string.isEmpty)
        }

        func shouldApplyExternalText(_ text: String, to textView: NSTextView) -> Bool {
            guard !textView.hasMarkedText(), !markedTextActive else {
                return false
            }
            return textView.string != text && text != lastTextFromTextView
        }

        func didApplyExternalText(_ text: String) {
            lastTextFromTextView = text
            setMarkedTextActive(false, forceNotify: text.isEmpty)
        }

        private func syncTextFromTextView(_ textView: NSTextView) {
            let currentText = textView.string
            lastTextFromTextView = currentText
            if parent.text != currentText {
                parent.text = currentText
            }
            updateMarkedTextState(textView)
        }

        private func setMarkedTextActive(_ isActive: Bool, forceNotify: Bool) {
            let changed = markedTextActive != isActive
            markedTextActive = isActive
            if changed || forceNotify {
                parent.onMarkedTextChanged(isActive)
            }
        }

        func centerText(in textView: NSTextView) {
            guard !isCenteringText, textView.bounds.height > 0 else {
                return
            }
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return
            }

            isCenteringText = true
            defer { isCenteringText = false }

            layoutManager.ensureLayout(for: textContainer)
            let lineHeight = textView.font.map { ceil($0.ascender - $0.descender + $0.leading) } ?? 18
            let usedHeight = max(layoutManager.usedRect(for: textContainer).height, lineHeight)
            let verticalInset = max(4, floor((textView.bounds.height - usedHeight) / 2))
            let currentInset = textView.textContainerInset
            guard abs(currentInset.height - verticalInset) > 0.5 || currentInset.width != 0 else {
                return
            }

            textView.textContainerInset = NSSize(width: 0, height: verticalInset)
        }

        func focus(_ textView: NSTextView, attemptsRemaining: Int = 4) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self, weak textView] in
                guard let self, let textView, !self.didFocus else {
                    return
                }

                if let window = textView.window {
                    self.didFocus = window.makeFirstResponder(textView)
                }

                if !self.didFocus, attemptsRemaining > 0 {
                    self.focus(textView, attemptsRemaining: attemptsRemaining - 1)
                }
            }
        }
    }
}

private final class LingobarInputNSTextView: NSTextView {
    var onMarkedTextChanged: ((Bool) -> Void)?

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        onMarkedTextChanged?(hasMarkedText())
    }

    override func unmarkText() {
        super.unmarkText()
        onMarkedTextChanged?(hasMarkedText())
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        if hasMarkedText() {
            onMarkedTextChanged?(true)
        }
    }
}

private extension NSColor {
    static let lingoTextColor = NSColor(calibratedWhite: 1.0, alpha: 0.95)
    static let lingoMutedColor = NSColor(calibratedWhite: 1.0, alpha: 0.60)
    static let lingoAccentTextColor = NSColor(calibratedRed: 170 / 255, green: 182 / 255, blue: 1.0, alpha: 1.0)
}
