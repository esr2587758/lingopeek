import LingobarCore
import SwiftUI

public struct GrammarResultPanel: View {
    public var result: GrammarResult

    @State private var selectedView: GrammarVizView
    @State private var hoveredRole: GrammarRole?
    @State private var openChunkID: String?

    public init(result: GrammarResult, initialView: GrammarVizView = .annotated) {
        self.result = result
        self._selectedView = State(initialValue: initialView)
    }

    public var body: some View {
        VStack(spacing: 0) {
            sentenceSection
            viewTabs
            visualizationSection
            patternSection
            knowledgeSection
        }
        .frame(maxWidth: .infinity)
    }

    private var sentenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.sourceSentence)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color.lingoText)
                .lineSpacing(9)
                .fixedSize(horizontal: false, vertical: true)

            Text(result.chineseMeaning)
                .font(.system(size: 13.5))
                .foregroundStyle(Color.lingoMuted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if !result.analysisScopeNote.isEmpty {
                Text(result.analysisScopeNote)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Color.lingoSubtle)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private var viewTabs: some View {
        GrammarWrapLayout(spacing: 6, rowSpacing: 6) {
            ForEach(GrammarVizView.allCases) { view in
                Button {
                    selectedView = view
                    hoveredRole = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: view.symbol)
                            .font(.system(size: 15, weight: .medium))
                        Text(view.title)
                            .font(.system(size: 12.5, weight: selectedView == view ? .semibold : .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .foregroundStyle(selectedView == view ? Color.lingoAccentText : Color.lingoMuted)
                    .grammarHoverChrome(
                        fill: selectedView == view ? Color.lingoAccentWeak : Color.clear,
                        hoverFill: selectedView == view ? Color.lingoAccentWeak : Color.lingoChip,
                        stroke: selectedView == view ? Color.clear : Color.lingoHairline,
                        hoverStroke: selectedView == view ? Color.clear : Color.lingoHairline,
                        cornerRadius: 9
                    )
                }
                .buttonStyle(.plain)
                .help(view.help)
                .accessibilityIdentifier("grammar-tab-\(view.rawValue)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private var visualizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch selectedView {
            case .annotated:
                roleLegend
                annotatedView
            case .dependency:
                roleLegend
                DependencyDiagram(
                    chunks: result.chunks,
                    dependencies: result.dependencies,
                    hoveredRole: $hoveredRole
                )
            case .tree:
                GrammarTreeView(node: result.tree)
            case .trunk:
                trunkView
            case .tense:
                tenseVoiceView
            case .order:
                wordOrderView
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .accessibilityIdentifier("grammar-viz-\(selectedView.rawValue)")
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private var roleLegend: some View {
        GrammarWrapLayout(spacing: 12, rowSpacing: 8) {
            ForEach(GrammarRole.allCases) { role in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(role.color)
                        .frame(width: 9, height: 9)
                    Text(role.zh)
                        .font(.system(size: 11.5))
                }
                .foregroundStyle(Color.lingoMuted)
                .opacity(hoveredRole == nil || hoveredRole == role ? 1 : 0.35)
                .onHover { hoveredRole = $0 ? role : nil }
            }
        }
    }

    private var annotatedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            GrammarWrapLayout(spacing: 2, rowSpacing: 10) {
                ForEach(result.chunks) { chunk in
                    GrammarChunkPill(
                        chunk: chunk,
                        isDimmed: hoveredRole != nil && hoveredRole != chunk.role,
                        isOpen: openChunkID == chunk.id
                    ) {
                        withAnimation(.easeOut(duration: 0.18)) {
                            openChunkID = openChunkID == chunk.id ? nil : chunk.id
                        }
                    }
                    .onHover { hoveredRole = $0 ? chunk.role : nil }
                }
            }
            .padding(.top, 4)

            Text("点击任意成分，展开词性与形态 ↓")
                .font(.system(size: 11))
                .foregroundStyle(Color.lingoSubtle)
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(result.chunks) { chunk in
                    GrammarChunkNote(
                        chunk: chunk,
                        isDimmed: hoveredRole != nil && hoveredRole != chunk.role,
                        isOpen: openChunkID == chunk.id
                    ) {
                        withAnimation(.easeOut(duration: 0.18)) {
                            openChunkID = openChunkID == chunk.id ? nil : chunk.id
                        }
                    }
                    .onHover { hoveredRole = $0 ? chunk.role : nil }
                }
            }
            .padding(.top, 22)
        }
    }

    private var trunkView: some View {
        VStack(alignment: .leading, spacing: 12) {
            GrammarWrapLayout(spacing: 8, rowSpacing: 8) {
                ForEach(result.trunk.core) { item in
                    Text(item.w)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color.lingoText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(item.role.highlight, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(item.role.color, lineWidth: 1)
                        )
                }
            }

            Text(result.trunk.coreZh)
                .font(.system(size: 14))
                .foregroundStyle(Color.lingoMuted)

            GrammarWrapLayout(spacing: 7, rowSpacing: 7) {
                Text("已省略的修饰成分")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.lingoSubtle)
                ForEach(result.trunk.dropped, id: \.self) { dropped in
                    Text(dropped)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lingoSubtle)
                        .strikethrough(true, color: Color.lingoSubtle)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .padding(.top, 4)
        }
    }

    private var tenseVoiceView: some View {
        VStack(spacing: 10) {
            ForEach(result.tenseVoice) { clause in
                GrammarTenseCard(clause: clause)
            }
        }
    }

    private var wordOrderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            GrammarOrderRow(label: "英文语序", segments: result.wordOrder.en)

            HStack(spacing: 7) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                Text("后置修饰前移")
                    .font(.system(size: 11.5, weight: .medium))
            }
            .foregroundStyle(Color.lingoAccentText)
            .padding(.leading, 68)
            .padding(.vertical, 8)

            GrammarOrderRow(label: "中文语序", segments: chineseOrderSegments)

            HStack(alignment: .top, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.lingoAccentText, lineWidth: 1.5)
                    .frame(width: 18, height: 11)
                    .padding(.top, 3)
                Text(result.wordOrder.note)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lingoMuted)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 224 / 255, green: 145 / 255, blue: 92 / 255).opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color(red: 224 / 255, green: 145 / 255, blue: 92 / 255).opacity(0.22), lineWidth: 1)
            )
            .padding(.top, 6)
        }
    }

    private var chineseOrderSegments: [GrammarOrderSegment] {
        result.wordOrder.zhOrder.enumerated().compactMap { index, sourceID in
            guard let source = result.wordOrder.en.first(where: { $0.id == sourceID }),
                  index < result.wordOrder.zhText.count else {
                return nil
            }
            return GrammarOrderSegment(
                id: source.id,
                text: result.wordOrder.zhText[index],
                role: source.role,
                zhPos: index + 1,
                moved: source.moved
            )
        }
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("可复用句型")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
                .textCase(.uppercase)
            Text(result.pattern.en)
                .font(.system(size: 14.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.lingoText)
            Text(result.pattern.zh)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.lingoMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lingoAccent.opacity(0.05))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lingoHairline)
                .frame(height: 1)
        }
    }

    private var knowledgeSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                columnHead("link", "固定搭配")
                ForEach(result.collocations) { collocation in
                    GrammarCollocationCard(collocation: collocation)
                }

                columnHead("book.closed", "常见词组")
                    .padding(.top, 7)
                GrammarWrapLayout(spacing: 7, rowSpacing: 7) {
                    ForEach(result.phrases) { phrase in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(phrase.en)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.lingoText)
                            Text(phrase.zh)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.lingoSubtle)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 0) {
                columnHead("lightbulb", "语法点")
                ForEach(result.grammarPoints) { point in
                    GrammarPointCard(point: point)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func columnHead(_ systemName: String, _ title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.lingoAccentText)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.lingoMuted)
        }
        .padding(.bottom, 10)
    }
}

public enum GrammarVizView: String, CaseIterable, Identifiable {
    case annotated
    case dependency
    case tree
    case trunk
    case tense
    case order

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .annotated: "成分标注"
        case .dependency: "依存关系"
        case .tree: "层次结构"
        case .trunk: "主干提取"
        case .tense: "时态语态"
        case .order: "语序对照"
        }
    }

    var symbol: String {
        switch self {
        case .annotated: "highlighter"
        case .dependency: "point.3.connected.trianglepath.dotted"
        case .tree: "list.bullet.indent"
        case .trunk: "line.3.horizontal.decrease"
        case .tense: "clock"
        case .order: "arrow.up.arrow.down"
        }
    }

    var help: String {
        switch self {
        case .annotated: "彩色高亮 + 点词看词性形态"
        case .dependency: "词块之间的句法弧"
        case .tree: "主句、从句和修饰层级"
        case .trunk: "剥离修饰看骨架"
        case .tense: "时态、语态、语气和施受关系"
        case .order: "英文到中文的语序重排"
        }
    }
}

private struct GrammarChunkPill: View {
    var chunk: GrammarChunk
    var isDimmed: Bool
    var isOpen: Bool
    var onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Text(chunk.text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.lingoText)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(chunk.role.highlight, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(chunk.role.color)
                        .frame(height: 2)
                }
                .overlay(alignment: .topLeading) {
                    if isHovered || isOpen {
                        Text(chunk.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(chunk.role.color, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .offset(x: 4, y: -12)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
        }
        .buttonStyle(.plain)
        .opacity(isDimmed ? 0.32 : 1)
        .onHover { isHovered = $0 }
    }
}

private struct GrammarChunkNote: View {
    var chunk: GrammarChunk
    var isDimmed: Bool
    var isOpen: Bool
    var onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(chunk.role.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Text(chunk.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(chunk.role.color)
                        Text(chunk.text)
                            .font(.system(size: 13.5, weight: .regular))
                            .foregroundStyle(Color.lingoText)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isOpen ? Color.lingoText : Color.lingoSubtle)
                            .rotationEffect(.degrees(isOpen ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)

                Text(chunk.note)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lingoSubtle)
                    .lineSpacing(3)

                if isOpen, !chunk.tokens.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(chunk.tokens, id: \.w) { token in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(token.w)
                                    .font(.system(size: 13.5, weight: .medium))
                                    .foregroundStyle(Color.lingoText)
                                    .frame(minWidth: 80, alignment: .leading)
                                Text(token.pos)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(chunk.role.color)
                                    .fixedSize()
                                Text(token.infl)
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Color.lingoSubtle)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .opacity(isDimmed ? 0.32 : 1)
    }
}

private struct DependencyDiagram: View {
    var chunks: [GrammarChunk]
    var dependencies: [GrammarDependency]
    @Binding var hoveredRole: GrammarRole?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                Canvas { context, size in
                    drawDependencies(context: &context, size: size)
                }
                .frame(width: proxy.size.width, height: 90)
            }
            .frame(height: 90)

            GrammarWrapLayout(spacing: 6, rowSpacing: 8) {
                ForEach(chunks) { chunk in
                    Text(chunk.text)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.lingoText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(chunk.role.color)
                                .frame(height: 2)
                        }
                        .opacity(hoveredRole == nil || hoveredRole == chunk.role ? 1 : 0.32)
                        .onHover { hoveredRole = $0 ? chunk.role : nil }
                }
            }
        }
    }

    private func drawDependencies(context: inout GraphicsContext, size: CGSize) {
        guard chunks.count > 1 else {
            return
        }
        let yBase = size.height - 5
        let usableWidth = max(size.width - 40, 1)
        let step = usableWidth / CGFloat(max(chunks.count - 1, 1))

        func xPosition(for id: String) -> CGFloat? {
            guard let index = chunks.firstIndex(where: { $0.id == id }) else {
                return nil
            }
            return 20 + CGFloat(index) * step
        }

        for dependency in dependencies {
            guard let fromX = xPosition(for: dependency.from),
                  let toX = xPosition(for: dependency.to),
                  let fromChunk = chunks.first(where: { $0.id == dependency.from }) else {
                continue
            }
            let span = abs(toX - fromX)
            let lift = min(20 + span * 0.22, 74)
            let role = fromChunk.role
            let isDimmed = hoveredRole != nil && hoveredRole != role
            let opacity = isDimmed ? 0.22 : 0.85
            let color = role.color.opacity(opacity)

            var path = Path()
            path.move(to: CGPoint(x: fromX, y: yBase))
            path.addCurve(
                to: CGPoint(x: toX, y: yBase),
                control1: CGPoint(x: fromX, y: yBase - lift),
                control2: CGPoint(x: toX, y: yBase - lift)
            )
            context.stroke(path, with: .color(color), lineWidth: 1.6)

            var arrow = Path()
            arrow.move(to: CGPoint(x: toX - 4, y: yBase - 7))
            arrow.addLine(to: CGPoint(x: toX + 4, y: yBase - 7))
            arrow.addLine(to: CGPoint(x: toX, y: yBase - 1))
            arrow.closeSubpath()
            context.fill(arrow, with: .color(color))

            let midX = (fromX + toX) / 2
            let labelY = yBase - lift
            let labelWidth = max(CGFloat(dependency.label.count * 12 + 12), 34)
            let labelRect = CGRect(x: midX - labelWidth / 2, y: labelY - 9, width: labelWidth, height: 17)
            let labelPath = RoundedRectangle(cornerRadius: 6, style: .continuous).path(in: labelRect)
            context.fill(labelPath, with: .color(Color(red: 27 / 255, green: 29 / 255, blue: 39 / 255).opacity(isDimmed ? 0.25 : 1)))
            context.stroke(labelPath, with: .color(role.color.opacity(isDimmed ? 0.16 : 0.40)), lineWidth: 1)

            let text = context.resolve(
                Text(dependency.label)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(role.color.opacity(isDimmed ? 0.30 : 1))
            )
            context.draw(text, at: CGPoint(x: midX, y: labelY - 0.5), anchor: .center)
        }
    }
}

private struct GrammarTreeView: View {
    var node: GrammarTreeNode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GrammarTreeNodeView(node: node, depth: 0)
        }
    }
}

private struct GrammarTreeNodeView: View {
    var node: GrammarTreeNode
    var depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(node.role.color)
                    .frame(width: 3, height: 16)
                Text(node.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(node.role.color)
                    .frame(width: 76, alignment: .leading)
                Text(node.text)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.lingoText)
            }
            .padding(.vertical, 6)
            .padding(.leading, CGFloat(depth) * 18)

            if !node.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(node.children) { child in
                        GrammarTreeNodeView(node: child, depth: depth + 1)
                    }
                }
                .padding(.leading, 4)
                .overlay(alignment: .leading) {
                    DashedVerticalLine()
                        .stroke(Color.lingoHairlineStrong, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                        .frame(width: 1)
                }
            }
        }
    }
}

private struct DashedVerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct GrammarTenseCard: View {
    var clause: GrammarTenseClause

    private var isPassive: Bool {
        clause.voice == "被动"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(clause.scope)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.lingoSubtle)
                Text(clause.verb)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.lingoText)
            }

            GrammarWrapLayout(spacing: 6, rowSpacing: 6) {
                badge(clause.tense, fill: Color.lingoAccent2.opacity(0.18), foreground: Color(red: 179 / 255, green: 170 / 255, blue: 1))
                badge(clause.aspect)
                badge(clause.voice, fill: isPassive ? Color(red: 79 / 255, green: 184 / 255, blue: 201 / 255).opacity(0.20) : Color.lingoChipHover, foreground: isPassive ? Color(red: 127 / 255, green: 214 / 255, blue: 227 / 255) : Color.lingoMuted)
                badge("\(clause.mood)语气")
            }
            .padding(.top, 9)

            GrammarWrapLayout(spacing: 8, rowSpacing: 8) {
                svoNode(clause.svo.agent, fill: Color.lingoAccent.opacity(0.18), foreground: Color(red: 179 / 255, green: 192 / 255, blue: 1))
                HStack(spacing: 5) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text(clause.svo.action)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.lingoMuted)
                if let receiver = clause.svo.receiver, !receiver.isEmpty {
                    svoNode(receiver, fill: Color(red: 79 / 255, green: 184 / 255, blue: 201 / 255).opacity(0.18), foreground: Color(red: 143 / 255, green: 220 / 255, blue: 232 / 255))
                } else {
                    svoNode("（无宾语）", fill: Color.lingoChipHover, foreground: Color.lingoSubtle)
                }
            }
            .padding(.top, 11)

            Text(clause.why)
                .font(.system(size: 12))
                .foregroundStyle(Color.lingoSubtle)
                .lineSpacing(3)
                .padding(.top, 10)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isPassive ? GrammarRole.object.color : Color.lingoAccent)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func badge(_ text: String, fill: Color = Color.lingoChipHover, foreground: Color = Color.lingoMuted) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(fill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func svoNode(_ text: String, fill: Color, foreground: Color) -> some View {
        Text(text)
            .font(.system(size: 12.5))
            .foregroundStyle(foreground)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GrammarOrderRow: View {
    var label: String
    var segments: [GrammarOrderSegment]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.lingoSubtle)
                .frame(width: 56, alignment: .leading)
                .padding(.top, 7)

            GrammarWrapLayout(spacing: 6, rowSpacing: 7) {
                ForEach(segments) { segment in
                    HStack(spacing: 5) {
                        Text("\(segment.id)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 13 / 255, green: 14 / 255, blue: 18 / 255))
                            .frame(width: 16, height: 16)
                            .background(segment.role.color, in: Circle())
                        Text(segment.text)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.lingoText)
                    }
                    .padding(.leading, 7)
                    .padding(.trailing, 9)
                    .padding(.vertical, 5)
                    .background(segment.role.highlight, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(segment.moved ? segment.role.color : Color.clear, lineWidth: 1.5)
                    }
                    .overlay(alignment: .bottom) {
                        if !segment.moved {
                            Rectangle()
                                .fill(segment.role.color)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct GrammarCollocationCard: View {
    var collocation: GrammarCollocation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(collocation.phrase)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.lingoAccentText)
                Text(collocation.pos)
                    .font(.system(size: 10.5))
                    .italic()
                    .foregroundStyle(Color.lingoSubtle)
                Spacer(minLength: 6)
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lingoMuted)
                    .frame(width: 24, height: 24)
                    .background(Color.lingoChipHover, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Text(collocation.zh)
                .font(.system(size: 13))
                .foregroundStyle(Color.lingoText)
                .padding(.top, 6)

            Text(collocation.note)
                .font(.system(size: 11.5))
                .foregroundStyle(Color.lingoSubtle)
                .lineSpacing(3)
                .padding(.top, 4)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("e.g.")
                    .font(.system(size: 12.5, weight: .semibold))
                    .italic()
                    .foregroundStyle(Color.lingoAccentText)
                Text(collocation.example)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.lingoMuted)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.top, 7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .padding(.bottom, 9)
    }
}

private struct GrammarPointCard: View {
    var point: GrammarPoint

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(point.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(point.tag)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(point.color, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    Text(point.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.lingoText)
                }
                Text(point.body)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lingoMuted)
                    .lineSpacing(3)
            }
            .padding(.leading, 11)
            .padding(.trailing, 12)
            .padding(.vertical, 11)
        }
        .background(Color.lingoChip, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .padding(.bottom, 9)
    }
}

private struct GrammarWrapLayout: Layout {
    var spacing: CGFloat = 6
    var rowSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = max(proposal.width ?? 0, 1)
        let rows = rows(in: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height
        } + CGFloat(max(rows.count - 1, 0)) * rowSpacing
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(in: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = item.size
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private func rows(in maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if proposedWidth > maxWidth, !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.items.append(RowItem(index: index, size: size))
            current.width = current.items.count == 1 ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }
        return rows
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private struct RowItem {
        var index: Int
        var size: CGSize
    }
}

private extension GrammarRole {
    var color: Color {
        switch self {
        case .subject: Color(red: 110 / 255, green: 139 / 255, blue: 1.0)
        case .predicate: Color(red: 138 / 255, green: 125 / 255, blue: 1.0)
        case .object: Color(red: 79 / 255, green: 184 / 255, blue: 201 / 255)
        case .attr: Color(red: 224 / 255, green: 145 / 255, blue: 92 / 255)
        case .adv: Color(red: 91 / 255, green: 191 / 255, blue: 138 / 255)
        case .appos: Color(red: 214 / 255, green: 120 / 255, blue: 159 / 255)
        case .conj: Color(red: 182 / 255, green: 188 / 255, blue: 200 / 255)
        }
    }

    var highlight: Color {
        color.opacity(self == .conj ? 0.20 : 0.22)
    }
}

private extension GrammarPoint {
    var color: Color {
        switch tag {
        case "从句": GrammarRole.appos.color
        case "语态": GrammarRole.object.color
        case "修饰": GrammarRole.attr.color
        case "非谓语", "时态": GrammarRole.adv.color
        default: Color.lingoAccent
        }
    }
}

private extension View {
    func grammarHoverChrome(
        fill: Color,
        hoverFill: Color,
        stroke: Color = Color.clear,
        hoverStroke: Color? = nil,
        cornerRadius: CGFloat
    ) -> some View {
        modifier(
            GrammarHoverChrome(
                fill: fill,
                hoverFill: hoverFill,
                stroke: stroke,
                hoverStroke: hoverStroke ?? stroke,
                cornerRadius: cornerRadius
            )
        )
    }
}

private struct GrammarHoverChrome: ViewModifier {
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
