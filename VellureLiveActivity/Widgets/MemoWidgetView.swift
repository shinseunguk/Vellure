import SwiftUI
import VellureCore
import WidgetKit

/// 위젯 한 칸의 내용. 패밀리에 따라 표현을 바꾼다.
struct MemoWidgetView: View {
    @Environment(\.widgetFamily) private var environmentFamily

    let entry: MemoWidgetEntry
    /// 렌더 테스트에서 패밀리를 직접 지정하기 위한 통로.
    /// `widgetFamily` 환경값은 쓰기가 막혀 있어 위젯 밖에서는 바꿀 수 없다.
    var familyOverride: WidgetFamily?

    private var family: WidgetFamily { familyOverride ?? environmentFamily }

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

/// 메모 타입을 나타내는 라운드 타일.
/// 앱 카드와 같은 표식이라 위젯이 같은 제품으로 읽힌다.
private struct TypeTile: View {
    let renderType: RenderType
    let tint: Color
    var size: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
            .fill(tint.opacity(0.15))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: renderType.iconName)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            }
    }
}

/// 값 칩. 앱 카드의 보조 값과 같은 모양이다.
private struct ValueChip: View {
    let text: String
    let tint: Color
    var fontSize: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy))
            .foregroundStyle(tint)
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

/// 정사각 칸. 위쪽에 타입을 밝히고 아래쪽에 제목과 값을 모은다.
/// 값을 가운데 띄우면 여백만 커지고 시선이 흩어진다.
private struct SmallMemoView: View {
    let memo: MemoSnapshot

    private var tint: Color { Theme.memoColor(for: memo.colorTag) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                TypeTile(renderType: memo.renderType, tint: tint)
                Text(memo.renderType.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 10)

            VStack(alignment: .leading, spacing: 5) {
                Text(memo.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if memo.renderType == .progress {
                    progressBlock
                } else {
                    Text(memo.headlineValue)
                        .memoHighlightStyle(size: 27)
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(memo.headlineValue)
                .memoHighlightStyle(size: 24)
                .foregroundStyle(tint)
            ProgressBar(value: memo.progress ?? 0, tint: tint, height: 6)
        }
    }
}

/// 앱 카드와 같은 모양의 진행 막대.
private struct ProgressBar: View {
    let value: Double
    let tint: Color
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(tint.opacity(0.15))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: geo.size.width * min(max(value, 0), 1))
                }
        }
        .frame(height: height)
    }
}

/// 가로로 긴 칸. 위젯 탭 정렬 순서대로 여러 건을 담는다.
private struct MediumMemoView: View {
    /// 표시할 최대 행 수. 더 넣으면 행 높이가 눌려 값이 읽히지 않는다.
    private static let rowLimit = 3

    let memos: [MemoSnapshot]

    var body: some View {
        VStack(spacing: 0) {
            // 건수가 적을 때 위로 몰리면 아래가 텅 빈다. 가운데로 모은다.
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                ForEach(Array(memos.prefix(Self.rowLimit).enumerated()), id: \.offset) { _, memo in
                    row(memo)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ memo: MemoSnapshot) -> some View {
        let tint = Theme.memoColor(for: memo.colorTag)
        return HStack(spacing: 10) {
            TypeTile(renderType: memo.renderType, tint: tint, size: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if memo.renderType == .progress {
                    ProgressBar(value: memo.progress ?? 0, tint: tint, height: 4)
                        .frame(maxWidth: 120)
                }
            }

            Spacer(minLength: 8)

            ValueChip(text: memo.headlineValue, tint: tint)
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
