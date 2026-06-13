import LingobarCore
import SwiftUI

struct LingobarRootView: View {
    @ObservedObject var viewModel: LingobarViewModel

    var body: some View {
        VStack(spacing: 8) {
            dragHandle
            commandBar
            resultPanel
        }
        .padding(8)
        .frame(width: 760, height: 386)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.lingoPanel)
                .shadow(color: .black.opacity(0.38), radius: 34, y: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private var dragHandle: some View {
        ZStack {
            WindowDragHandle()
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.lingoMuted)
                Text("Lingobar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                Text("Drag here")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.lingoMuted)
                Spacer()
                Text("⌥⌘L")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.lingoMuted)
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
        }
        .frame(height: 22)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .help("Drag this area to move Lingobar")
    }

    private var commandBar: some View {
        HStack(spacing: 8) {
            if viewModel.mode == .selection {
                selectedChip
                ForEach(viewModel.actions) { action in
                    actionButton(action)
                }
            } else {
                Image(systemName: "text.cursor")
                    .foregroundStyle(Color.lingoMuted)
                TextField("输入、粘贴或说一句想表达的话", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .onSubmit {
                        viewModel.submitInput()
                    }
                Button {
                    viewModel.submitInput()
                } label: {
                    Text(viewModel.isLoading ? "生成中" : "生成")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(FilledCapsuleButtonStyle())
                .disabled(viewModel.isLoading)
            }
        }
        .padding(8)
        .frame(height: 54)
        .background(Color.lingoBar, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var selectedChip: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.selectedText)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(.white)
            Text("Selected text · current app")
                .font(.system(size: 10))
                .foregroundStyle(Color.lingoMuted)
        }
        .frame(width: 172, alignment: .leading)
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 30)
        }
    }

    private func actionButton(_ action: LanguageAction) -> some View {
        Button {
            viewModel.perform(action)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: action.symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(action.title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(height: 38)
            .padding(.horizontal, 9)
            .foregroundStyle(viewModel.action == action ? .white : Color.lingoText)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(viewModel.action == action ? Color.white.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help("\(action.title) \(action.shortcut)")
    }

    private var resultPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(viewModel.result.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(viewModel.result.shortcut)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.lingoMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }

                    Text(viewModel.result.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.lingoText)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 0) {
                        ForEach(viewModel.result.rows, id: \.label) { row in
                            HStack(alignment: .top, spacing: 12) {
                                Text(row.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.lingoAccent)
                                    .frame(width: 74, alignment: .leading)
                                Text(row.value)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.lingoText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 7)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 14) {
                    Text(viewModel.result.sideTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    FlowLayout(items: viewModel.result.chips) { chip in
                        Text(chip)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.lingoText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    Spacer()
                    SavedPhraseMiniList(phrases: Array(viewModel.savedPhrases.prefix(2)))
                }
                .padding(18)
                .frame(width: 252, alignment: .topLeading)
                .background(Color.black.opacity(0.19))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                }
            }

            footer
        }
        .background(Color.lingoPanel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack {
            Button("复制") { viewModel.copyResult() }
                .buttonStyle(SecondaryFooterButtonStyle())
            Button("保存") { viewModel.saveCurrentPhrase() }
                .buttonStyle(PrimaryFooterButtonStyle())
            Button("继续展开") { viewModel.perform(.expand) }
                .buttonStyle(SecondaryFooterButtonStyle())
            Button("插入当前 App") { viewModel.insertResult() }
                .buttonStyle(SecondaryFooterButtonStyle())

            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.55)
                    .progressViewStyle(.circular)
            }
            Text(viewModel.status)
                .font(.system(size: 12))
                .foregroundStyle(Color.lingoMuted)
                .frame(minWidth: 92, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color.black.opacity(0.2))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}

private struct SavedPhraseMiniList: View {
    var phrases: [SavedPhrase]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Saved")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color.lingoMuted)
            ForEach(phrases) { phrase in
                VStack(alignment: .leading, spacing: 3) {
                    Text(phrase.title)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(phrase.note)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundStyle(Color.lingoMuted)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
