import SwiftUI
import UIKit
import VellureCore

/// 목록 화면 상단의 날짜·제목과 동작 버튼.
/// 정렬 모드에서는 다른 버튼을 감추고 "완료"만 남긴다.
struct MemoListHeader: View {
    let surface: Surface
    /// 정렬 버튼을 보여줄지. 메모가 하나도 없으면 정렬할 것이 없다.
    let canReorder: Bool
    @Binding var isReordering: Bool
    let onNewMemo: () -> Void
    let onSettings: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var haptic = UISelectionFeedbackGenerator()

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .scaledFont(13, weight: .semibold)
                    .foregroundStyle(Theme.textSecondary)
                Text(LocalizedStringKey(surface == .memo ? "home.title" : "home.widget.title"))
                    .scaledFont(27, weight: .heavy)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                if isReordering {
                    doneButton
                } else {
                    if canReorder { reorderButton }
                    newMemoButton
                    settingsButton
                }
            }
        }
    }

    private var doneButton: some View {
        Button {
            withAnimation { isReordering = false }
        } label: {
            Text("home.done")
                .scaledFont(13, weight: .bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Theme.accent)
                .clipShape(Capsule())
        }
    }

    private var reorderButton: some View {
        Button {
            haptic.prepare()
            withAnimation { isReordering = true }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .scaledFont(14, weight: .bold)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Theme.chipBackground)
                .clipShape(Circle())
        }
        .accessibilityLabel("a11y.header.reorder")
    }

    private var newMemoButton: some View {
        Button(action: onNewMemo) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .scaledFont(12, weight: .bold)
                // 접근성 글자 크기에서는 라벨이 여러 줄로 접혀 버튼이 뭉개진다.
                // 아이콘만 남긴다. VoiceOver는 접근성 레이블로 읽으므로 정보 손실이 없다.
                if !dynamicTypeSize.isAccessibilitySize {
                    Text("home.new")
                        .scaledFont(13, weight: .bold)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.accent)
            .clipShape(Capsule())
        }
        .accessibilityLabel("a11y.header.newMemo")
    }

    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape")
                .scaledFont(15)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Theme.chipBackground)
                .clipShape(Circle())
        }
        .accessibilityLabel("a11y.header.settings")
    }
}
