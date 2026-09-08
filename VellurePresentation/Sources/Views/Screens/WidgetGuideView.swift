import SwiftUI
import VellureCore

/// 위젯을 홈·잠금화면에 배치하는 방법을 안내한다.
///
/// 앱이 사용자를 대신해 위젯을 설치할 수 없다. iOS는 위젯 추가를 사용자 조작으로만 허용하므로,
/// 메모를 만들어도 안내가 없으면 "위젯이 안 나온다"로 끝난다.
public struct WidgetGuideView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    intro

                    GuideSection(
                        icon: "square.grid.2x2",
                        titleKey: "guide.home.title",
                        steps: ["guide.home.step1", "guide.home.step2", "guide.home.step3"]
                    )

                    GuideSection(
                        icon: "lock",
                        titleKey: "guide.lock.title",
                        steps: ["guide.lock.step1", "guide.lock.step2", "guide.lock.step3"]
                    )

                    tip
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("guide.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("guide.done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var intro: some View {
        Text("guide.intro")
            .scaledFont(14)
            .foregroundStyle(Theme.textSecondary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 위젯이 여러 개일 때의 핵심 안내.
    /// 이 문장이 없으면 사용자는 위젯이 엉뚱한 메모를 보여준다고 인식한다.
    private var tip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.tap")
                .scaledFont(15, weight: .semibold)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            Text("guide.tip")
                .scaledFont(13)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Theme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 표면 하나의 추가 절차.
private struct GuideSection: View {
    let icon: String
    let titleKey: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .scaledFont(14, weight: .semibold)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(titleKey))
                    .scaledFont(16, weight: .heavy)
                    .foregroundStyle(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, key in
                    step(number: index + 1, key: key)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func step(number: Int, key: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .scaledFont(11, weight: .heavy)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Theme.accent)
                .clipShape(Circle())

            Text(LocalizedStringKey(key))
                .scaledFont(14)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
#Preview {
    WidgetGuideView()
}
#endif
