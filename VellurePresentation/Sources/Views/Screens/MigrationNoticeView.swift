import SwiftUI
import VellureCore

/// v1.1로 올라온 기존 사용자에게 탭이 둘로 나뉘었음을 알린다.
///
/// 디데이·달성률이 위젯 탭으로 옮겨가므로, 안내가 없으면 메모 탭만 본 사용자에게는
/// 메모가 사라진 것으로 보인다.
struct MigrationNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    /// 확인 후 위젯 탭으로 보낼지 여부를 상위에 알린다.
    let onGoToWidgetTab: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 22) {
                tabIllustration

                VStack(spacing: 10) {
                    Text("migration.title")
                        .scaledFont(21, weight: .heavy)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("migration.description")
                        .scaledFont(14)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 8) {
                    row(icon: "note.text", titleKey: "tab.memo", detailKey: "migration.memo.detail")
                    row(icon: "square.grid.2x2", titleKey: "tab.widget", detailKey: "migration.widget.detail")
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    onGoToWidgetTab()
                } label: {
                    Text("migration.cta.widget")
                        .scaledFont(15, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { dismiss() } label: {
                    Text("migration.cta.later")
                        .scaledFont(14, weight: .semibold)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    /// 탭이 둘로 나뉘었다는 사실을 그림으로 먼저 보여준다.
    private var tabIllustration: some View {
        HStack(spacing: 10) {
            tabChip(icon: "note.text", titleKey: "tab.memo", isHighlighted: false)
            tabChip(icon: "square.grid.2x2", titleKey: "tab.widget", isHighlighted: true)
        }
    }

    private func tabChip(icon: String, titleKey: String, isHighlighted: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .scaledFont(20, weight: .semibold)
            Text(LocalizedStringKey(titleKey))
                .scaledFont(12, weight: .bold)
        }
        .foregroundStyle(isHighlighted ? Theme.accent : Theme.textSecondary)
        .frame(width: 92, height: 76)
        .background(isHighlighted ? Theme.accent.opacity(0.12) : Theme.chipBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func row(icon: String, titleKey: String, detailKey: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.accent)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(titleKey))
                    .scaledFont(13, weight: .bold)
                    .foregroundStyle(Theme.textPrimary)
                Text(LocalizedStringKey(detailKey))
                    .scaledFont(12.5)
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    MigrationNoticeView(onGoToWidgetTab: {})
}
#endif
