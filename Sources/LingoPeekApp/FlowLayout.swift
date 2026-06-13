import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    var items: Data
    var spacing: CGFloat = 6
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        GeometryReader { geometry in
            let rows = makeRows(width: geometry.size.width)
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { item in
                            content(item)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 68)
    }

    private func makeRows(width: CGFloat) -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentWidth: CGFloat = 0

        for item in items {
            let itemWidth = estimatedWidth(for: item)
            if currentWidth + itemWidth + spacing > width, !rows[rows.count - 1].isEmpty {
                rows.append([item])
                currentWidth = itemWidth
            } else {
                rows[rows.count - 1].append(item)
                currentWidth += itemWidth + spacing
            }
        }
        return rows
    }

    private func estimatedWidth(for item: Data.Element) -> CGFloat {
        String(describing: item).count < 6 ? 64 : CGFloat(String(describing: item).count * 8 + 24)
    }
}
