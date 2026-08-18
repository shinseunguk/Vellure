import SwiftUI
import VellureCore

struct MemoCardView: View {
    let memo: Memo
    let onTap: () -> Void
    let onToggleActivity: () -> Void
    let onDelete: () -> Void
    var showsActions: Bool = true

    private var tintColor: Color {
        Theme.memoColor(for: memo.colorTag)
    }

    private var typeIcon: String {
        switch memo.renderType {
        case .plain: "note.text"
        case .checklist: "checklist"
        case .dday: "calendar"
        case .countdown: "timer"
        case .progress: "chart.bar.fill"
        }
    }

    private var typeLabel: String {
        switch memo.renderType {
        case .plain: String(localized: "type.plain")
        case .checklist: String(localized: "type.checklist")
        case .dday: String(localized: "type.dday")
        case .countdown: String(localized: "type.countdown")
        case .progress: String(localized: "type.progress")
        }
    }

    private var sideValue: String? {
        switch memo.renderType {
        case .dday:
            guard let target = memo.targetDate else { return nil }
            let days = Calendar.current.dateComponents([.day], from: .now, to: target).day ?? 0
            return days >= 0 ? "D-\(days)" : "D+\(abs(days))"
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

    private var isActive: Bool { memo.activityId != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: typeIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(tintColor)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(typeLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tintColor)
                            .lineLimit(1)
                            .fixedSize()
                        if let value = sideValue {
                            Text(value)
                                .font(.system(size: 10.5, weight: .heavy))
                                .foregroundStyle(tintColor)
                                .monospacedDigit()
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(tintColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    if !memo.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(memo.content)
                            .font(.system(size: 15.5, weight: .bold))
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
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(item.done ? tintColor : Theme.textSecondary)
                                    Text(item.title)
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundStyle(item.done ? Theme.textSecondary : Theme.textPrimary)
                                        .strikethrough(item.done)
                                        .lineLimit(1)
                                }
                            }
                            if items.count > 4 {
                                Text("+\(items.count - 4)")
                                    .font(.system(size: 11, weight: .semibold))
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
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isActive ? .white : tintColor)
                                .frame(width: 34, height: 34)
                                .background(isActive ? tintColor : tintColor.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(Theme.chipBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
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
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
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
