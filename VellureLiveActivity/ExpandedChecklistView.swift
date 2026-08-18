import AppIntents
import SwiftUI
import VellureCore

struct ExpandedChecklistView: View {
    /// 확장 영역 높이 상한 안에서 안전하게 보이는 최대 행 수.
    /// 남은 개수 안내("외 N개")도 한 행을 차지하므로 같은 예산에서 함께 계산한다.
    private static let capacity = 4
    /// 행 간격
    private static let rowSpacing: CGFloat = 6

    let items: [LiveChecklistItem]
    let memoId: String
    let tint: Color

    var body: some View {
        let showsOverflow = items.count > Self.capacity
        let visibleCount = showsOverflow ? Self.capacity - 1 : Self.capacity

        VStack(alignment: .leading, spacing: Self.rowSpacing) {
            ForEach(items.prefix(visibleCount), id: \.id) { item in
                checkRow(item)
            }
            if showsOverflow {
                Text("외 \(items.count - visibleCount)개")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func checkRow(_ item: LiveChecklistItem) -> some View {
        Button(intent: ToggleItemIntent(memoId: memoId, itemId: item.id)) {
            HStack(spacing: 8) {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(item.done ? tint : .secondary)
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.done ? Color.secondary : Color.white)
                    .strikethrough(item.done)
                    .lineLimit(1)
                    .truncationMode(.tail)
                // Spacer가 없으면 행 폭이 확정되지 않아 말줄임 대신 그대로 잘린다.
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.done ? "a11y.item.checked" : "a11y.item.unchecked")
    }
}

#if DEBUG
#Preview {
    ExpandedChecklistView(
        items: [
            LiveChecklistItem(id: "1", title: "여권", done: true),
            LiveChecklistItem(id: "2", title: "충전기", done: false),
            LiveChecklistItem(id: "3", title: "이어폰", done: false)
        ],
        memoId: "preview",
        tint: .green
    )
    .padding()
    .background(.black)
}
#endif
