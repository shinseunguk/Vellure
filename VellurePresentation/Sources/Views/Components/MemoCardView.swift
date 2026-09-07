import SwiftUI
import VellureCore

struct MemoCardView: View {
    let memo: Memo
    let onTap: () -> Void
    let onToggleActivity: () -> Void
    let onDelete: () -> Void
    var showsActions: Bool = true
    /// 실제로 잠금화면에 떠 있는지. 저장된 activityId가 아니라
    /// 실행 중인 Activity 목록에서 판정한 값을 주입받는다.
    var isActive: Bool = false

    private var tintColor: Color {
        Theme.memoColor(for: memo.colorTag)
    }

    private var sideValue: String? {
        switch memo.renderType {
        case .dday:
            guard let target = memo.targetDate else { return nil }
            return DDayFormatter.string(for: target)
        case .countdown:
            guard let target = memo.targetDate else { return nil }
            let remaining = target.timeIntervalSince(.now)
            if remaining <= 0 { return "00:00" }
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            return hours > 0
                ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                : String(format: "%02d:%02d", minutes, seconds)
        case .checklist:
            let total = memo.items?.count ?? 0
            let done = memo.items?.filter(\.done).count ?? 0
            return "\(done)/\(total)"
        case .progress:
            return "\(Int((memo.progress ?? 0) * 100))%"
        case .plain:
            return nil
        }
    }

    /// 타입별 보조 값 칩.
    ///
    /// 카운트다운만 `Text(timerInterval:)`을 쓴다. 계산된 문자열로 그리면
    /// 뷰가 다시 그려질 때까지 숫자가 멈춰 있어 흐르지 않는다.
    /// (D-day·진행률·체크 개수는 초 단위로 변하지 않으므로 문자열로 충분하다)
    @ViewBuilder
    private var sideValueChip: some View {
        if memo.renderType == .countdown, let target = memo.targetDate, target > .now {
            chipLabel { Text(timerInterval: Date.now...target, countsDown: true) }
        } else if let value = sideValue {
            chipLabel { Text(value) }
        }
    }

    private func chipLabel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .scaledFont(10.5, weight: .heavy)
            .foregroundStyle(tintColor)
            .monospacedDigit()
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(tintColor.opacity(0.12))
            .clipShape(Capsule())
    }

    /// 잠금화면에 떠 있는 동안 언제까지 유지되는지 알린다.
    /// Live Activity와 같은 8시간 기준이라 두 화면의 값이 일치한다.
    ///
    /// 메타 행이 아니라 배지 안에 두는 이유:
    /// 타입 라벨·값 칩과 한 줄을 나눠 쓰면 카운트다운처럼 값이 긴 타입에서
    /// 서로 폭을 다투다 말줄임이 생긴다 (#37과 같은 구조).
    /// 배지는 우측 상단 독립 영역이라 폭 경쟁이 없다.
    @ViewBuilder
    private var expiryTimer: some View {
        if let deadline = memo.activeDeadline() {
            HStack(spacing: 3) {
                Text(verbatim: "·")
                    .scaledFont(10, weight: .heavy)
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityHidden(true)

                if deadline > .now {
                    // 고정 폭을 주지 않는다. 자릿수가 줄면 그만큼 배지가 좁아지며
                    // 아이콘과 숫자가 계속 붙어 있다.
                    Text(timerInterval: Date.now...deadline, countsDown: true)
                        .scaledFont(10, weight: .heavy)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    Text("la.expired")
                        .scaledFont(10, weight: .heavy)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .lineLimit(1)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: memo.renderType.iconName)
                            .scaledFont(15, weight: .semibold)
                            .foregroundStyle(tintColor)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(memo.renderType.displayName)
                            .scaledFont(11, weight: .bold)
                            .foregroundStyle(tintColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        sideValueChip

                        Spacer(minLength: 0)
                    }
                    if !memo.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(memo.content)
                            .scaledFont(15.5, weight: .bold)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    if memo.renderType == .progress {
                        GeometryReader { geo in
                            Capsule()
                                .fill(tintColor.opacity(0.15))
                                .frame(height: 5)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(tintColor)
                                        .frame(width: geo.size.width * (memo.progress ?? 0), height: 5)
                                }
                        }
                        .frame(height: 5, alignment: .leading)
                        .frame(maxWidth: 150)
                        .padding(.top, 4)
                    } else if memo.renderType == .checklist, let items = memo.items, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(items.prefix(4)) { item in
                                HStack(spacing: 5) {
                                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                        .scaledFont(11, weight: .semibold)
                                        .foregroundStyle(item.done ? tintColor : Theme.textSecondary)
                                    Text(item.title)
                                        .scaledFont(12.5, weight: .medium)
                                        .foregroundStyle(item.done ? Theme.textSecondary : Theme.textPrimary)
                                        .strikethrough(item.done)
                                        .lineLimit(1)
                                }
                            }
                            if items.count > 4 {
                                Text("+\(items.count - 4)")
                                    .scaledFont(11, weight: .semibold)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 3)
                    }
                }

                Spacer(minLength: 4)

                if showsActions {
                    HStack(spacing: 6) {
                        Button(action: onToggleActivity) {
                            Image(systemName: isActive ? "arrow.down" : "arrow.up")
                                .accessibilityHidden(true)
                                .scaledFont(13, weight: .bold)
                                .foregroundStyle(isActive ? .white : tintColor)
                                .frame(width: 34, height: 34)
                                .background(isActive ? tintColor : tintColor.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isActive ? "a11y.card.unpublish" : "a11y.card.publish")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .accessibilityHidden(true)
                                .scaledFont(13, weight: .medium)
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(Theme.chipBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("a11y.card.delete")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isActive ? tintColor.opacity(0.4) : Theme.divider, lineWidth: isActive ? 2 : 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isActive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 5, height: 5)
                        Text("card.onLock")
                            .scaledFont(10, weight: .heavy)
                            .foregroundStyle(.white)
                        expiryTimer
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(Color(red: 0.15, green: 0.18, blue: 0.21))
                    .clipShape(Capsule())
                    .offset(y: -9)
                    .padding(.trailing, 14)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityHint("a11y.card.hint")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        MemoCardView(
            memo: PreviewSupport.sampleMemo(renderType: .checklist, content: "여행 준비물"),
            onTap: {},
            onToggleActivity: {},
            onDelete: {}
        )
        MemoCardView(
            memo: PreviewSupport.sampleMemo(renderType: .dday, content: "프로젝트 마감", activityId: nil),
            onTap: {},
            onToggleActivity: {},
            onDelete: {}
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
}
#endif
