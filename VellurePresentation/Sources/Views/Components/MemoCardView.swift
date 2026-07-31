import SwiftUI
import VellureCore

struct MemoCardView: View {
    let memo: Memo
    let onTap: () -> Void
    let onToggleActivity: () -> Void

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

    private var subtitle: String {
        switch memo.renderType {
        case .dday:
            guard let target = memo.targetDate else { return "" }
            let days = Calendar.current.dateComponents([.day], from: .now, to: target).day ?? 0
            return days >= 0 ? "D-\(days)" : "D+\(abs(days))"
        case .countdown:
            guard let target = memo.targetDate else { return "" }
            return target.formatted(date: .abbreviated, time: .shortened)
        case .checklist:
            let total = memo.items?.count ?? 0
            let done = memo.items?.filter(\.done).count ?? 0
            return "\(done)/\(total)"
        case .progress:
            return "\(Int((memo.progress ?? 0) * 100))%"
        case .plain:
            return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: typeIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tintColor)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if memo.activityId != nil {
                            Circle()
                                .fill(tintColor)
                                .frame(width: 7, height: 7)
                        }
                        Text(memo.content)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text(typeLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)

                        if !subtitle.isEmpty {
                            Text("·")
                                .foregroundStyle(Theme.textSecondary)
                            Text(subtitle)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(tintColor)
                        }
                    }
                }

                Spacer()

                Button(action: onToggleActivity) {
                    Image(systemName: memo.activityId != nil ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(memo.activityId != nil ? .red.opacity(0.7) : tintColor)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.divider, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
