import SwiftUI
import VellureCore

struct EmptyStateView: View {
    /// 어느 탭의 빈 상태인지. 안내 문구와 아이콘이 달라진다.
    var surface: Surface = .memo
    let onCreateTap: () -> Void

    /// 위젯 탭은 "잠금화면에 띄운다"가 아니라 "홈화면에 배치한다"가 목표다.
    /// 같은 문구를 쓰면 사용자가 다음 행동을 잘못 고른다.
    private var titleKey: LocalizedStringKey {
        surface == .memo ? "empty.title" : "empty.widget.title"
    }

    private var descriptionKey: LocalizedStringKey {
        surface == .memo ? "empty.description" : "empty.widget.description"
    }

    private var ctaKey: LocalizedStringKey {
        surface == .memo ? "empty.cta" : "empty.widget.cta"
    }

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .stroke(Theme.divider, lineWidth: 1)
                .frame(width: 76, height: 76)
                .overlay {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 12, height: 12)
                }

            VStack(spacing: 8) {
                Text(titleKey)
                    .scaledFont(19, weight: .heavy)
                    .foregroundStyle(Theme.textPrimary)

                Text(descriptionKey)
                    .scaledFont(14)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onCreateTap) {
                Text(ctaKey)
                    .scaledFont(15, weight: .bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

#if DEBUG
#Preview("메모 탭") {
    EmptyStateView(surface: .memo, onCreateTap: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
}

#Preview("위젯 탭") {
    EmptyStateView(surface: .widget, onCreateTap: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
}
#endif
