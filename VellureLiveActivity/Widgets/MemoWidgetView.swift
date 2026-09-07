import SwiftUI
import VellureCore
import WidgetKit

/// 위젯 한 칸의 내용. 패밀리에 따라 표현을 바꾼다.
struct MemoWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MemoWidgetEntry

    var body: some View {
        if entry.isMissing {
            MissingMemoView()
        } else if let memo = entry.memo {
            content(memo)
        } else {
            EmptyMemoView()
        }
    }

    @ViewBuilder
    private func content(_ memo: MemoSnapshot) -> some View {
        switch family {
        case .accessoryInline:
            InlineMemoView(memo: memo)
        case .accessoryCircular:
            CircularMemoView(memo: memo)
        case .accessoryRectangular:
            RectangularMemoView(memo: memo)
        case .systemMedium:
            MediumMemoView(memos: entry.listMemos)
        default:
            SmallMemoView(memo: memo)
        }
    }
}

// MARK: - 잠금화면

/// 시계 위 한 줄. 아이콘과 값만 담긴다.
private struct InlineMemoView: View {
    let memo: MemoSnapshot

    var body: some View {
        // 잠금화면 accessory는 시스템이 단색(vibrant)으로 렌더링해 틴트가 적용되지 않는다.
        // 컬러 태그로 구분할 수 없으므로 아이콘과 값으로 구분한다.
        Label {
            Text("\(memo.headlineValue) · \(memo.title)")
        } icon: {
            Image(systemName: memo.renderType.iconName)
        }
    }
}

/// 시계 아래 원형 칸. 값 하나만 크게 담는다.
private struct CircularMemoView: View {
    let memo: MemoSnapshot

    var body: some View {
        switch memo.renderType {
        case .progress:
            Gauge(value: memo.progress ?? 0) {
                Image(systemName: memo.renderType.iconName)
            } currentValueLabel: {
                Text("\(Int((memo.progress ?? 0) * 100))")
                    .minimumScaleFactor(0.6)
            }
            .gaugeStyle(.accessoryCircularCapacity)
        default:
            VStack(spacing: 0) {
                Text(memo.headlineValue)
                    .font(.system(size: 17, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(memo.title)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(2)
        }
    }
}

/// 시계 아래 가로 칸. 제목과 값을 두 줄로 담는다.
private struct RectangularMemoView: View {
    let memo: MemoSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label {
                Text(memo.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: memo.renderType.iconName)
            }
            .font(.system(size: 12, weight: .semibold))

            if memo.renderType == .progress {
                ProgressView(value: memo.progress ?? 0)
                    .progressViewStyle(.linear)
                Text("\(Int((memo.progress ?? 0) * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
            } else {
                Text(memo.headlineValue)
                    .font(.system(size: 20, weight: .heavy))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 홈화면

/// 정사각 칸. Live Activity 카드를 압축한 형태로, 여기서는 컬러 태그가 살아난다.
private struct SmallMemoView: View {
    let memo: MemoSnapshot

    private var tint: Color { Theme.memoColor(for: memo.colorTag) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: memo.renderType.iconName)
                    .font(.system(size: 11, weight: .semibold))
                Text(memo.renderType.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(tint)

            Text(memo.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if memo.renderType == .progress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int((memo.progress ?? 0) * 100))%")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(tint)
                        .monospacedDigit()
                    ProgressView(value: memo.progress ?? 0)
                        .progressViewStyle(.linear)
                        .tint(tint)
                }
            } else {
                Text(memo.headlineValue)
                    .memoHighlightStyle()
                    .foregroundStyle(tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 가로로 긴 칸. 위젯 탭 정렬 순서대로 여러 건을 담는다.
private struct MediumMemoView: View {
    /// 표시할 최대 행 수. 더 넣으면 행 높이가 눌려 값이 읽히지 않는다.
    private static let rowLimit = 3

    let memos: [MemoSnapshot]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(memos.prefix(Self.rowLimit).enumerated()), id: \.offset) { _, memo in
                row(memo)
            }
            if memos.count < Self.rowLimit {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ memo: MemoSnapshot) -> some View {
        let tint = Theme.memoColor(for: memo.colorTag)
        return HStack(spacing: 8) {
            // 컬러 태그를 세로 막대로 둔다. 아이콘을 쓰면 제목이 밀려 폭을 잃는다.
            Capsule()
                .fill(tint)
                .frame(width: 3, height: 22)

            Text(memo.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 6)

            if memo.renderType == .progress {
                HStack(spacing: 5) {
                    ProgressView(value: memo.progress ?? 0)
                        .progressViewStyle(.linear)
                        .tint(tint)
                        .frame(width: 44)
                    Text("\(Int((memo.progress ?? 0) * 100))%")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(tint)
                        .monospacedDigit()
                }
            } else {
                Text(memo.headlineValue)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - 빈 상태

/// 고른 메모가 지워졌을 때. 다른 메모로 조용히 바꾸지 않는다.
private struct MissingMemoView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: 16, weight: .semibold))
            Text("widget.missing")
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.textSecondary)
    }
}

/// 위젯 표면에 메모가 하나도 없을 때.
private struct EmptyMemoView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 16, weight: .semibold))
            Text("widget.empty")
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.textSecondary)
    }
}
