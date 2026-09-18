import SwiftUI
import VellureCore

/// 최근 잠금화면 게시 이력.
///
/// "8시간이 안 됐는데 사라졌다"를 사실과 대조할 수 있어야 한다.
/// 통합 로그는 케이블로 Mac에 연결해야 보여, 정작 이상하다고 느낀 순간에 쓸 수 없다.
struct ActivityHistoryView: View {
    /// 한 번에 보여줄 건수. 더 길어지면 설정 화면이 이력으로 덮인다.
    private static let visibleCount = 5

    let records: [ActivityRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("settings.section.history")
                .scaledFont(13, weight: .bold)
                .foregroundStyle(Theme.textSecondary)

            list

            Text("settings.history.hint")
                .scaledFont(11.5)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 2)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(records.prefix(Self.visibleCount).enumerated()), id: \.element.id) { index, record in
                if index > 0 {
                    Divider().padding(.leading, 14)
                }
                row(record)
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }

    private func row(_ record: ActivityRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(statusColor(record))
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .scaledFont(13.5, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(detail(record))
                    .scaledFont(11.5)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    /// 앱이 내린 적 없는데 사라진 건만 눈에 띄게 한다. 나머지는 예상된 동작이다.
    private func statusColor(_ record: ActivityRecord) -> Color {
        switch record.reason {
        case .disappeared: .orange
        case .none: Theme.accent
        default: Theme.textSecondary
        }
    }

    private func detail(_ record: ActivityRecord) -> String {
        let started = record.startedAt.formatted(date: .omitted, time: .shortened)
        guard let reason = record.reason else {
            return String(format: String(localized: "history.running"), started)
        }
        return String(
            format: String(localized: "history.ended"),
            started,
            record.livedMinutes,
            String(localized: reasonKey(reason))
        )
    }

    private func reasonKey(_ reason: ActivityRecord.EndReason) -> String.LocalizationValue {
        switch reason {
        case .user: "history.reason.user"
        case .expired: "history.reason.expired"
        case .autoClear: "history.reason.autoClear"
        case .disappeared: "history.reason.disappeared"
        }
    }
}
