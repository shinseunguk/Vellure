import SwiftUI

struct ExpandedChecklistView: View {
    let items: [LiveChecklistItem]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if items.count > 0 { checkRow(items[0]) }
            if items.count > 1 { checkRow(items[1]) }
            if items.count > 2 { checkRow(items[2]) }
            if items.count > 3 { checkRow(items[3]) }
            if items.count > 4 {
                Text("외 \(items.count - 4)개")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func checkRow(_ item: LiveChecklistItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(item.done ? tint : .secondary)
            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(item.done ? Color.secondary : Color.white)
                .strikethrough(item.done)
                .lineLimit(1)
        }
    }
}
